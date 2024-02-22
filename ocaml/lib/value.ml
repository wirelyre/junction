open Sexplib.Std

type t =
  | Bool of bool
  | Nat of Uint64.t
  | Unit
  | Function of (t list -> t)
[@@deriving sexp]

exception WrongType

let fun_of_t = function
  | Function f -> f
  | _ -> raise WrongType

let type_ = function
  | Bool _ -> "core.Bool"
  | Nat _ -> "core.Nat"
  | Unit -> "core.Unit"
  | Function _ -> raise WrongType

let tag = function
  | Bool false -> "False"
  | Bool true -> "True"
  | _ -> raise WrongType

module Nat = struct
  open Uint64

  let lift2 f = function
    | [ Nat lhs; Nat rhs ] -> Nat (f lhs rhs)
    | _ -> raise WrongType

  let comp f = function
    | [ Nat lhs; Nat rhs ] -> Bool (f (compare lhs rhs))
    | _ -> raise WrongType

  let div lhs rhs =
    if compare rhs zero > 0 then lhs / rhs else max_int

  let methods =
    BatHashtbl.of_list
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
  let lift1 f = function
    | [ Bool b ] -> Bool (f b)
    | _ -> raise WrongType

  let lift2 f = function
    | [ Bool lhs; Bool rhs ] -> Bool (f lhs rhs)
    | _ -> raise WrongType

  let methods =
    BatHashtbl.of_list
      [
        ("not", lift1 not);
        ("and", lift2 ( && ));
        ("or", lift2 ( || ));
      ]
end
