open Sexplib.Std

exception WrongType

type value =
  (* structure / tagged union *)
  | Data of {
      type_ : string;
      tag : string option; [@sexp.option]
      fields : (string * value) list; [@sexp.list]
    }
  | Nat of Uint64.t
[@@deriving sexp]

(* Things found on the stack. *)
type obj =
  | Val of value (* value *)
  | Ref of value ref (* reference to variable *)
  | Mod of string (* module/function in global namespace *)

type inst =
  (* Basic operations *)
  | Literal of Uint64.t
  | Unit
  | Drop
  | Field of string
  (* Variables and references *)
  | Create
  | Destroy
  | Reference of int
  | Load
  | Store
  (* Modules *)
  | Method of string
  | Global of string
  (* Control flow *)
  | Call of int
  | Cases of (string * inst list) list
  | While of inst list * inst list
  | For of inst list
[@@deriving sexp]

(* item in the global namespace *)
type item =
  | Module (* module with no code *)
  | Code of inst list (* user function with bytecode *)
      [@sexp.list]
  | Constructor of string * string option * string list
  | Native of (obj list -> value) (* native function *)
  | Value of value (* unit, like `core.Bool.True` *)
[@@deriving sexp]

type namespace = (string, item) Map.t [@@deriving sexp]

module Namespace = struct
  let empty = Map.empty

  let get ns path =
    match Map.find path ns with
    | Value v -> Val v
    | Module | Code _ | Constructor _ | Native _ -> Mod path

  let merge =
    Map.merge (fun path item1 item2 ->
        match (item1, item2) with
        | None, i | i, None -> i
        | Some (Value _), _ | _, Some (Value _) ->
            raise (Failure ("collision with value: " ^ path))
        | Some Module, i | i, Some Module -> i
        | _, _ -> raise (Failure ("duplicate item: " ^ path)))

  let of_item p item =
    let join a b = a ^ "." ^ b in
    let full = List.fold_left join "" p |> BatString.lchop in
    BatEnum.(
      append
        (BatList.enum p |> scan join
        |> map (fun path -> (path, Module)))
        (singleton (full, item)))
    |> Map.of_enum
end
