open Sexplib.Std

type inst =
  | Literal of Uint64.t
  | Drop
  | Method of string
  | Call of int
[@@deriving sexp]

let insts_of_sexp = Sexplib.Std.list_of_sexp inst_of_sexp
let sexp_of_insts = Sexplib.Std.sexp_of_list sexp_of_inst

type state = { stack : Value.t BatVect.t ref }

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

let rec eval_block insts =
  let state = { stack = ref BatVect.empty } in
  List.iter (eval state) insts;

  assert (BatVect.length !(state.stack) == 1);
  BatVect.get !(state.stack) 0

and eval { stack } = function
  | Literal i -> push stack (Value.Nat i)
  | Drop -> ignore (pop stack)
  | Method m ->
      let receiver = pop stack in
      push stack
        (Value.Function
           (BatHashtbl.find Value.Nat.methods m));
      push stack receiver
  | Call argc ->
      let stack', f, argv = split_end !stack argc in
      let result =
        (Value.fun_of_t f) (BatVect.to_list argv)
      in
      stack := stack';
      push stack result
