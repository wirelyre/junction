open Junction
open Sexplib.Std

type test = { expect : Value.t; code : Bytecode.inst list }
[@@deriving sexp]

let () =
  Sexplib.(
    let sexps = Sexp.load_sexps "test.sexp" in
    List.iter
      (fun sexp ->
        let test = test_of_sexp sexp in
        let code = Bytecode.fun_of_bc test.code in

        let expect = Value.sexp_of_t test.expect in
        let result = Value.sexp_of_t (code []) in

        if expect = result then
          print_endline ("✅ " ^ Sexp.to_string result)
        else
          print_endline
            ("❌ "
            ^ Sexp.to_string result
            ^ ", expected "
            ^ Sexp.to_string expect))
      sexps)
