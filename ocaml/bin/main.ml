open Junction
open Sexplib.Std

type test = {
  expect : Types.value;
  namespace : (string * Types.item option) list;
}
[@@deriving sexp]

let () =
  Sexplib.(
    let sexps = Sexp.load_sexps "test.sexp" in
    List.iter
      (fun sexp ->
        let test = test_of_sexp sexp in

        let ns =
          BatHashtbl.of_list
            (Value.builtins
            @ List.map Bytecode.val_of_item test.namespace)
        in
        let main =
          Value.fun_of_t (Hashtbl.find ns "main")
        in

        let expect = Types.sexp_of_value test.expect in
        let result = Types.sexp_of_value (main ns []) in

        if expect = result then
          print_endline ("✅ " ^ Sexp.to_string result)
        else
          print_endline
            ("❌ "
            ^ Sexp.to_string result
            ^ ", expected "
            ^ Sexp.to_string expect))
      sexps)
