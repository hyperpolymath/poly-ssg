(** ReScript WASM-GC Compiler - CLI Entry Point *)

open Rescript_wasm
open Lambda_ir
open Wasm_compile
open Wasm_emit

(** {1 Example Programs} *)

(** Example: let add = (a, b) => a + b *)
let example_add () =
  let a = make_ident "a" in
  let b = make_ident "b" in
  let body = Lprim (Paddint, [Lvar a; Lvar b]) in
  let func = Lfunction ({ params = [a; b]; return_type = Some Tint }, body) in
  [("add", func)]

(** Example: let result = 1 + 2 *)
let example_simple_add () =
  let expr = Lprim (Paddint, [const_int 1; const_int 2]) in
  [("result", expr)]

(** Example: let max = (a, b) => if a > b then a else b *)
let example_max () =
  let a = make_ident "a" in
  let b = make_ident "b" in
  let cond = Lprim (Pintcomp Cgt, [Lvar a; Lvar b]) in
  let body = Lifthenelse (cond, Lvar a, Lvar b) in
  let func = Lfunction ({ params = [a; b]; return_type = Some Tint }, body) in
  [("max", func)]

(** Example: let square = x => x * x *)
let example_square () =
  let x = make_ident "x" in
  let body = Lprim (Pmulint, [Lvar x; Lvar x]) in
  let func = Lfunction ({ params = [x]; return_type = Some Tint }, body) in
  [("square", func)]

(** Example: let fact = n => ... (iterative) *)
let example_factorial () =
  let n = make_ident "n" in
  let result = make_ident "result" in
  let i = make_ident "i" in

  (* result = 1 *)
  (* for i = 1 to n do result = result * i done *)
  (* result *)
  let body =
    Llet (Strict, result, const_int 1,
      Lsequence (
        Lfor (i, const_int 1, Lvar n, true,
          Llet (Strict, result,
            Lprim (Pmulint, [Lvar result; Lvar i]),
            const_unit)),
        Lvar result))
  in
  let func = Lfunction ({ params = [n]; return_type = Some Tint }, body) in
  [("factorial", func)]

(** Example: Float operations *)
let example_float () =
  let x = make_ident "x" in
  let y = make_ident "y" in
  let body = Lprim (Paddfloat, [
    Lprim (Pmulfloat, [Lvar x; Lvar x]);
    Lprim (Pmulfloat, [Lvar y; Lvar y])
  ]) in
  let func = Lfunction ({ params = [x; y]; return_type = Some Tfloat }, body) in
  [("sum_of_squares", func)]

(** Combined example with multiple functions *)
let example_combined () =
  example_add () @
  example_max () @
  example_square () @
  example_simple_add ()

(** {1 CLI} *)

let examples = [
  ("add", example_add);
  ("simple", example_simple_add);
  ("max", example_max);
  ("square", example_square);
  ("factorial", example_factorial);
  ("float", example_float);
  ("combined", example_combined);
]

let print_usage () =
  print_endline "ReScript WASM-GC Compiler (Phase 1 MVP)";
  print_endline "";
  print_endline "Usage: rescript_wasm [options] [example]";
  print_endline "";
  print_endline "Options:";
  print_endline "  --help, -h     Show this help message";
  print_endline "  --test         Run built-in test";
  print_endline "  --list         List available examples";
  print_endline "";
  print_endline "Examples:";
  List.iter (fun (name, _) ->
    print_endline ("  " ^ name)
  ) examples;
  print_endline "";
  print_endline "Example usage:";
  print_endline "  rescript_wasm add          # Compile 'add' example";
  print_endline "  rescript_wasm combined     # Compile all examples together"

let run_test () =
  print_endline "(* Running built-in test *)";
  print_endline "";

  (* Test 1: Simple add function *)
  print_endline "(* Test 1: add function *)";
  let program = example_add () in
  let wasm_module = compile_program program in
  let wat = emit_module wasm_module in
  print_endline wat;
  print_endline "";

  (* Test 2: Max function with conditional *)
  print_endline "(* Test 2: max function *)";
  let program = example_max () in
  let wasm_module = compile_program program in
  let wat = emit_module wasm_module in
  print_endline wat;
  print_endline "";

  (* Test 3: Combined *)
  print_endline "(* Test 3: combined *)";
  let program = example_combined () in
  let wasm_module = compile_program program in
  let wat = emit_module wasm_module in
  print_endline wat;

  print_endline "";
  print_endline "(* All tests completed *)"

let compile_example name =
  match List.assoc_opt name examples with
  | Some example_fn ->
      let program = example_fn () in
      let wasm_module = compile_program program in
      let wat = emit_module wasm_module in
      print_endline wat
  | None ->
      Printf.eprintf "Unknown example: %s\n" name;
      Printf.eprintf "Use --list to see available examples\n";
      exit 1

let () =
  let args = Array.to_list Sys.argv |> List.tl in
  match args with
  | [] | ["--help"] | ["-h"] -> print_usage ()
  | ["--test"] -> run_test ()
  | ["--list"] ->
      print_endline "Available examples:";
      List.iter (fun (name, _) -> print_endline ("  " ^ name)) examples
  | [name] -> compile_example name
  | _ ->
      print_endline "Error: Too many arguments";
      print_usage ();
      exit 1
