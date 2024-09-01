include BatMap
open Batteries
open Sexplib

let sexp_of_t of_k of_v map =
  let entries =
    enum map
    |> Enum.map (fun (k, v) -> Sexp.List [ of_k k; of_v v ])
  in
  Sexp.List (List.of_enum entries)

let t_of_sexp k_of v_of =
  let error = Sexplib.Conv.of_sexp_error "Map.t_of_sexp" in
  let entry_of_sexp = function
    | Sexp.List [ k; v ] -> (k_of k, v_of v)
    | s -> error s
  in
  function
  | Sexp.List entries ->
      List.enum entries |> Enum.map entry_of_sexp |> of_enum
  | s -> error s
