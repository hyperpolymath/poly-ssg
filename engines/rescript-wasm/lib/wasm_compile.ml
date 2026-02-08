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
  | Tvariant _ -> Ref Any  (* Variants are boxed *)
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
  (* Phase 4: Pattern matching *)
  | Lswitch (_, sw) ->
      (* Type is determined by the branches *)
      begin match sw.sw_consts with
      | (_, branch) :: _ -> infer_type env branch
      | [] -> begin match sw.sw_blocks with
        | (_, branch) :: _ -> infer_type env branch
        | [] -> begin match sw.sw_failaction with
          | Some branch -> infer_type env branch
          | None -> Ref Any
          end
        end
      end
  | Lstaticraise _ -> Ref Any  (* Never returns normally *)
  | Lstaticcatch (_, _, handler) -> infer_type env handler
  | Ltrywith (body, _, _) -> infer_type env body

and type_of_primitive = function
  | Paddint | Psubint | Pmulint | Pdivint | Pmodint
  | Pnegint | Pandint | Porint | Pxorint | Plslint | Pasrint
  | Pintcomp _ -> Ref I31
  | Paddfloat | Psubfloat | Pmulfloat | Pdivfloat | Pnegfloat -> F64
  | Pfloatcomp _ -> Ref I31  (* Comparisons return int/bool *)
  | Pintoffloat -> Ref I31
  | Pfloatofint -> F64
  | Pidentity -> Ref Any
  (* Phase 2: Blocks/records *)
  | Pmakeblock (tag, _) -> Ref (Struct (block_type_name tag 0))  (* Size unknown *)
  | Pfield _ -> Ref Any  (* Field access - type depends on block *)
  | Psetfield _ -> Ref (Struct "$unit")  (* Set returns unit *)
  (* Phase 2: Arrays *)
  | Pmakearray _ -> Ref (Array "$genarray")
  | Parraylength _ -> Ref I31
  | Parrayrefu _ -> Ref Any
  | Parraysetu _ -> Ref (Struct "$unit")
  | Parrayrefs _ -> Ref Any
  | Parraysets _ -> Ref (Struct "$unit")
  (* Phase 4: Variants *)
  | Pisint -> Ref I31  (* Returns bool as i31 *)
  | Pisout -> Ref I31  (* Returns bool as i31 *)
  | Pgettag -> Ref I31  (* Returns tag as i31 *)
  (* Phase 5: JS Interop *)
  | Pccall _ -> Ref Any  (* External calls return boxed values *)
  | Pjs_unsafe_downgrade -> Ref Any  (* Unsafe cast returns any *)

(** Generate block struct type name for a given tag and size *)
and block_type_name tag size =
  Printf.sprintf "$block_%d_%d" tag size

(** Generate or retrieve block struct type *)
and ensure_block_type env tag size =
  let name = block_type_name tag size in
  match lookup_struct env name with
  | Some _ -> env
  | None ->
      let fields = List.init size (fun i -> {
        field_name = Printf.sprintf "f%d" i;
        field_type = Ref Any;  (* Generic field type *)
        field_mutable = true;  (* Allow mutation for now *)
      }) in
      let struct_type = {
        struct_name = name;
        struct_fields = fields;
        struct_supertype = None;
      } in
      add_struct_type env struct_type

(** Generate or retrieve generic array type *)
and ensure_genarray_type env =
  let name = "$genarray" in
  match lookup_array env name with
  | Some _ -> env
  | None ->
      let array_type = {
        array_name = name;
        array_elem_type = Ref Any;
        array_elem_mutable = true;
      } in
      add_array_type env array_type

(** {1 Phase 3: Closure Support} *)

(** Closure counter for generating unique names *)
let closure_counter = ref 0

(** Generate unique closure type name *)
let fresh_closure_name () =
  let n = !closure_counter in
  incr closure_counter;
  Printf.sprintf "$closure_%d" n

(** Generate closure struct type with funcref + captured variables *)
let ensure_closure_type env num_captures =
  let name = Printf.sprintf "$closure_env_%d" num_captures in
  match lookup_struct env name with
  | Some _ -> (env, name)
  | None ->
      (* Closure struct: first field is funcref, rest are captured values *)
      let func_field = {
        field_name = "fn";
        field_type = Ref Any;  (* Will hold funcref *)
        field_mutable = false;
      } in
      let capture_fields = List.init num_captures (fun i -> {
        field_name = Printf.sprintf "cap%d" i;
        field_type = Ref Any;  (* Captured values are boxed *)
        field_mutable = false;
      }) in
      let struct_type = {
        struct_name = name;
        struct_fields = func_field :: capture_fields;
        struct_supertype = None;
      } in
      (add_struct_type env struct_type, name)

