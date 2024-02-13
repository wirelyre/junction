include Stdint.Uint64

let sexp_of_t t = Sexplib.Sexp.Atom (to_string t)

let t_of_sexp s =
  match s with
  | Sexplib.Sexp.Atom a -> of_string a
  | _ -> Sexplib.Conv.of_sexp_error "Uint64.t_of_sexp" s
