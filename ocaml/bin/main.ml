open Junction
open Sexplib.Std

type a = (string * Bytecode.item option) list
[@@deriving sexp]

let () =
  {|
    module std

    use core.Option.None
    use core.Option.Some

    type range(start: Nat, end: Nat)

    impl range (core.Iterator[Nat]) {
        fn next(^self) {
            if self.start < self.end {
                ^self := range(self.start + 1, self.end)
                Some(self.start - 1)
            } else { None }
        }
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
