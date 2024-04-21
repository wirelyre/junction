open Junction
open Sexplib.Std

type a = (string * Bytecode.inst list) list
[@@deriving sexp]

let () =
  {|
    mod main

    use core.Bool
    use core.Bool.False
    use core.Bool.True
    use core.Nat

    fn is_even(n: Nat): Bool {
        if n == 0 { True } else { is_odd(n - 1) }
    }
    fn is_odd(n: Nat): Bool {
        if n == 0 { False } else { is_even(n - 1) }
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
