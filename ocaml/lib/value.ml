type t = Nat of Uint64.t [@@deriving sexp]

let uint64_of_t = function Nat i -> i
let type_ = function Nat _ -> "std.Nat"
