open Sexplib.Std

type value =
  | Data of {
      type_ : string;
      tag : string option; [@sexp.option]
      fields : (string * value) list; [@sexp.list]
    }
  | Nat of Uint64.t
  | Module of {
      path : string;
      f : (ns -> obj list -> value) option;
    }
[@@deriving sexp]

(* Things found on the stack. *)
and obj =
  | Val of value (* value *)
  | Ref of value ref (* reference to variable *)

(* Namespace *)
and ns = (string, value) Hashtbl.t

type inst =
  (* Basic operations *)
  | Literal of Uint64.t
  | Unit
  | Drop
  | Field of string
  (* Variables and references *)
  | Create
  | Destroy
  | Ref of int
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

let insts_of_sexp = Sexplib.Std.list_of_sexp inst_of_sexp
let sexp_of_insts = Sexplib.Std.sexp_of_list sexp_of_inst

type item =
  | Code of inst list [@sexp.list]
  | Unit of string
  | Constructor of string option * string list
[@@deriving sexp]
