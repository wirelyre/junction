type inst = Literal of Uint64.t | Drop [@@deriving sexp]

let insts_of_sexp = Sexplib.Std.list_of_sexp inst_of_sexp
let sexp_of_insts = Sexplib.Std.sexp_of_list sexp_of_inst

type state = { stack : Value.t BatVect.t ref }

let push vec item = vec := BatVect.append item !vec

let pop vec =
  let item, rest = BatVect.pop !vec in
  vec := rest;
  item

let rec eval_block insts =
  let state = { stack = ref BatVect.empty } in
  List.iter (eval state) insts;

  assert (BatVect.length !(state.stack) == 1);
  BatVect.get !(state.stack) 0

and eval { stack } = function
  | Literal i -> push stack (Value.Nat i)
  | Drop -> ignore (pop stack)
