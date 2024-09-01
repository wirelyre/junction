open Sexplib.Std
open Types

exception WrongType

let mk_unit type_ tag = Data { type_; tag; fields = [] }
let unit_ = mk_unit "core.Unit" None

let t_of_bool b =
  mk_unit "core.Bool" (Some (if b then "True" else "False"))

let bool_of_t = function
  | Data { type_ = "core.Bool"; tag = Some tag; _ } ->
      tag = "True"
  | _ -> raise WrongType

let fun_of_t = function
  | Module { f = Some f; _ } -> f
  | _ -> raise WrongType

let type_ =
  let type_of_t = function
    | Data d -> d.type_
    | Nat _ -> "core.Nat"
    | Module _ -> raise WrongType
  in
  function Val v -> type_of_t v | Ref r -> type_of_t !r

let tag = function
  | Data { tag = Some t; _ } -> t
  | _ -> raise WrongType

let field ns f = function
  | Val (Data { fields; _ }) -> List.assoc f fields
  | Val (Module { path; _ }) ->
      Hashtbl.find ns (path ^ "." ^ f)
  | _ -> raise WrongType

let ref_of_obj = function
  | Val _ -> raise WrongType
  | Ref r -> r

let val_of_obj = function
  | Val v -> v
  | Ref _ -> raise WrongType

let named_var_of_obj = function
  | Val v -> ref v
  | Ref r -> r

let fun_of_obj = function
  | Val (Module { f = Some f; _ }) -> f
  | _ -> raise WrongType

let option_of_t = function
  | Data { type_ = "core.Option"; fields; _ } ->
      List.assoc_opt "inner" fields
  | _ -> raise WrongType

let methods mod_name =
  let path name = mod_name ^ "." ^ name in
  List.map (fun (name, f) ->
      (path name, Module { path = path name; f = Some f }))

module Bool = struct
  let lift1 f _ns = function
    | [ Val b ] -> t_of_bool (f (bool_of_t b))
    | _ -> raise WrongType

  let lift2 f _ns = function
    | [ Val lhs; Val rhs ] ->
        t_of_bool (f (bool_of_t lhs) (bool_of_t rhs))
    | _ -> raise WrongType

  let ns =
    [
      ("core.Bool.False", t_of_bool false);
      ("core.Bool.True", t_of_bool true);
    ]
    @ methods "core.Bool"
        [
          ("not", lift1 not);
          ("and", lift2 ( && ));
          ("or", lift2 ( || ));
        ]
end

module Nat = struct
  open Uint64

  let lift2 f _ns = function
    | [ Val (Nat lhs); Val (Nat rhs) ] -> Nat (f lhs rhs)
    | _ -> raise WrongType

  let comp f _ns = function
    | [ Val (Nat lhs); Val (Nat rhs) ] ->
        t_of_bool (f (compare lhs rhs))
    | _ -> raise WrongType

  let div lhs rhs =
    if compare rhs zero > 0 then lhs / rhs else max_int

  let ns =
    methods "core.Nat"
      [
        ("add", lift2 add);
        ("sub", lift2 sub);
        ("mul", lift2 mul);
        ("div", lift2 div);
        ("and", lift2 logand);
        ("or", lift2 logor);
        ("lt", comp (fun c -> c < 0));
        ("le", comp (fun c -> c <= 0));
        ("ne", comp (fun c -> c <> 0));
        ("eq", comp (fun c -> c == 0));
        ("ge", comp (fun c -> c >= 0));
        ("gt", comp (fun c -> c > 0));
      ]
end

let builtins =
  let no_code path = (path, Module { path; f = None }) in
  [
    no_code "core"; no_code "core.Bool"; no_code "core.Nat";
  ]
  @ Nat.ns @ Bool.ns
