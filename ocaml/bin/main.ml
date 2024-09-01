open Junction

type test = {
  expect : Types.value;
  namespace : Types.namespace;
}
[@@deriving sexp]

let () =
  Sexplib.(
    let sexps = Sexp.load_sexps "test.sexp" in
    List.iter
      (fun sexp ->
        let test = test_of_sexp sexp in

        let ns =
          Types.Namespace.merge Value.builtins test.namespace
        in
        let main =
          Junction.Bytecode.invoke ns
            (Types.Namespace.get ns "main")
        in

        let expect = Types.sexp_of_value test.expect in
        let result =
          Types.sexp_of_value (main BatVect.empty)
        in

        if expect = result then
          print_endline ("✅ " ^ Sexp.to_string result)
        else
          print_endline
            ("❌ "
            ^ Sexp.to_string result
            ^ ", expected "
            ^ Sexp.to_string expect))
      sexps)
