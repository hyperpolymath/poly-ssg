(** Lambda IR to WASM-GC Compiler *)

open Lambda_ir
open Wasm_types
open Wasm_env

(** {1 Errors} *)

exception Compile_error of string

let error msg = raise (Compile_error msg)

(** {1 Type Inference} *)

(** Infer WASM type from Lambda type annotation *)
let _type_of_lambda_type = function
  | Tint -> Ref I31
  | Tfloat -> F64
  | Tstring -> Ref (Array "$string")
  | Tunit -> Ref (Struct "$unit")
  | Tbool -> Ref I31
  | Tfunc _ -> Ref Any  (* Functions are boxed for now *)
  | Tany -> Ref Any

(** Infer type from a constant *)
let type_of_const = function
  | Const_int _ -> Ref I31
  | Const_float _ -> F64
  | Const_string _ -> Ref (Array "$string")
  | Const_char _ -> Ref I31

(** Simple type inference - returns the WASM type of an expression *)
let rec infer_type env expr =
  match expr with
  | Lconst c -> type_of_const c
  | Lvar id ->
      (* Look up local type - default to i31ref for now *)
      begin match lookup_local env id with
      | Some _ -> Ref I31  (* TODO: track types properly *)
      | None -> Ref I31
      end
  | Lprim (prim, _) -> type_of_primitive prim
  | Lifthenelse (_, then_, _) -> infer_type env then_
  | Llet (_, _, _, body) -> infer_type env body
  | Lletrec (_, body) -> infer_type env body
  | Lsequence (_, e2) -> infer_type env e2
  | Lapply _ -> Ref I31  (* Default return type *)
  | Lfunction _ -> Ref Any  (* Function values *)
  | Lwhile _ -> Ref (Struct "$unit")
  | Lfor _ -> Ref (Struct "$unit")

and type_of_primitive = function
  | Paddint | Psubint | Pmulint | Pdivint | Pmodint
  | Pnegint | Pandint | Porint | Pxorint | Plslint | Pasrint
  | Pintcomp _ -> Ref I31
  | Paddfloat | Psubfloat | Pmulfloat | Pdivfloat | Pnegfloat -> F64
  | Pfloatcomp _ -> Ref I31  (* Comparisons return int/bool *)
  | Pintoffloat -> Ref I31
  | Pfloatofint -> F64
  | Pidentity -> Ref Any

(** {1 Constant Compilation} *)

let compile_const = function
  | Const_int n ->
      RefI31 (I32Const (Int32.of_int n))
  | Const_float f ->
      F64Const f
  | Const_string s ->
      (* String as UTF-8 byte array *)
      let bytes = String.to_seq s |> List.of_seq in
      let byte_instrs = List.map (fun c ->
        I32Const (Int32.of_int (Char.code c))
      ) bytes in
      ArrayNewFixed ("$string", byte_instrs)
  | Const_char c ->
      RefI31 (I32Const (Int32.of_int (Char.code c)))

(** {1 Primitive Compilation} *)

let compile_comparison cmp a b =
  match cmp with
  | Ceq -> I32Eq (a, b)
  | Cne -> I32Ne (a, b)
  | Clt -> I32LtS (a, b)
  | Cle -> I32LeS (a, b)
  | Cgt -> I32GtS (a, b)
  | Cge -> I32GeS (a, b)

let compile_float_comparison cmp a b =
  match cmp with
  | Ceq -> F64Eq (a, b)
  | Cne -> F64Ne (a, b)
  | Clt -> F64Lt (a, b)
  | Cle -> F64Le (a, b)
  | Cgt -> F64Gt (a, b)
  | Cge -> F64Ge (a, b)

