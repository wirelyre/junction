module Lex : sig
  type token =
    | Ident of string
    | Kw of string
    | Num of Uint64.t
    | Punct of string
    | String of string
  [@@deriving sexp]

  val lex : string -> token list
end

val parse_file : Lex.token list -> (string * Bytecode.inst list) list
