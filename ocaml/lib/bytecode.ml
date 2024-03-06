open Sexplib.Std

type inst =
  (* Basic operations *)
  | Literal of Uint64.t
  | Unit
  | Drop
  (* Variables and references *)
  | Create
  | Destroy
  | Ref of int
  | Load
  | Store
  (* Data *)
  | Construct of string * string option * string list
  | Field of string
  (* Modules *)
  | Method of string
  | Global of string
  (* Control flow *)
  | Call of int
  | Cases of (string * inst list) list
  | While of inst list * inst list
[@@deriving sexp]

let insts_of_sexp = Sexplib.Std.list_of_sexp inst_of_sexp
let sexp_of_insts = Sexplib.Std.sexp_of_list sexp_of_inst

type state = {
  stack : Value.obj BatVect.t ref;
  vars : Value.t ref BatVect.t ref;
}

let push vec item = vec := BatVect.append item !vec

let pop vec =
  let item, rest = BatVect.pop !vec in
  vec := rest;
  item

let split_end vec n =
  let len = BatVect.length vec in
  ( BatVect.sub vec 0 (len - n - 1),
    BatVect.get vec (len - n - 1),
    BatVect.sub vec (len - n) n )

let construct names stack =
  let offset = BatVect.length !stack - List.length names in
  let value =
    Seq.(
      ints offset
      |> map (BatVect.get !stack)
      |> map Value.val_of_obj
      |> zip (List.to_seq names))
    |> List.of_seq
  in
  stack := BatVect.sub !stack 0 offset;
  value

let rec eval_block insts ns vars =
  let state =
    { stack = ref BatVect.empty; vars = ref vars }
  in
  List.iter (eval ns state) insts;

  assert (BatVect.length !(state.stack) == 1);
  assert (BatVect.(length !(state.vars) == length vars));
  BatVect.get !(state.stack) 0 |> Value.val_of_obj

and eval ns { stack; vars } = function
  | Literal i -> push stack (Val (Value.Nat i))
  | Unit -> push stack (Val Value.unit_)
  | Drop -> pop stack |> ignore
  | Create ->
      pop stack |> Value.val_of_obj |> ref |> push vars
  | Destroy -> pop vars |> ignore
  | Ref i -> push stack (Ref (BatVect.get !vars i))
  | Load ->
      Val !(pop stack |> Value.ref_of_obj) |> push stack
  | Store ->
      let value = pop stack in
      let ref = pop stack in
      Value.ref_of_obj ref := Value.val_of_obj value
  | Construct (type_, tag, fields) ->
      let fields = construct fields stack in
      push stack (Val (Data { type_; tag; fields }))
  | Field f ->
      push stack (Val (Value.field ns f (pop stack)))
  | Method m ->
      let receiver = pop stack in
      let type_ = Value.type_ receiver in
      eval ns { stack; vars } (Global type_);
      eval ns { stack; vars } (Field m);
      push stack receiver
  | Global g -> push stack (Val (BatHashtbl.find ns g))
  | Call argc ->
      let stack', f, argv = split_end !stack argc in
      let result =
        (Value.fun_of_obj f) ns (BatVect.to_list argv)
      in
      stack := stack';
      push stack (Val result)
  | Cases c ->
      let value = pop stack in
      let branch =
        List.assoc (Value.tag (Value.val_of_obj value)) c
      in
      push stack (Val (eval_block branch ns !vars))
  | While (test, body) ->
      while Value.bool_of_t (eval_block test ns !vars) do
        ignore (eval_block body ns !vars)
      done

type item = Code of inst list [@sexp.list]
[@@deriving sexp]

let val_of_item = function
  | path, Code insts ->
      let f ns args =
        eval_block insts ns
          (args
          |> List.map Value.named_var_of_obj
          |> BatVect.of_list)
      in
      (path, Value.Module { path; f = Some f })
