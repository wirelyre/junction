open Junction
open Sexplib.Std

type a = (string * Bytecode.inst list) list
[@@deriving sexp]

let () =
  {|
    mod main
    #19 & 25
    #a(3, )
    #a->b(4,5,6,)
    #1
    #while True { 1 while False { 2 } 3 }

    let a := if True { 4 + 5 } else { 6 - 7 }
    a * 8
  |}
  |> Parser.Lex.lex |> Parser.parse_file |> sexp_of_a
  |> Sexplib.Sexp.to_string |> print_endline

(*
let () =
  Parser.Lex.lex
    {|
fn sum[T: Add, I: Iterator[T]](zero: T, iter: I): T {
    let total := zero
    for item := iter {
        total := total + item
    }
    total
}
|}
  |> List.map Parser.Lex.sexp_of_token
  |> List.map Sexplib.Sexp.to_string
  |> List.iter print_endline
*)
