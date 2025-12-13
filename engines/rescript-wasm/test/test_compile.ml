(** Test Suite for ReScript WASM-GC Compiler *)

open Rescript_wasm
open Lambda_ir
open Wasm_types
open Wasm_compile
open Wasm_emit

(** {1 Test Helpers} *)

let test_count = ref 0
let pass_count = ref 0
let fail_count = ref 0

let test name f =
  incr test_count;
  Printf.printf "Test %d: %s... " !test_count name;
  try
    f ();
    incr pass_count;
    print_endline "PASS"
  with e ->
    incr fail_count;
    Printf.printf "FAIL: %s\n" (Printexc.to_string e)

let assert_eq msg expected actual =
  if expected <> actual then
    failwith (Printf.sprintf "%s: expected %s, got %s" msg expected actual)

let assert_contains msg needle haystack =
  if not (String.length haystack >= String.length needle &&
          let rec check i =
            if i + String.length needle > String.length haystack then false
            else if String.sub haystack i (String.length needle) = needle then true
            else check (i + 1)
          in check 0) then
    failwith (Printf.sprintf "%s: expected to contain '%s'" msg needle)

(** {1 Type Tests} *)

let test_val_type_emit () =
  test "emit i32 type" (fun () ->
    assert_eq "i32" "i32" (emit_val_type I32)
  );
  test "emit f64 type" (fun () ->
    assert_eq "f64" "f64" (emit_val_type F64)
  );
  test "emit i31ref type" (fun () ->
    assert_eq "i31ref" "(ref i31)" (emit_val_type (Ref I31))
  );
  test "emit nullable extern" (fun () ->
    assert_eq "ref null extern" "(ref null extern)" (emit_val_type (RefNull Extern))
  )

(** {1 Instruction Tests} *)

let test_instr_emit () =
  test "emit i32.const" (fun () ->
    let instr = I32Const 42l in
    assert_eq "i32.const" "(i32.const 42)" (emit_instr instr)
  );
  test "emit ref.i31" (fun () ->
    let instr = RefI31 (I32Const 42l) in
    assert_eq "ref.i31" "(ref.i31 (i32.const 42))" (emit_instr instr)
  );
  test "emit i32.add" (fun () ->
    let instr = I32Add (I32Const 1l, I32Const 2l) in
    assert_eq "i32.add" "(i32.add (i32.const 1) (i32.const 2))" (emit_instr instr)
  );
  test "emit local.get" (fun () ->
    let instr = LocalGet 0 in
    assert_eq "local.get" "(local.get 0)" (emit_instr instr)
  )

(** {1 Constant Compilation Tests} *)

let test_const_compile () =
  test "compile int constant" (fun () ->
    let expr = const_int 42 in
    let m = compile_expr_as_module expr in
    let wat = emit_module m in
    assert_contains "int const in output" "ref.i31" wat;
    assert_contains "int value in output" "42" wat
  );
  test "compile float constant" (fun () ->
    let expr = const_float 3.14 in
    let m = compile_expr_as_module expr in
    let wat = emit_module m in
    assert_contains "float const in output" "f64.const" wat;
    assert_contains "float value in output" "3.14" wat
  )

(** {1 Arithmetic Compilation Tests} *)

let test_arithmetic_compile () =
  test "compile integer addition" (fun () ->
    let expr = add (const_int 1) (const_int 2) in
    let m = compile_expr_as_module expr in
    let wat = emit_module m in
    assert_contains "i32.add in output" "i32.add" wat;
    assert_contains "i31.get_s in output" "i31.get_s" wat
  );
  test "compile integer subtraction" (fun () ->
    let expr = sub (const_int 5) (const_int 3) in
    let m = compile_expr_as_module expr in
    let wat = emit_module m in
    assert_contains "i32.sub in output" "i32.sub" wat
  );
  test "compile integer multiplication" (fun () ->
    let expr = mul (const_int 3) (const_int 4) in
    let m = compile_expr_as_module expr in
    let wat = emit_module m in
    assert_contains "i32.mul in output" "i32.mul" wat
  )

(** {1 Function Compilation Tests} *)

let test_function_compile () =
  test "compile simple function" (fun () ->
    let a = make_ident "a" in
    let b = make_ident "b" in
    let body = Lprim (Paddint, [Lvar a; Lvar b]) in
    let func = Lfunction ({ params = [a; b]; return_type = Some Tint }, body) in
    let m = compile_program [("add", func)] in
    let wat = emit_module m in
    assert_contains "func declaration" "(func $add" wat;
    assert_contains "export" "(export \"add\")" wat;
    assert_contains "param" "(param" wat
  );
  test "compile function with conditional" (fun () ->
    let a = make_ident "a" in
    let b = make_ident "b" in
    let cond = Lprim (Pintcomp Cgt, [Lvar a; Lvar b]) in
    let body = Lifthenelse (cond, Lvar a, Lvar b) in
    let func = Lfunction ({ params = [a; b]; return_type = Some Tint }, body) in
    let m = compile_program [("max", func)] in
    let wat = emit_module m in
    assert_contains "if instruction" "(if" wat;
    assert_contains "then" "(then" wat;
    assert_contains "else" "(else" wat
  )

