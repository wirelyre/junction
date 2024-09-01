open Types

let mk_data type_ tag fields = Data { type_; tag; fields }
let unit_ = mk_data "core.Unit" None []

let scoped parent items =
  List.map
    (fun (path, item) ->
      Namespace.of_item (parent @ [ path ]) item)
    items
  |> List.fold_left Namespace.merge Namespace.empty

let under1 into from f = function
  | [ Val v ] -> into (f (from v))
  | _ -> raise WrongType

let under2 into from f = function
  | [ Val v1; Val v2 ] -> into (f (from v1) (from v2))
  | _ -> raise WrongType

module Bool = struct
  let to_val b =
    let tag = if b then "True" else "False" in
    mk_data "core.Bool" (Some tag) []

  let of_val = function
    | Data { type_ = "core.Bool"; tag = Some tag; _ } ->
        tag = "True"
    | _ -> raise WrongType

  let lift1 = under1 to_val of_val
  let lift2 = under2 to_val of_val

  let ns =
    scoped [ "core"; "Bool" ]
      [
        ("False", Value (to_val false));
        ("True", Value (to_val true));
        ("not", Native (lift1 not));
        ("and", Native (lift2 ( && )));
        ("or", Native (lift2 ( || )));
      ]
end

module Nat = struct
  open Uint64

  let to_val n = Nat n
  let of_val = function Nat n -> n | _ -> raise WrongType
  let lift1 = under1 to_val of_val
  let lift2 = under2 to_val of_val

  let div lhs rhs =
    if compare rhs zero > 0 then lhs / rhs else max_int

  let cmp f =
    under2 Bool.to_val of_val (fun x y -> f (compare x y) 0)

  let ns =
    scoped [ "core"; "Nat" ]
      [
        ("add", Native (lift2 add));
        ("sub", Native (lift2 sub));
        ("mul", Native (lift2 mul));
        ("div", Native (lift2 div));
        ("not", Native (lift1 lognot));
        ("and", Native (lift2 logand));
        ("or", Native (lift2 logor));
        ("lt", Native (cmp ( < )));
        ("le", Native (cmp ( <= )));
        ("ne", Native (cmp ( <> )));
        ("eq", Native (cmp ( == )));
        ("ge", Native (cmp ( >= )));
        ("gt", Native (cmp ( > )));
      ]
end

module Option = struct
  let of_val = function
    | Data { type_ = "core.Option"; fields; _ } ->
        List.assoc_opt "inner" fields
    | _ -> raise WrongType

  let ns =
    scoped [ "core"; "Option" ]
      [
        ( "None",
          Value (mk_data "core.Option" (Some "None") []) );
        ( "Some",
          Constructor
            ("core.Option", Some "Some", [ "inner" ]) );
      ]
end