(** Generate function type for closure wrapper *)
let closure_func_type num_params _num_captures =
  (* Closure function takes: closure env, then regular params *)
  (* _num_captures reserved for future optimization of closure types *)
  let env_param = Ref Any in  (* The closure struct *)
  let regular_params = List.init num_params (fun _ -> Ref I31) in
  {
    ft_params = env_param :: regular_params;
    ft_results = [Ref Any];  (* Generic return *)
  }

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

  (* Phase 2: Records/blocks *)
  | Pmakeblock (tag, _mutability) ->
      let size = List.length args in
      let env = ensure_block_type env tag size in
      let type_name = block_type_name tag size in
      let env, compiled_args = List.fold_left_map (fun env arg ->
        compile_expr env arg
      ) env args in
      (env, StructNew (type_name, compiled_args))

  | Pfield n ->
      begin match args with
      | [record] ->
          let env, crecord = compile_expr env record in
          (* Use generic field access - actual type depends on block type *)
          let field_name = Printf.sprintf "f%d" n in
          (* We need to determine the struct type from the record *)
          (* For now, assume block_0 (tuple) types - could be improved with type info *)
          (env, StructGet ("$block_0_0", field_name, crecord))
      | _ -> error "field access expects 1 argument"
      end

  | Psetfield (n, _mutability) ->
      begin match args with
      | [record; value] ->
          let env, crecord = compile_expr env record in
          let env, cvalue = compile_expr env value in
          let field_name = Printf.sprintf "f%d" n in
          (env, Seq [
            StructSet ("$block_0_0", field_name, crecord, cvalue);
            StructNew ("$unit", [])
          ])
      | _ -> error "setfield expects 2 arguments"
      end

  (* Phase 2: Arrays *)
  | Pmakearray (_kind, _mutability) ->
      let env = ensure_genarray_type env in
      let env, compiled_args = List.fold_left_map (fun env arg ->
        compile_expr env arg
      ) env args in
      (env, ArrayNewFixed ("$genarray", compiled_args))

  | Parraylength _kind ->
      begin match args with
      | [arr] ->
          let env, carr = compile_expr env arr in
          (env, RefI31 (ArrayLen carr))
      | _ -> error "array length expects 1 argument"
      end

  | Parrayrefu _kind ->
      begin match args with
      | [arr; idx] ->
          let env, carr = compile_expr env arr in
          let env, cidx = compile_expr env idx in
          (* Index is i31ref, need to unwrap to i32 *)
          (env, ArrayGet ("$genarray", carr, I31GetS cidx))
      | _ -> error "array get expects 2 arguments"
      end

  | Parraysetu _kind ->
      begin match args with
      | [arr; idx; value] ->
          let env, carr = compile_expr env arr in
          let env, cidx = compile_expr env idx in
          let env, cvalue = compile_expr env value in
          (env, Seq [
            ArraySet ("$genarray", carr, I31GetS cidx, cvalue);
            StructNew ("$unit", [])
          ])
      | _ -> error "array set expects 3 arguments"
      end

  | Parrayrefs _kind ->
      (* Safe array access - for now same as unsafe, could add bounds check *)
      begin match args with
      | [arr; idx] ->
          let env, carr = compile_expr env arr in
          let env, cidx = compile_expr env idx in
          (env, ArrayGet ("$genarray", carr, I31GetS cidx))
      | _ -> error "array get expects 2 arguments"
      end

  | Parraysets _kind ->
      (* Safe array set - for now same as unsafe, could add bounds check *)
      begin match args with
      | [arr; idx; value] ->
          let env, carr = compile_expr env arr in
          let env, cidx = compile_expr env idx in
          let env, cvalue = compile_expr env value in
          (env, Seq [
            ArraySet ("$genarray", carr, I31GetS cidx, cvalue);
            StructNew ("$unit", [])
          ])
      | _ -> error "array set expects 3 arguments"
      end

  (* Phase 4: Variants *)
  | Pisint ->
      (* Check if value is an immediate integer (i31ref) vs a block *)
      begin match args with
      | [v] ->
          let env, cv = compile_expr env v in
          (* Use ref.test to check if it's an i31ref *)
          (env, RefI31 (RefTest (I31, cv)))
      | _ -> error "isint expects 1 argument"
      end

  | Pisout ->
      (* Check if tag is out of range - used for exhaustiveness *)
      begin match args with
      | [tag; num_tags] ->
          let env, ctag = compile_expr env tag in
          let env, cnum = compile_expr env num_tags in
          (* tag >= num_tags means out of range *)
          (env, RefI31 (I32GeU (I31GetS ctag, I31GetS cnum)))
      | _ -> error "isout expects 2 arguments"
      end

  | Pgettag ->
      (* Get tag from a block (variant constructor) *)
      begin match args with
      | [block] ->
          let env, cblock = compile_expr env block in
          (* For now, assume tag is stored in first field or use struct info *)
          (* In ReScript WASM-GC, we could use different struct types per tag *)
          (* Simplified: extract tag from the variant struct *)
          (env, RefI31 (StructGet ("$variant", "tag", cblock)))
      | _ -> error "gettag expects 1 argument"
      end

  (* Phase 5: JS Interop *)
  | Pccall { prim_name; prim_arity; prim_native_name } ->
      (* Call external JavaScript function via import *)
      let import_name = if prim_native_name <> "" then prim_native_name else prim_name in
      let local_name = "$" ^ import_name in
      (* Ensure the import is registered *)
      let env = ensure_js_import env "js" import_name local_name prim_arity in
      let env, cargs = List.fold_left_map (fun env arg ->
        compile_expr env arg
      ) env args in
      (* Generate call to imported function *)
      (env, Call (local_name, cargs))

  | Pjs_unsafe_downgrade ->
      (* Unsafe cast from JS value - identity at runtime *)
      begin match args with
      | [v] -> compile_expr env v
      | _ -> error "js_unsafe_downgrade expects 1 argument"
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
          (* Check if it's a known direct function *)
          if lookup_global env id.name then
            (* Direct global function call *)
            let env, cargs = List.fold_left_map (fun env arg ->
              compile_expr env arg
            ) env args in
            (env, Call ("$" ^ id.name, cargs))
          else begin
            (* Could be a closure in a local variable *)
            match lookup_local env id with
            | Some idx ->
                (* Closure call: extract funcref and call with closure as first arg *)
                let env, cargs = List.fold_left_map (fun env arg ->
                  compile_expr env arg
                ) env args in
                let closure_val = LocalGet idx in
                (* For closure call, we need: closure env, then args *)
                (* Using call_ref requires knowing the type - use generic for now *)
                let num_args = List.length args in
                let func_type = closure_func_type num_args 0 in
                let closure_type_name = Printf.sprintf "$closure_env_%d" num_args in
                (env, CallRef (func_type,
                  StructGet (closure_type_name, "fn", closure_val),
                  closure_val :: cargs))
            | None ->
                (* Try as direct function call *)
                let env, cargs = List.fold_left_map (fun env arg ->
                  compile_expr env arg
                ) env args in
                (env, Call ("$" ^ id.name, cargs))
          end
      | _ ->
          (* Indirect call through arbitrary expression *)
          let env, cfn = compile_expr env fn in
          let env, cargs = List.fold_left_map (fun env arg ->
            compile_expr env arg
          ) env args in
          (* Assume the expression evaluates to a closure *)
          let num_args = List.length args in
          let func_type = closure_func_type num_args 0 in
          (* The function expression should evaluate to a closure struct *)
          (env, CallRef (func_type,
            StructGet ("$closure_env_0", "fn", cfn),
            cfn :: cargs))
      end

  | Lfunction (repr, body) ->
      (* Check for free variables *)
      let fvs = free_vars body in
      let bound_params = List.map (fun p -> p.stamp) repr.params in
      let captured = List.filter (fun fv ->
        not (List.mem fv.stamp bound_params)
      ) fvs in

      if captured = [] then
        (* No free variables - simple function, no closure needed *)
        let env, func_name = fresh_func_name env "lambda" in
        let env, func = compile_function env func_name repr.params body in
        let env = add_function env func in
        (env, RefFunc func_name)
      else
        (* Has free variables - create a closure *)
        let num_params = List.length repr.params in
        let num_captures = List.length captured in
        let closure_name = fresh_closure_name () in

        (* Ensure closure struct type exists *)
        let env, closure_type_name = ensure_closure_type env num_captures in

        (* Generate the closure wrapper function *)
        let env = enter_scope env in

        (* First param is the closure env struct *)
        let closure_env_id = make_ident "$env" in
        let env, closure_env_idx = alloc_local env closure_env_id (Ref Any) in

        (* Then regular params *)
        let env, _ = List.fold_left (fun (env, _) param ->
          let env, idx = alloc_local env param (Ref I31) in
          (env, idx)
        ) (env, 0) repr.params in

        (* Extract captured variables from closure struct *)
        let env, extract_instrs = List.fold_left (fun (env, instrs) (i, cap_id) ->
          let cap_local_id = make_ident ("$cap_" ^ cap_id.name) in
          let env, cap_idx = alloc_local env cap_local_id (Ref Any) in
          (* Also add the original id mapping so body can access it *)
          let env = bind_local env cap_id cap_idx (Ref Any) in
          let field_name = Printf.sprintf "cap%d" i in
          let extract = LocalSet (cap_idx,
            StructGet (closure_type_name, field_name, LocalGet closure_env_idx)) in
          (env, instrs @ [extract])
        ) (env, []) (List.mapi (fun i c -> (i, c)) captured) in

        (* Compile the body with captured vars available *)
        let env, cbody = compile_expr env body in

        let func = {
          func_name = closure_name;
          func_type = closure_func_type num_params num_captures;
          func_locals = get_locals env;
          func_body = Seq (extract_instrs @ [cbody]);
          func_export = None;
        } in
        let env = exit_scope env in
        let env = add_function env func in

        (* Create the closure struct: funcref + captured values *)
        let env, capture_instrs = List.fold_left_map (fun env cap_id ->
          match lookup_local env cap_id with
          | Some idx -> (env, LocalGet idx)
          | None -> (env, RefNull Any)  (* Fallback - shouldn't happen *)
        ) env captured in

        let closure_instr = StructNew (closure_type_name,
          RefFunc closure_name :: capture_instrs) in
        (env, closure_instr)

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

  (* Phase 4: Pattern Matching *)
  | Lswitch (scrutinee, sw) ->
      let env, cscrutinee = compile_expr env scrutinee in
      (* Store scrutinee in a local for multiple accesses *)
      let scrut_id = make_ident "$scrutinee" in
      let env, scrut_idx = alloc_local env scrut_id (Ref Any) in

      (* Compile constant cases (immediate integers) *)
      let env, const_branches = List.fold_left_map (fun env (tag, body) ->
        let env, cbody = compile_expr env body in
        (env, (tag, cbody))
      ) env sw.sw_consts in

      (* Compile block cases (constructors with data) *)
      let env, block_branches = List.fold_left_map (fun env (tag, body) ->
        let env, cbody = compile_expr env body in
        (env, (tag, cbody))
      ) env sw.sw_blocks in

      (* Compile fail action *)
      let env, fail_instr = match sw.sw_failaction with
        | Some fail ->
            let env, cfail = compile_expr env fail in
            (env, Some cfail)
        | None -> (env, None)
      in

      (* Generate switch using br_table or nested ifs *)
      let default_instr = match fail_instr with
        | Some f -> f
        | None -> Unreachable
      in

      (* Build the switch logic *)
      let build_switch is_const branches =
        if branches = [] then default_instr
        else
          let check_branch (tag, body) rest =
            let cmp = if is_const then
              (* For constants, compare directly *)
              I32Eq (I31GetS (LocalGet scrut_idx), I32Const (Int32.of_int tag))
            else
              (* For blocks, compare the tag *)
              let tag_instr = StructGet ("$variant", "tag", LocalGet scrut_idx) in
              I32Eq (tag_instr, I32Const (Int32.of_int tag))
            in
            If (cmp, [body], [rest])
          in
          List.fold_right check_branch branches default_instr
      in

      (* Combine const and block cases *)
      let body =
        if const_branches <> [] && block_branches <> [] then
          (* Check if int first, then dispatch *)
          let is_int = RefTest (I31, LocalGet scrut_idx) in
          If (is_int,
            [build_switch true const_branches],
            [build_switch false block_branches])
        else if const_branches <> [] then
          build_switch true const_branches
        else
          build_switch false block_branches
      in

      (env, Seq [LocalSet (scrut_idx, cscrutinee); body])

  | Lstaticraise (exit_num, args) ->
      (* Static raise - jump to a catch handler *)
      let env, cargs = List.fold_left_map (fun env arg ->
        compile_expr env arg
      ) env args in
      (* For now, use br with the exit number as label depth *)
      (* In real impl, would need to track catch handlers *)
      let _ = cargs in  (* Args would be passed via locals in full impl *)
      (env, Br exit_num)

  | Lstaticcatch (body, (exit_num, ids), handler) ->
      (* Static catch - wraps body with a handler for staticraise *)
      let _ = exit_num in
      (* Allocate locals for the handler parameters *)
      let env = List.fold_left (fun env id ->
        let env, _ = alloc_local env id (Ref Any) in
        env
      ) env ids in
      let env, cbody = compile_expr env body in
      let env, chandler = compile_expr env handler in
      (* Use block/br structure for static exception handling *)
      (* The body can br to the handler block *)
      (env, Block (Some (Printf.sprintf "$catch_%d" exit_num), [
        cbody;
        Br 1  (* Skip handler if body completes normally *)
      ]))
      (* Note: simplified - full impl needs block for handler too *)
      |> fun (env, block_instr) ->
        (env, Seq [block_instr; chandler])

  | Ltrywith (body, exn_id, handler) ->
      (* Try-with for dynamic exceptions *)
      (* WASM-GC doesn't have native exception handling (yet) *)
      (* For now, compile as just the body - exceptions would trap *)
      let env, cbody = compile_expr env body in
      let env, _ = alloc_local env exn_id (Ref Any) in
      let env, _chandler = compile_expr env handler in
      (* TODO: When WASM exceptions are available, use try-catch *)
      (env, cbody)

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