(** {1 Let Binding Tests} *)

let test_let_compile () =
  test "compile let binding" (fun () ->
    let x = make_ident "x" in
    let expr = Llet (Strict, x, const_int 42, Lvar x) in
    let m = compile_expr_as_module expr in
    let wat = emit_module m in
    assert_contains "local.set in output" "local.set" wat;
    assert_contains "local.get in output" "local.get" wat
  )

(** {1 Lambda IR Tests} *)

let test_lambda_ir () =
  test "free variables - closed expression" (fun () ->
    let expr = add (const_int 1) (const_int 2) in
    if not (is_closed expr) then
      failwith "Expected expression to be closed"
  );
  test "free variables - open expression" (fun () ->
    let x = make_ident "x" in
    let expr = Lvar x in
    if is_closed expr then
      failwith "Expected expression to be open"
  );
  test "free variables - let binds variable" (fun () ->
    let x = make_ident "x" in
    let expr = Llet (Strict, x, const_int 1, Lvar x) in
    if not (is_closed expr) then
      failwith "Expected let-bound expression to be closed"
  );
  test "pretty print lambda" (fun () ->
    let expr = add (const_int 1) (const_int 2) in
    let s = lambda_to_string expr in
    assert_contains "plus in output" "+" s
  )

(** {1 Module Generation Tests} *)

let test_module_generation () =
  test "generate complete module" (fun () ->
    let a = make_ident "a" in
    let b = make_ident "b" in
    let body = Lprim (Paddint, [Lvar a; Lvar b]) in
    let func = Lfunction ({ params = [a; b]; return_type = Some Tint }, body) in
    let m = compile_program [("add", func)] in
    let wat = emit_module m in
    assert_contains "module wrapper" "(module" wat;
    assert_contains "type definitions" "(type" wat
  )

(** {1 Phase 2: Tuple Tests} *)

let test_tuple_compile () =
  test "compile tuple creation" (fun () ->
    let expr = tuple [const_int 1; const_int 2] in
    let m = compile_expr_as_module expr in
    let wat = emit_module m in
    assert_contains "struct.new in output" "struct.new" wat
  );
  test "compile tuple2 helper" (fun () ->
    let expr = tuple2 (const_int 10) (const_int 20) in
    let m = compile_expr_as_module expr in
    let wat = emit_module m in
    assert_contains "struct.new in output" "struct.new" wat
  );
  test "compile tuple3 helper" (fun () ->
    let expr = tuple3 (const_int 1) (const_int 2) (const_int 3) in
    let m = compile_expr_as_module expr in
    let wat = emit_module m in
    assert_contains "struct.new in output" "struct.new" wat;
    assert_contains "block type" "$block_0_3" wat
  )

(** {1 Phase 2: Record/Block Tests} *)

let test_block_compile () =
  test "compile makeblock with tag" (fun () ->
    let expr = makeblock 1 [const_int 42; const_string "hello"] in
    let m = compile_expr_as_module expr in
    let wat = emit_module m in
    assert_contains "struct.new in output" "struct.new" wat;
    assert_contains "block type with tag" "$block_1_2" wat
  );
  test "compile mutable block" (fun () ->
    let expr = makeblock_mut 0 [const_int 1; const_int 2] in
    let m = compile_expr_as_module expr in
    let wat = emit_module m in
    assert_contains "struct.new in output" "struct.new" wat
  )

(** {1 Phase 2: Array Tests} *)

let test_array_compile () =
  test "compile array creation" (fun () ->
    let expr = makearray [const_int 1; const_int 2; const_int 3] in
    let m = compile_expr_as_module expr in
    let wat = emit_module m in
    assert_contains "array.new_fixed in output" "array.new_fixed" wat;
    assert_contains "genarray type" "$genarray" wat
  );
  test "compile array length" (fun () ->
    let arr = make_ident "arr" in
    let body = arraylength (Lvar arr) in
    let func = Lfunction ({ params = [arr]; return_type = Some Tint }, body) in
    let m = compile_program [("len", func)] in
    let wat = emit_module m in
    assert_contains "array.len in output" "array.len" wat
  );
  test "compile array get" (fun () ->
    let arr = make_ident "arr" in
    let idx = make_ident "idx" in
    let body = arrayget (Lvar arr) (Lvar idx) in
    let func = Lfunction ({ params = [arr; idx]; return_type = Some Tany }, body) in
    let m = compile_program [("get", func)] in
    let wat = emit_module m in
    assert_contains "array.get in output" "array.get" wat;
    assert_contains "i31.get_s for index" "i31.get_s" wat
  );
  test "compile array set" (fun () ->
    let arr = make_ident "arr" in
    let idx = make_ident "idx" in
    let v = make_ident "v" in
    let body = arrayset (Lvar arr) (Lvar idx) (Lvar v) in
    let func = Lfunction ({ params = [arr; idx; v]; return_type = Some Tunit }, body) in
    let m = compile_program [("set", func)] in
    let wat = emit_module m in
    assert_contains "array.set in output" "array.set" wat
  )

