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

(** {1 Run All Tests} *)

let () =
  print_endline "ReScript WASM-GC Compiler Test Suite";
  print_endline "====================================";
  print_endline "";

  test_val_type_emit ();
  print_endline "";

  test_instr_emit ();
  print_endline "";

  test_const_compile ();
  print_endline "";

  test_arithmetic_compile ();
  print_endline "";

  test_function_compile ();
  print_endline "";

  test_let_compile ();
  print_endline "";

  test_lambda_ir ();
  print_endline "";

  test_module_generation ();
  print_endline "";

  print_endline "====================================";
  Printf.printf "Results: %d passed, %d failed, %d total\n"
    !pass_count !fail_count !test_count;

  if !fail_count > 0 then exit 1
