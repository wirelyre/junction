open Junction.Types

type test = { expect : value; namespace : namespace }
[@@deriving sexp]

let builtins =
  BatList.fold_left Namespace.merge Namespace.empty
    Junction.Builtins.[ Bool.ns; Nat.ns; Option.ns ]

let () =
  Sexplib.(
    let sexps = Sexp.load_sexps "test.sexp" in
    List.iter
      (fun sexp ->
        let test = test_of_sexp sexp in

        let ns = Namespace.merge builtins test.namespace in
        let main =
          Junction.Bytecode.invoke ns
            (Namespace.get ns "main")
        in

        let expect = sexp_of_value test.expect in
        let result = sexp_of_value (main BatVect.empty) in

        if expect = result then
          print_endline ("✅ " ^ Sexp.to_string result)
        else
          print_endline
            ("❌ "
            ^ Sexp.to_string result
            ^ ", expected "
            ^ Sexp.to_string expect))
      sexps)
