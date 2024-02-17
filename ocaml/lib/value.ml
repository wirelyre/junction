type t = Nat of Uint64.t | Function of (t list -> t)
[@@deriving sexp]

exception WrongType

let uint64_of_t = function
  | Nat i -> i
  | _ -> raise WrongType

let fun_of_t = function
  | Function f -> f
  | _ -> raise WrongType

let type_ = function
  | Nat _ -> "std.Nat"
  | Function _ -> raise WrongType

module Nat = struct
  open Uint64

  let lift2 f = function
    | [ Nat lhs; Nat rhs ] -> Nat (f lhs rhs)
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
      ]
end
