open Types

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
  | Mod path -> Namespace.get ns (path ^ "." ^ f)
