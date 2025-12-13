(** Minimal Lambda IR for ReScript WASM-GC Backend *)

type ident = { name : string; stamp : int; }

val make_ident : string -> ident
val ident_name : ident -> string

type constant =
  | Const_int of int
  | Const_float of float
  | Const_string of string
  | Const_char of char

type comparison = Ceq | Cne | Clt | Cle | Cgt | Cge

type primitive =
  | Paddint | Psubint | Pmulint | Pdivint | Pmodint | Pnegint
  | Pandint | Porint | Pxorint | Plslint | Pasrint
  | Pintcomp of comparison
  | Paddfloat | Psubfloat | Pmulfloat | Pdivfloat | Pnegfloat
  | Pfloatcomp of comparison
  | Pintoffloat | Pfloatofint
  | Pidentity

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

val const_int : int -> lambda
val const_float : float -> lambda
val const_string : string -> lambda
val const_unit : lambda
val const_true : lambda
val const_false : lambda

val var : string -> lambda
val var_id : ident -> lambda
val apply : lambda -> lambda list -> lambda
val func : string list -> lambda -> lambda
val func_typed : (string * lambda_type) list -> lambda_type -> lambda -> lambda
val let_ : string -> lambda -> lambda -> lambda
val let_id : ident -> lambda -> lambda -> lambda
val letrec : (string * lambda) list -> lambda -> lambda

val prim : primitive -> lambda list -> lambda
val add : lambda -> lambda -> lambda
val sub : lambda -> lambda -> lambda
val mul : lambda -> lambda -> lambda
val div : lambda -> lambda -> lambda

val if_ : lambda -> lambda -> lambda -> lambda
val seq : lambda -> lambda -> lambda
val seqs : lambda list -> lambda

val free_vars : lambda -> ident list
val is_closed : lambda -> bool

val pp_lambda : Format.formatter -> lambda -> unit
val lambda_to_string : lambda -> string

module Compat : sig
  type t = lambda
  val of_rescript : 'a -> t
  val is_standalone : unit -> bool
end
