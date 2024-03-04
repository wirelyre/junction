open Sexplib.Std

type t =
  | Bool of bool
  | Data of {
      type_ : string;
      tag : string option;
      fields : (string * t) list;
    }
  | Nat of Uint64.t
  | Unit
  | Module of {
      path : string;
      f : (ns -> obj list -> t) option;
    }
[@@deriving sexp]

(* A value or reference.
 *
 * Temporary stack items are objects.
 * Function take objects as arguments, and return values.
 *)
and obj = Val of t | Ref of t ref

(* Namespace *)
and ns = (string, t) Hashtbl.t

exception WrongType

let bool_of_t = function
  | Bool b -> b
  | _ -> raise WrongType

let fun_of_t = function
  | Module { f = Some f; _ } -> f
  | _ -> raise WrongType

let type_ = function
  | Bool _ -> "core.Bool"
  | Data d -> d.type_
  | Nat _ -> "core.Nat"
  | Unit -> "core.Unit"
  | Module _ -> raise WrongType

let tag = function
  | Bool false -> "False"
  | Bool true -> "True"
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

let ns_of_methods mod_name mthds : ns =
  let path name = mod_name ^ "." ^ name in
  List.to_seq mthds
  |> Seq.map (fun (name, f) ->
         (name, Module { path = path name; f = Some f }))
  |> Hashtbl.of_seq

module Nat = struct
  open Uint64

  let lift2 f _ns = function
    | [ Val (Nat lhs); Val (Nat rhs) ] -> Nat (f lhs rhs)
    | _ -> raise WrongType

  let comp f _ns = function
    | [ Val (Nat lhs); Val (Nat rhs) ] ->
        Bool (f (compare lhs rhs))
    | _ -> raise WrongType

  let div lhs rhs =
    if compare rhs zero > 0 then lhs / rhs else max_int

  let methods =
    ns_of_methods "core.Nat"
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

module Bool = struct
  let lift1 f _ns = function
    | [ Val (Bool b) ] -> Bool (f b)
    | _ -> raise WrongType

  let lift2 f _ns = function
    | [ Val (Bool lhs); Val (Bool rhs) ] -> Bool (f lhs rhs)
    | _ -> raise WrongType

  let methods =
    ns_of_methods "core.Bool"
      [
        ("not", lift1 not);
        ("and", lift2 ( && ));
        ("or", lift2 ( || ));
      ]
end
