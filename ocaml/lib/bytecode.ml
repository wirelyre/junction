open Batteries
open Types

type state = {
  stack : obj Vect.t ref;
  vars : value ref Vect.t ref;
}

let push vec item = vec := Vect.append item !vec

let pop vec =
  let item, rest = Vect.pop !vec in
  vec := rest;
  item

let split_end vec n =
  let len = Vect.length vec in
  ( Vect.sub vec 0 (len - n - 1),
    Vect.get vec (len - n - 1),
    Vect.sub vec (len - n) n )

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

let get_method ns name receiver =
  field ns name (type' !(var_of_obj receiver))

let rec invoke ns f args =
  let path = unwrap_mod f in
  match Map.find path ns with
  | Module | Value _ -> raise WrongType
  | Native f -> f (Vect.to_list args)
  | Code insts ->
      eval_block insts ns (Vect.map var_of_obj args)
  | Constructor (type_, tag, fields) ->
      let args = Vect.(map unwrap_val args |> to_list) in
      let fields = List.combine fields args in
      Data { type_; tag; fields }

and eval_block insts ns vars =
  let state = { stack = ref Vect.empty; vars = ref vars } in
  List.iter (eval ns state) insts;

  assert (Vect.length !(state.stack) == 1);
  assert (Vect.(length !(state.vars) == length vars));
  Vect.get !(state.stack) 0 |> unwrap_val

and eval ns { stack; vars } = function
  | Literal i -> push stack (Val (Nat i))
  | Unit -> push stack (Val Builtins.unit_)
  | Drop -> pop stack |> ignore
  | Field f -> push stack (field ns f (pop stack))
  | Create -> pop stack |> unwrap_val |> ref |> push vars
  | Destroy -> pop vars |> ignore
  | Reference i -> push stack (Ref (Vect.get !vars i))
  | Load -> Val !(pop stack |> unwrap_ref) |> push stack
  | Store ->
      let value = pop stack in
      let ref = pop stack in
      unwrap_ref ref := unwrap_val value
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
      let branch = List.assoc (tag value) c in
      push stack (Val (eval_block branch ns !vars))
  | While (test, body) ->
      while
        Builtins.Bool.of_val (eval_block test ns !vars)
      do
        ignore (eval_block body ns !vars)
      done
  | For body ->
      let iter = Ref (pop stack |> var_of_obj) in
      let next = get_method ns "next" iter in
      Seq.of_dispenser (fun () ->
          invoke ns next (Vect.singleton iter)
          |> Builtins.Option.of_val)
      |> Seq.iter (fun item ->
             push vars (ref item);
             eval_block body ns !vars |> ignore;
             pop vars |> ignore)