(** Compile a primitive operation *)
let rec compile_prim env prim args =
  let compile_int_binop op =
    match args with
    | [a; b] ->
        let env, ca = compile_expr env a in
        let env, cb = compile_expr env b in
        (* Unwrap i31refs, do operation, wrap result *)
        (env, RefI31 (op (I31GetS ca) (I31GetS cb)))
    | _ -> error "Binary integer operation expects 2 arguments"
  in

  let compile_float_binop op =
    match args with
    | [a; b] ->
        let env, ca = compile_expr env a in
        let env, cb = compile_expr env b in
        (env, op ca cb)
    | _ -> error "Binary float operation expects 2 arguments"
  in

  match prim with
  (* Integer arithmetic *)
  | Paddint -> compile_int_binop (fun a b -> I32Add (a, b))
  | Psubint -> compile_int_binop (fun a b -> I32Sub (a, b))
  | Pmulint -> compile_int_binop (fun a b -> I32Mul (a, b))
  | Pdivint -> compile_int_binop (fun a b -> I32DivS (a, b))
  | Pmodint -> compile_int_binop (fun a b -> I32RemS (a, b))
  | Pandint -> compile_int_binop (fun a b -> I32And (a, b))
  | Porint -> compile_int_binop (fun a b -> I32Or (a, b))
  | Pxorint -> compile_int_binop (fun a b -> I32Xor (a, b))
  | Plslint -> compile_int_binop (fun a b -> I32Shl (a, b))
  | Pasrint -> compile_int_binop (fun a b -> I32ShrS (a, b))

  | Pnegint ->
      begin match args with
      | [a] ->
          let env, ca = compile_expr env a in
          (env, RefI31 (I32Sub (I32Const 0l, I31GetS ca)))
      | _ -> error "Unary negation expects 1 argument"
      end

  | Pintcomp cmp ->
      begin match args with
      | [a; b] ->
          let env, ca = compile_expr env a in
          let env, cb = compile_expr env b in
          (* Return 1 for true, 0 for false as i31ref *)
          (env, RefI31 (compile_comparison cmp (I31GetS ca) (I31GetS cb)))
      | _ -> error "Integer comparison expects 2 arguments"
      end

  (* Float arithmetic *)
  | Paddfloat -> compile_float_binop (fun a b -> F64Add (a, b))
  | Psubfloat -> compile_float_binop (fun a b -> F64Sub (a, b))
  | Pmulfloat -> compile_float_binop (fun a b -> F64Mul (a, b))
  | Pdivfloat -> compile_float_binop (fun a b -> F64Div (a, b))

  | Pnegfloat ->
      begin match args with
      | [a] ->
          let env, ca = compile_expr env a in
          (env, F64Neg ca)
      | _ -> error "Unary float negation expects 1 argument"
      end

  | Pfloatcomp cmp ->
      begin match args with
      | [a; b] ->
          let env, ca = compile_expr env a in
          let env, cb = compile_expr env b in
          (env, RefI31 (compile_float_comparison cmp ca cb))
      | _ -> error "Float comparison expects 2 arguments"
      end

  (* Conversions *)
  | Pintoffloat ->
      begin match args with
      | [a] ->
          let env, _ca = compile_expr env a in
          (* f64 -> i32 -> i31ref *)
          (env, RefI31 (I32Const 0l))  (* TODO: proper f64.trunc_sat_s *)
      | _ -> error "int_of_float expects 1 argument"
      end

  | Pfloatofint ->
      begin match args with
      | [a] ->
          let env, _ca = compile_expr env a in
          (* i31ref -> i32 -> f64 *)
          (env, F64Const 0.0)  (* TODO: proper i32.convert_f64_s *)
      | _ -> error "float_of_int expects 1 argument"
      end

  | Pidentity ->
      begin match args with
      | [a] -> compile_expr env a
      | _ -> error "identity expects 1 argument"
      end

(** {1 Expression Compilation} *)

