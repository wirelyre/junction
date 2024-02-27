open Junction
open Sexplib.Std

type test = {
  expect : Value.t;
  namespace : (string, Bytecode.inst list) Hashtbl.t;
}
[@@deriving sexp]

open Batteries

let () =
  Sexplib.(
    let sexps = Sexp.load_sexps "test.sexp" in
    List.iter
      (fun sexp ->
        let test = test_of_sexp sexp in

        let ns =
          test.namespace
          |> Hashtbl.map (fun _path -> Bytecode.fun_of_bc)
        in
        let main =
          Value.fun_of_t (Hashtbl.find ns "main")
        in

        let expect = Value.sexp_of_t test.expect in
        let result = Value.sexp_of_t (main ns []) in

        if expect = result then
          print_endline ("✅ " ^ Sexp.to_string result)
        else
          print_endline
            ("❌ "
            ^ Sexp.to_string result
            ^ ", expected "
            ^ Sexp.to_string expect))
      sexps)
