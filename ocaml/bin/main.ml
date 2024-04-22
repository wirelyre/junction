open Junction
open Sexplib.Std

type a = (string * Bytecode.item option) list
[@@deriving sexp]

let () =
  {|
    module main

    use std.range
    let sum := 0
    for n := range(1, 101) { sum := sum + n }
    sum

    trait Iterator[Item] {
        fn next(^self): Option[Item]
    }

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
