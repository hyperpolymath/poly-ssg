(** Minimal Lambda IR for ReScript WASM-GC Backend *)

type ident = {
  name : string;
  stamp : int;
}

let ident_counter = ref 0

let make_ident name =
  incr ident_counter;
  { name; stamp = !ident_counter }

let ident_name id = id.name

type constant =
  | Const_int of int
  | Const_float of float
  | Const_string of string
  | Const_char of char

type comparison = Ceq | Cne | Clt | Cle | Cgt | Cge

(** Mutability flag for record fields and array elements *)
type mutable_flag = Immutable | Mutable

(** Array kind for typed arrays *)
type array_kind = Pgenarray | Paddrarray | Pintarray | Pfloatarray

type primitive =
  (* Integer arithmetic *)
  | Paddint | Psubint | Pmulint | Pdivint | Pmodint | Pnegint
  | Pandint | Porint | Pxorint | Plslint | Pasrint
  | Pintcomp of comparison
  (* Float arithmetic *)
  | Paddfloat | Psubfloat | Pmulfloat | Pdivfloat | Pnegfloat
  | Pfloatcomp of comparison
  (* Conversions *)
  | Pintoffloat | Pfloatofint
  (* Identity *)
  | Pidentity
  (* Records/blocks (Phase 2) *)
  | Pmakeblock of int * mutable_flag  (** Create block with tag *)
  | Pfield of int                      (** Get field at index *)
  | Psetfield of int * mutable_flag    (** Set field at index *)
  (* Arrays (Phase 2) *)
  | Pmakearray of array_kind * mutable_flag  (** Create array *)
  | Parraylength of array_kind         (** Array length *)
  | Parrayrefu of array_kind           (** Array get (unsafe) *)
  | Parraysetu of array_kind           (** Array set (unsafe) *)
  | Parrayrefs of array_kind           (** Array get (safe/bounds checked) *)
  | Parraysets of array_kind           (** Array set (safe/bounds checked) *)

type let_kind = Strict | Alias | Variable

type function_repr = {
  params : ident list;
  return_type : lambda_type option;
}

and lambda_type =
  | Tint | Tfloat | Tstring | Tunit | Tbool
  | Tfunc of lambda_type list * lambda_type
  | Tany

and lambda =
  | Lconst of constant
  | Lvar of ident
  | Lapply of lambda * lambda list
  | Lfunction of function_repr * lambda
  | Llet of let_kind * ident * lambda * lambda
  | Lletrec of (ident * lambda) list * lambda
  | Lprim of primitive * lambda list
  | Lifthenelse of lambda * lambda * lambda
  | Lsequence of lambda * lambda
  | Lwhile of lambda * lambda
  | Lfor of ident * lambda * lambda * bool * lambda

let const_int n = Lconst (Const_int n)
let const_float f = Lconst (Const_float f)
let const_string s = Lconst (Const_string s)
let const_unit = Lconst (Const_int 0)
let const_true = Lconst (Const_int 1)
let const_false = Lconst (Const_int 0)

let var name = Lvar (make_ident name)
let var_id id = Lvar id

let apply fn args = Lapply (fn, args)

let func params body =
  let param_ids = List.map make_ident params in
  Lfunction ({ params = param_ids; return_type = None }, body)

let func_typed params return_type body =
  let param_ids = List.map (fun (name, _) -> make_ident name) params in
  Lfunction ({ params = param_ids; return_type = Some return_type }, body)

let let_ name value body =
  Llet (Strict, make_ident name, value, body)

let let_id id value body =
  Llet (Strict, id, value, body)

let letrec bindings body =
  let id_bindings = List.map (fun (name, value) -> (make_ident name, value)) bindings in
  Lletrec (id_bindings, body)

let prim p args = Lprim (p, args)
let add a b = Lprim (Paddint, [a; b])
let sub a b = Lprim (Psubint, [a; b])
let mul a b = Lprim (Pmulint, [a; b])
let div a b = Lprim (Pdivint, [a; b])

(* Record/tuple constructors *)
let makeblock tag fields = Lprim (Pmakeblock (tag, Immutable), fields)
let makeblock_mut tag fields = Lprim (Pmakeblock (tag, Mutable), fields)
let field n record = Lprim (Pfield n, [record])
let setfield n record value = Lprim (Psetfield (n, Mutable), [record; value])

