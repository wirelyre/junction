open Sexplib.Std

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
  | Field f ->
      push stack (Val (Value.field ns f (pop stack)))
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

type item =
  | Code of inst list [@sexp.list]
  | Unit of string
  | Constructor of string option * string list
[@@deriving sexp]

let val_of_item = function
  | path, None -> (path, Value.Module { path; f = None })
  | path, Some (Code insts) ->
      let f ns args =
        eval_block insts ns
          (args
          |> List.map Value.named_var_of_obj
          |> BatVect.of_list)
      in
      (path, Value.Module { path; f = Some f })
  | type_, Some (Unit tag) ->
      ( type_ ^ "." ^ tag,
        Value.Data { type_; tag = Some tag; fields = [] } )
  | type_, Some (Constructor (tag, fields)) ->
      let path =
        match tag with
        | None -> type_
        | Some tag -> type_ ^ "." ^ tag
      in
      let constructor _ns args =
        let fields =
          Seq.zip
            (List.to_seq fields)
            (List.to_seq args |> Seq.map Value.val_of_obj)
          |> List.of_seq
        in
        Value.Data { type_; tag; fields }
      in
      (path, Value.Module { path; f = Some constructor })
