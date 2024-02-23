open Junction

let _ =
  Sexplib.(
    let sexps = Sexp.load_sexps "test.sexp" in
    List.iter
      (fun sexp ->
        let bc = Bytecode.insts_of_sexp sexp in

        bc |> Bytecode.sexp_of_insts |> Sexp.to_string
        |> print_endline;

        print_string "-> ";

        Bytecode.eval_block bc (ref BatVect.empty)
        |> Value.sexp_of_t |> Sexp.to_string
        |> print_endline)
      sexps)