(* Tuple constructors (tag 0) *)
let tuple fields = makeblock 0 fields
let tuple2 a b = tuple [a; b]
let tuple3 a b c = tuple [a; b; c]

(* Array constructors *)
let makearray elements = Lprim (Pmakearray (Pgenarray, Mutable), elements)
let arraylength arr = Lprim (Parraylength Pgenarray, [arr])
let arrayget arr idx = Lprim (Parrayrefu Pgenarray, [arr; idx])
let arrayset arr idx value = Lprim (Parraysetu Pgenarray, [arr; idx; value])

let if_ cond then_ else_ = Lifthenelse (cond, then_, else_)
let seq e1 e2 = Lsequence (e1, e2)

let rec seqs = function
  | [] -> const_unit
  | [e] -> e
  | e :: es -> Lsequence (e, seqs es)

module IdentSet = Set.Make(struct
  type t = ident
  let compare a b = compare a.stamp b.stamp
end)

let rec free_vars_set expr =
  match expr with
  | Lconst _ -> IdentSet.empty
  | Lvar id -> IdentSet.singleton id
  | Lapply (fn, args) ->
      List.fold_left (fun acc arg -> IdentSet.union acc (free_vars_set arg))
        (free_vars_set fn) args
  | Lfunction (repr, body) ->
      let bound = IdentSet.of_list repr.params in
      IdentSet.diff (free_vars_set body) bound
  | Llet (_, id, value, body) ->
      IdentSet.union (free_vars_set value) (IdentSet.remove id (free_vars_set body))
  | Lletrec (bindings, body) ->
      let bound = IdentSet.of_list (List.map fst bindings) in
      let binding_fvs = List.fold_left
        (fun acc (_, value) -> IdentSet.union acc (free_vars_set value))
        IdentSet.empty bindings in
      IdentSet.diff (IdentSet.union binding_fvs (free_vars_set body)) bound
  | Lprim (_, args) ->
      List.fold_left (fun acc arg -> IdentSet.union acc (free_vars_set arg))
        IdentSet.empty args
  | Lifthenelse (cond, then_, else_) ->
      IdentSet.union (free_vars_set cond)
        (IdentSet.union (free_vars_set then_) (free_vars_set else_))
  | Lsequence (e1, e2) ->
      IdentSet.union (free_vars_set e1) (free_vars_set e2)
  | Lwhile (cond, body) ->
      IdentSet.union (free_vars_set cond) (free_vars_set body)
  | Lfor (id, lo, hi, _, body) ->
      IdentSet.union (free_vars_set lo)
        (IdentSet.union (free_vars_set hi) (IdentSet.remove id (free_vars_set body)))

let free_vars expr = IdentSet.elements (free_vars_set expr)
let is_closed expr = IdentSet.is_empty (free_vars_set expr)

let pp_comparison fmt = function
  | Ceq -> Format.fprintf fmt "="
  | Cne -> Format.fprintf fmt "<>"
  | Clt -> Format.fprintf fmt "<"
  | Cle -> Format.fprintf fmt "<="
  | Cgt -> Format.fprintf fmt ">"
  | Cge -> Format.fprintf fmt ">="

