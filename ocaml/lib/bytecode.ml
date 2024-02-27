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
  | Unit -> push stack (Val Unit)
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
  | Method m ->
      let receiver = pop stack in
      let table =
        match Value.val_of_obj receiver with
        | Bool _ -> Value.Bool.methods
        | Nat _ -> Value.Nat.methods
        | _ -> raise Value.WrongType
      in
      push stack
        (Val (Value.Function (BatHashtbl.find table m)));
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

let fun_of_bc insts =
  Value.Function
    (fun ns args ->
      eval_block insts ns
        (args
        |> List.map Value.named_var_of_obj
        |> BatVect.of_list))