and compile_expr env expr =
  match expr with
  | Lconst c ->
      (env, compile_const c)

  | Lvar id ->
      begin match lookup_local env id with
      | Some idx -> (env, LocalGet idx)
      | None ->
          (* Try as global *)
          if lookup_global env id.name then
            (env, GlobalGet ("$" ^ id.name))
          else
            error (Printf.sprintf "Unbound variable: %s" id.name)
      end

  | Lprim (prim, args) ->
      compile_prim env prim args

  | Lifthenelse (cond, then_, else_) ->
      let env, ccond = compile_expr env cond in
      let env, cthen = compile_expr env then_ in
      let env, celse = compile_expr env else_ in
      (* Condition is i31ref, unwrap to i32 for if *)
      (env, If (I31GetS ccond, [cthen], [celse]))

  | Llet (_, id, value, body) ->
      let val_type = infer_type env value in
      let env, idx = alloc_local env id val_type in
      let env, cvalue = compile_expr env value in
      let env, cbody = compile_expr env body in
      (env, Seq [LocalSet (idx, cvalue); cbody])

  | Lletrec (bindings, body) ->
      (* For Phase 1, we don't support true recursion - just sequential bindings *)
      let env = List.fold_left (fun env (id, _) ->
        let env, _ = alloc_local env id (Ref I31) in
        env
      ) env bindings in
      let env = List.fold_left (fun env (id, value) ->
        let _idx = lookup_local_exn env id in
        let env, cvalue = compile_expr env value in
        add_function env {
          func_name = "$" ^ id.name;
          func_type = { ft_params = []; ft_results = [Ref I31] };
          func_locals = [];
          func_body = cvalue;
          func_export = None;
        }
      ) env bindings in
      compile_expr env body

  | Lsequence (e1, e2) ->
      let env, c1 = compile_expr env e1 in
      let env, c2 = compile_expr env e2 in
      (env, Seq [Drop c1; c2])

  | Lapply (fn, args) ->
      begin match fn with
      | Lvar id ->
          (* Direct function call *)
          let env, cargs = List.fold_left_map (fun env arg ->
            compile_expr env arg
          ) env args in
          (env, Call ("$" ^ id.name, cargs))
      | _ ->
          (* Indirect call - not fully supported in Phase 1 *)
          error "Indirect function calls not supported in Phase 1"
      end

  | Lfunction (repr, body) ->
      (* Create a function and return a reference to it *)
      let env, func_name = fresh_func_name env "lambda" in
      let env, func = compile_function env func_name repr.params body in
      let env = add_function env func in
      (env, RefFunc func_name)

  | Lwhile (cond, body) ->
      let env, ccond = compile_expr env cond in
      let env, cbody = compile_expr env body in
      (* while cond do body done
         =>
         (block $exit
           (loop $loop
             (br_if $exit (i32.eqz cond))
             body
             (br $loop)))
      *)
      (env, Block (Some "$exit", [
        Loop (Some "$loop", [
          BrIf (1, I32Eqz (I31GetS ccond));
          Drop cbody;
          Br 0
        ])
      ]))

  | Lfor (id, lo, hi, up, body) ->
      let env, idx = alloc_local env id (Ref I31) in
      let env, clo = compile_expr env lo in
      let env, chi = compile_expr env hi in
      let env, cbody = compile_expr env body in
      (* for i = lo to hi do body done (simplified) *)
      let make_cmp a b = if up then I32LeS (a, b) else I32GeS (a, b) in
      let make_step a b = if up then I32Add (a, b) else I32Sub (a, b) in
      (env, Seq [
        LocalSet (idx, clo);
        Block (Some "$exit", [
          Loop (Some "$loop", [
            BrIf (1, I32Eqz (make_cmp (I31GetS (LocalGet idx)) (I31GetS chi)));
            Drop cbody;
            LocalSet (idx, RefI31 (make_step (I31GetS (LocalGet idx)) (I32Const 1l)));
            Br 0
          ])
        ])
      ])

(** {1 Function Compilation} *)

and compile_function env name params body =
  (* Enter a new scope for the function *)
  let env = enter_scope env in

  (* Allocate parameters as locals *)
  let env, param_types = List.fold_left_map (fun env param ->
    let typ = Ref I31 in  (* Default to i31ref for Phase 1 *)
    let env, _ = alloc_local env param typ in
    (env, typ)
  ) env params in

  (* Compile the body *)
  let env, cbody = compile_expr env body in

  (* Determine return type *)
  let return_type = infer_type env body in

  (* Build the function *)
  let func = {
    func_name = name;
    func_type = {
      ft_params = param_types;
      ft_results = [return_type];
    };
    func_locals = get_locals env;
    func_body = cbody;
    func_export = None;
  } in

  (* Exit scope *)
  let env = exit_scope env in

  (env, func)

(** {1 Top-level Compilation} *)

let compile_toplevel env name expr =
  match expr with
  | Lfunction (repr, body) ->
      (* Top-level function definition *)
      let env, func = compile_function env ("$" ^ name) repr.params body in
      let func = { func with func_export = Some name } in
      add_function env func

  | _ ->
      (* Top-level value - compile as a global initializer or init function *)
      (* For Phase 1, we wrap non-function values in a getter function *)
      let env = enter_scope env in
      let env, cexpr = compile_expr env expr in
      let return_type = infer_type env expr in
      let env = exit_scope env in
      let func = {
        func_name = "$" ^ name;
        func_type = {
          ft_params = [];
          ft_results = [return_type];
        };
        func_locals = [];
        func_body = cexpr;
        func_export = Some name;
      } in
      add_function env func

(** {1 Program Compilation} *)

let compile_program bindings =
  let env = empty () in
  let env = with_standard_types env in
  let env = List.fold_left (fun env (name, expr) ->
    compile_toplevel env name expr
  ) env bindings in
  to_module env

let compile_expr_as_module expr =
  compile_program [("main", expr)]