let pp_primitive fmt = function
  | Paddint -> Format.fprintf fmt "+"
  | Psubint -> Format.fprintf fmt "-"
  | Pmulint -> Format.fprintf fmt "*"
  | Pdivint -> Format.fprintf fmt "/"
  | Pmodint -> Format.fprintf fmt "mod"
  | Pnegint -> Format.fprintf fmt "~-"
  | Pandint -> Format.fprintf fmt "land"
  | Porint -> Format.fprintf fmt "lor"
  | Pxorint -> Format.fprintf fmt "lxor"
  | Plslint -> Format.fprintf fmt "lsl"
  | Pasrint -> Format.fprintf fmt "asr"
  | Pintcomp cmp -> Format.fprintf fmt "int%a" pp_comparison cmp
  | Paddfloat -> Format.fprintf fmt "+."
  | Psubfloat -> Format.fprintf fmt "-."
  | Pmulfloat -> Format.fprintf fmt "*."
  | Pdivfloat -> Format.fprintf fmt "/."
  | Pnegfloat -> Format.fprintf fmt "~-."
  | Pfloatcomp cmp -> Format.fprintf fmt "float%a" pp_comparison cmp
  | Pintoffloat -> Format.fprintf fmt "int_of_float"
  | Pfloatofint -> Format.fprintf fmt "float_of_int"
  | Pidentity -> Format.fprintf fmt "identity"
  (* Records/blocks *)
  | Pmakeblock (tag, _) -> Format.fprintf fmt "makeblock[%d]" tag
  | Pfield n -> Format.fprintf fmt "field[%d]" n
  | Psetfield (n, _) -> Format.fprintf fmt "setfield[%d]" n
  (* Arrays *)
  | Pmakearray _ -> Format.fprintf fmt "makearray"
  | Parraylength _ -> Format.fprintf fmt "arraylength"
  | Parrayrefu _ -> Format.fprintf fmt "array.get"
  | Parraysetu _ -> Format.fprintf fmt "array.set"
  | Parrayrefs _ -> Format.fprintf fmt "array.get_safe"
  | Parraysets _ -> Format.fprintf fmt "array.set_safe"

let rec pp_lambda fmt = function
  | Lconst (Const_int n) -> Format.fprintf fmt "%d" n
  | Lconst (Const_float f) -> Format.fprintf fmt "%g" f
  | Lconst (Const_string s) -> Format.fprintf fmt "%S" s
  | Lconst (Const_char c) -> Format.fprintf fmt "'%c'" c
  | Lvar id -> Format.fprintf fmt "%s/%d" id.name id.stamp
  | Lapply (fn, args) ->
      Format.fprintf fmt "(@[%a@ %a@])" pp_lambda fn
        (Format.pp_print_list ~pp_sep:Format.pp_print_space pp_lambda) args
  | Lfunction (repr, body) ->
      Format.fprintf fmt "(fun @[(%a)@ %a@])"
        (Format.pp_print_list ~pp_sep:Format.pp_print_space
           (fun fmt id -> Format.fprintf fmt "%s" id.name)) repr.params
        pp_lambda body
  | Llet (_, id, value, body) ->
      Format.fprintf fmt "@[<v>(let %s =@ @[%a@]@ in@ @[%a@])@]"
        id.name pp_lambda value pp_lambda body
  | Lletrec (bindings, body) ->
      Format.fprintf fmt "@[<v>(letrec@ @[<v>%a@]@ in@ @[%a@])@]"
        (Format.pp_print_list ~pp_sep:Format.pp_print_space
           (fun fmt (id, value) ->
              Format.fprintf fmt "(%s = @[%a@])" id.name pp_lambda value)) bindings
        pp_lambda body
  | Lprim (prim, args) ->
      Format.fprintf fmt "(@[%a@ %a@])" pp_primitive prim
        (Format.pp_print_list ~pp_sep:Format.pp_print_space pp_lambda) args
  | Lifthenelse (cond, then_, else_) ->
      Format.fprintf fmt "@[<v>(if @[%a@]@ then @[%a@]@ else @[%a@])@]"
        pp_lambda cond pp_lambda then_ pp_lambda else_
  | Lsequence (e1, e2) ->
      Format.fprintf fmt "@[<v>(seq@ @[%a@]@ @[%a@])@]" pp_lambda e1 pp_lambda e2
  | Lwhile (cond, body) ->
      Format.fprintf fmt "@[<v>(while @[%a@]@ @[%a@])@]" pp_lambda cond pp_lambda body
  | Lfor (id, lo, hi, up, body) ->
      Format.fprintf fmt "@[<v>(for %s = @[%a@] %s @[%a@]@ @[%a@])@]"
        id.name pp_lambda lo (if up then "to" else "downto") pp_lambda hi pp_lambda body

let lambda_to_string expr = Format.asprintf "%a" pp_lambda expr

module Compat = struct
  type t = lambda
  let of_rescript _ = failwith "Compat.of_rescript: Not implemented"
  let is_standalone () = true
end
