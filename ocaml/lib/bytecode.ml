open Types

type state = {
  stack : obj BatVect.t ref;
  vars : value ref BatVect.t ref;
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

let get_method ns name receiver =
  Value.field ns name
    (Value.type' !(Value.var_of_obj receiver))

let rec invoke ns f args =
  let path = Value.unwrap_mod f in
  match Map.find path ns with
  | Module | Value _ -> raise Value.WrongType
  | Native f -> f (BatVect.to_list args)
  | Code insts ->
      eval_block insts ns (BatVect.map Value.var_of_obj args)
  | Constructor (type_, tag, fields) ->
      let args =
        BatVect.(map Value.unwrap_val args |> to_list)
      in
      let fields = List.combine fields args in
      Data { type_; tag; fields }

and eval_block insts ns vars =
  let state =
    { stack = ref BatVect.empty; vars = ref vars }
  in
  List.iter (eval ns state) insts;

  assert (BatVect.length !(state.stack) == 1);
  assert (BatVect.(length !(state.vars) == length vars));
  BatVect.get !(state.stack) 0 |> Value.unwrap_val

and eval ns { stack; vars } = function
  | Literal i -> push stack (Val (Nat i))
  | Unit -> push stack (Val Value.unit_)
  | Drop -> pop stack |> ignore
  | Field f -> push stack (Value.field ns f (pop stack))
  | Create ->
      pop stack |> Value.unwrap_val |> ref |> push vars
  | Destroy -> pop vars |> ignore
  | Reference i -> push stack (Ref (BatVect.get !vars i))
  | Load ->
      Val !(pop stack |> Value.unwrap_ref) |> push stack
  | Store ->
      let value = pop stack in
      let ref = pop stack in
      Value.unwrap_ref ref := Value.unwrap_val value
  | Method m ->
      let receiver = pop stack in
      push stack (get_method ns m receiver);
      push stack receiver
  | Global g -> push stack (Namespace.get ns g)
  | Call argc ->
      let stack', f, argv = split_end !stack argc in
      let result = invoke ns f argv in
      stack := stack';
      push stack (Val result)
  | Cases c ->
      let value = pop stack in
      let branch = List.assoc (Value.tag value) c in
      push stack (Val (eval_block branch ns !vars))
  | While (test, body) ->
      while Value.bool_of_t (eval_block test ns !vars) do
        ignore (eval_block body ns !vars)
      done
  | For body ->
      let iter = Ref (pop stack |> Value.var_of_obj) in
      let next = get_method ns "next" iter in
      Seq.of_dispenser (fun () ->
          invoke ns next (BatVect.singleton iter)
          |> Value.option_of_t)
      |> Seq.iter (fun item ->
             push vars (ref item);
             eval_block body ns !vars |> ignore;
             pop vars |> ignore)