(** {1 Phase 3: Closure Tests} *)

let test_closure_compile () =
  test "compile simple lambda (no closure)" (fun () ->
    (* A lambda with no free variables - when compiled as a value, it generates ref.func *)
    let x = make_ident "x" in
    let lambda_body = Lprim (Paddint, [Lvar x; const_int 1]) in
    let lambda_expr = Lfunction ({ params = [x]; return_type = Some Tint }, lambda_body) in
    (* Wrap lambda in let to force it to be an expression value *)
    let f = make_ident "f" in
    let outer = Llet (Strict, f, lambda_expr, Lvar f) in
    let m = compile_expr_as_module outer in
    let wat = emit_module m in
    (* Should generate a function and ref.func to reference it *)
    assert_contains "lambda function defined" "$lambda" wat
  );
  test "compile closure with captured variable" (fun () ->
    (* let n = 10 in (fun x -> x + n) *)
    let n = make_ident "n" in
    let x = make_ident "x" in
    let lambda_body = Lprim (Paddint, [Lvar x; Lvar n]) in
    let lambda_expr = Lfunction ({ params = [x]; return_type = Some Tint }, lambda_body) in
    let outer = Llet (Strict, n, const_int 10, lambda_expr) in
    let m = compile_expr_as_module outer in
    let wat = emit_module m in
    (* Should generate closure struct *)
    assert_contains "closure struct type" "$closure_env" wat;
    assert_contains "struct.new for closure" "struct.new" wat
  );
  test "compile higher-order function (map-like)" (fun () ->
    (* A function that takes a function parameter *)
    let f = make_ident "f" in
    let x = make_ident "x" in
    (* apply f x = f(x) *)
    let body = Lapply (Lvar f, [Lvar x]) in
    let func = Lfunction ({ params = [f; x]; return_type = Some Tany }, body) in
    let m = compile_program [("apply", func)] in
    let wat = emit_module m in
    (* Should use call_ref for closure invocation *)
    assert_contains "call_ref in output" "call_ref" wat
  );
  test "compile curried function" (fun () ->
    (* let add = fun x -> (fun y -> x + y) *)
    let x = make_ident "x" in
    let y = make_ident "y" in
    let inner_body = Lprim (Paddint, [Lvar x; Lvar y]) in
    let inner = Lfunction ({ params = [y]; return_type = Some Tint }, inner_body) in
    let outer = Lfunction ({ params = [x]; return_type = Some Tany }, inner) in
    let m = compile_program [("add_curried", outer)] in
    let wat = emit_module m in
    (* Inner function captures x, so should be a closure *)
    assert_contains "closure struct" "$closure" wat;
    assert_contains "captures variable" "struct.get" wat
  )

(** {1 Run All Tests} *)

let () =
  print_endline "ReScript WASM-GC Compiler Test Suite";
  print_endline "====================================";
  print_endline "";

  print_endline "-- Phase 1: Types --";
  test_val_type_emit ();
  print_endline "";

  print_endline "-- Phase 1: Instructions --";
  test_instr_emit ();
  print_endline "";

  print_endline "-- Phase 1: Constants --";
  test_const_compile ();
  print_endline "";

  print_endline "-- Phase 1: Arithmetic --";
  test_arithmetic_compile ();
  print_endline "";

  print_endline "-- Phase 1: Functions --";
  test_function_compile ();
  print_endline "";

  print_endline "-- Phase 1: Let Bindings --";
  test_let_compile ();
  print_endline "";

  print_endline "-- Phase 1: Lambda IR --";
  test_lambda_ir ();
  print_endline "";

  print_endline "-- Phase 1: Module Generation --";
  test_module_generation ();
  print_endline "";

  print_endline "-- Phase 2: Tuples --";
  test_tuple_compile ();
  print_endline "";

  print_endline "-- Phase 2: Blocks/Records --";
  test_block_compile ();
  print_endline "";

  print_endline "-- Phase 2: Arrays --";
  test_array_compile ();
  print_endline "";

  print_endline "-- Phase 3: Closures --";
  test_closure_compile ();
  print_endline "";

  print_endline "====================================";
  Printf.printf "Results: %d passed, %d failed, %d total\n"
    !pass_count !fail_count !test_count;

  if !fail_count > 0 then exit 1
