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

let unwrap_val = function Val v -> v | _ -> raise WrongType
let unwrap_ref = function Ref r -> r | _ -> raise WrongType
let unwrap_mod = function Mod p -> p | _ -> raise WrongType

let var_of_obj = function
  | Val v -> ref v
  | Ref r -> r
  | _ -> raise WrongType

let type' = function
  | Data d -> Mod d.type_
  | Nat _ -> Mod "core.Nat"

let tag = function
  | Val (Data { tag = Some t; _ }) -> t
  | _ -> raise WrongType

let field ns f = function
  | Val (Data { fields; _ }) -> Val (List.assoc f fields)
  | Val (Nat _) -> raise WrongType (* Nat has no fields *)
  | Ref _ -> raise WrongType (* cannot call Field on a Ref *)
  | Mod path -> ns_get ns (path ^ "." ^ f)

let option_of_t = function
  | Data { type_ = "core.Option"; fields; _ } ->
      List.assoc_opt "inner" fields
  | _ -> raise WrongType

let methods mod_name =
  let path name = mod_name ^ "." ^ name in
  List.map (fun (name, f) -> (path name, Native f))

module Bool = struct
  let lift1 f = function
    | [ Val b ] -> t_of_bool (f (bool_of_t b))
    | _ -> raise WrongType

  let lift2 f = function
    | [ Val lhs; Val rhs ] ->
        t_of_bool (f (bool_of_t lhs) (bool_of_t rhs))
    | _ -> raise WrongType

  let ns =
    [
      ("core.Bool.False", Value (t_of_bool false));
      ("core.Bool.True", Value (t_of_bool true));
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

  let lift2 f = function
    | [ Val (Nat lhs); Val (Nat rhs) ] -> Nat (f lhs rhs)
    | _ -> raise WrongType

  let comp f = function
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
  let no_code path = (path, Module) in
  [ no_code "core"; no_code "core.Bool"; no_code "core.Nat" ]
  @ Nat.ns @ Bool.ns
