open Junction
open Sexplib.Std

type namespace = (string * Bytecode.item option) list
[@@deriving sexp]

type test = {
  expect : Value.t;
  sources : string list;
  namespace : namespace;
}
[@@deriving sexp]

let xor x1 x2 =
  match (x1, x2) with
  | None, None -> None
  | Some x1, None -> Some x1
  | None, Some x2 -> Some x2
  | Some _, Some _ -> failwith "duplicate"

let canonical items =
  items
  |> List.fold_left
       (fun ns (path, item) ->
         let old = BatMap.find_default None path ns in
         BatMap.add path (xor old item) ns)
       BatMap.empty
  |> BatMap.to_seq |> List.of_seq

let compile sources =
  List.map Parser.parse_file sources
  |> List.flatten |> canonical

let () =
  Sexplib.(
    let sexps = Sexp.load_sexps "test.sexp" in
    List.iter
      (fun sexp ->
        let test = test_of_sexp sexp in

        let compiled = compile test.sources in
        let expected = canonical test.namespace in
        if compiled <> expected then (
          print_endline
            ("❌ "
            ^ Sexp.to_string (sexp_of_namespace compiled));
          print_endline
            (Sexp.to_string (sexp_of_namespace expected)))
        else
          let ns =
            BatHashtbl.of_list
              (Value.builtins
              @ List.map Bytecode.val_of_item compiled)
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
