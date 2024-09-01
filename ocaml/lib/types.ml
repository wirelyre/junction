open Sexplib.Std

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

type namespace = (string, item) Hashtbl.t [@@deriving sexp]

let ns_get ns path =
  match Hashtbl.find ns path with
  | Value v -> Val v
  | Module | Code _ | Constructor _ | Native _ -> Mod path
