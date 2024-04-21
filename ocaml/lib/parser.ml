exception No_parse

module Lex : sig
  (* TODO: inline into module? *)
  type token =
    | Ident of string
    | Kw of string
    | Num of Uint64.t
    | Punct of string
    | String of string
  [@@deriving sexp]

  val lex : string -> token list
end = struct
  open Sexplib.Std

  type token =
    | Ident of string
    | Kw of string
    | Num of Uint64.t
    | Punct of string
    | String of string
  [@@deriving sexp]

  type lexer = { source : string; position : int }

  let whitespace = Str.regexp "\\([ \n]\\|#.*\n?\\)*"
  let punct = Str.regexp {|[][+*/%!|&<=>(){},.:^-]|}
  let ident = Str.regexp "[A-Za-z_][0-9A-Za-z_]*"
  let num = Str.regexp "[0-9]+"
  let string = Str.regexp {|"\([]-~ !#-[]\|\\["n\\]\)*"|}

  let any =
    Str.regexp
      {|[][+*/%!|&<=>(){},.:^-]\|[0-9A-Za-z_]+\|"\([]-~ !#-[]\|\\["n\\]\)*"|}

  let l_match l r =
    if Str.string_match r !l.source !l.position then (
      l := { !l with position = Str.match_end () };
      Some (Str.matched_string !l.source))
    else None

  let does_match r s =
    Str.string_match r s 0
    && Str.match_end () = String.length s

  let unescape s =
    Scanf.unescaped String.(sub s 1 (length s - 2))

  let identify s =
    match s with
    | "case" | "else" | "fn" | "for" | "if" | "impl" | "let"
    | "module" | "trait" | "type" | "use" | "while" ->
        Kw s
    | i when does_match ident i -> Ident i
    | n when does_match num n -> Num (Uint64.of_string n)
    | p when does_match punct p -> Punct p
    | s when does_match string s -> String (unescape s)
    | _ -> failwith "invalid character or number"

  let rec skip_brackets depth = function
    | Punct "[" :: rest -> skip_brackets (depth + 1) rest
    | Punct "]" :: rest -> skip_brackets (depth - 1) rest
    | _ :: rest when depth > 0 -> skip_brackets depth rest
    | tokens -> tokens

  let rec skip_type =
    (* types are completely ignored *)
    function
    | Ident _ :: rest -> skip_type rest
    | Punct "[" :: rest -> skip_brackets 1 rest
    | Punct "=" :: rest -> Punct ":=" :: rest
    | tokens -> tokens

  let rec combine acc =
    let punct p rest = combine (Punct p :: acc) rest in
    function
    | [] -> acc
    | Punct "=" :: Punct "=" :: rest -> punct "==" rest
    | Punct "!" :: Punct "=" :: rest -> punct "!=" rest
    | Punct "<" :: Punct "=" :: rest -> punct "<=" rest
    | Punct ">" :: Punct "=" :: rest -> punct ">=" rest
    | Punct "<" :: Punct "-" :: rest -> punct "<-" rest
    | Punct "-" :: Punct ">" :: rest -> punct "->" rest
    | Punct ":" :: rest -> combine acc (skip_type rest)
    | Punct "[" :: rest ->
        combine acc (skip_brackets 1 rest)
        (* TODO: duplicated logic *)
    | tok :: rest -> combine (tok :: acc) rest

  let lex source =
    let lexer = ref { source; position = 0 } in
    let advance () =
      assert (l_match lexer whitespace |> Option.is_some);
      l_match lexer any |> Option.map identify
    in
    let result = List.of_seq (Seq.of_dispenser advance) in
    if !lexer.position != String.length source then
      failwith "incomplete lex";

    result |> combine [] |> List.rev
end

open Lex

type binding = Global of string | Local of string * int

type state = {
  items : (string * Bytecode.item) list ref;
  root : string;
  current : string;
  local_c : int;
  ns : (string, binding) BatMap.t;
  output : Bytecode.inst BatVect.t ref;
}

let lookup s name : Bytecode.inst list =
  match BatMap.find_opt name s.ns with
  | Some (Global g) -> [ Global g ]
  | Some (Local (f, l)) when f = s.current ->
      [ Ref l; Load ]
  | Some (Local _) -> failwith "local in wrong scope"
  | None -> [ Global (s.root ^ "." ^ name) ]

let lookup_ref s name : Bytecode.inst list =
  match BatMap.find_opt name s.ns with
  | Some (Local (f, l)) when f = s.current -> [ Ref l ]
  | Some (Local _) -> failwith "local in wrong scope"
  | Some (Global _) -> failwith "not a ref"
  | None -> failwith "not in scope"

let append s insts =
  s.output := BatVect.(concat !(s.output) (of_list insts))

let output s after x =
  append s after;
  x

let require tok = function
  | tok' :: rest when tok = tok' -> rest
  | _ -> raise No_parse

let mk_new_output s = { s with output = ref BatVect.empty }
let unwrap_output s = BatVect.to_list !(s.output)

let add_local s i =
  {
    s with
    local_c = s.local_c + 1;
    ns = BatMap.add i (Local (s.current, s.local_c)) s.ns;
  }

let add_global s g n =
  { s with ns = BatMap.add n (Global g) s.ns }

(*


*)

let rec bin_prec ops s finally tokens =
  match ops with
  | [] -> finally tokens
  | this :: higher ->
      let higher = bin_prec higher s finally in
      let rec tail = function
        | Punct p :: rest when List.mem_assoc p this ->
            append s [ Bytecode.Method (List.assoc p this) ];
            higher rest |> output s [ Call 2 ] |> tail
        | tokens -> tokens
      in
      higher tokens |> tail

(*   path := IDENT ('.' IDENT)*   *)
let rec parse_path = function
  | head, _, Punct "." :: Ident tail :: rest ->
      parse_path (head ^ "." ^ tail, tail, rest)
  | path, last, tokens -> (path, last, tokens)

(*   params := '(' ')' | '(' param (',' param)* ','? ')'   *)
(*   param := '^'? IDENT ':' type   *)
let params =
  let rec params' building = function
    | Ident i :: Punct ")" :: rest
    | Ident i :: Punct "," :: Punct ")" :: rest
    (* TODO: check semantics *)
    | Punct "^" :: Ident i :: Punct ")" :: rest
    | Punct "^" :: Ident i :: Punct "," :: Punct ")" :: rest
      ->
        (BatVect.append i building, rest)
    | Ident i :: Punct "," :: rest ->
        params' (BatVect.append i building) rest
    | _ -> raise No_parse
  in
  function
  | Punct "(" :: Punct ")" :: rest -> (BatVect.empty, rest)
  | Punct "(" :: rest -> params' BatVect.empty rest
  | _ -> raise No_parse

(*   expr := ('!' | '-')* ...   *)
let rec expr s = function
  | Punct "!" :: rest ->
      expr s rest |> output s [ Method "not"; Call 1 ]
  | Punct "-" :: rest ->
      expr s rest |> output s [ Method "neg"; Call 1 ]
  | Punct "^" :: Ident _i :: _rest -> failwith "todo"
  | tokens -> expr_core s tokens

(*   ... (NUM | IDENT | IDENT '<-' IDENT call) ...   *)
and expr_core s = function
  | Num n :: rest ->
      append s [ Literal n ];
      expr_post s rest
  | Ident i :: Punct "<-" :: Ident m :: rest ->
      append s (lookup_ref s i);
      append s [ Method m ];
      expr_post s rest
  | Ident i :: rest ->
      append s (lookup s i);
      expr_post s rest
  | Punct "{" :: rest -> block s false rest |> expr_post s
  | _tokens -> raise No_parse (* TODO: tokens? *)

(*   ... ('.' IDENT | '->' IDENT call | call)*   *)
and expr_post s = function
  | Punct "." :: Ident f :: rest ->
      append s [ Bytecode.Field f ];
      expr_post s rest
  | Punct "->" :: Ident m :: rest ->
      append s [ Method m ];
      expr_post s rest
  | Punct "(" :: Punct ")" :: rest ->
      append s [ Call 0 ];
      expr_post s rest
  | Punct "(" :: rest -> expr_call s 1 rest |> expr_post s
  | tokens -> tokens

(*
     call := '(' ')'
           | '(' expr_loose (',' expr_loose)* ','? ')'
*)
and expr_call s argc tokens =
  match expr_loose s tokens with
  | Punct ")" :: rest | Punct "," :: Punct ")" :: rest ->
      append s [ Call argc ];
      rest
  | Punct "," :: rest -> expr_call s (argc + 1) rest
  | _ -> raise No_parse

(*
     branch := 'if' expr_loose block ('else' branch)?
             | 'case' (IDENT ':=')? expr_loose cases
     cases := '{' (IDENT '->' expr_loose)* '}'
*)
and branch s = function
  | Kw "if" :: condition ->
      let if_true = mk_new_output s in
      let if_false = mk_new_output s in

      let tail = function
        | Kw "else" :: rest -> branch if_false rest
        | rest -> output if_false [ Unit ] rest
      in

      expr_loose s condition
      |> require (Punct "{") |> block if_true false |> tail
      |> output s (* TODO: is correct precedence? *)
           [
             Cases
               [
                 ("True", unwrap_output if_true);
                 ("False", unwrap_output if_false);
               ];
           ]
  | Kw "case" :: Ident i :: Punct ":=" :: rest ->
      let cases = ref BatVect.empty in
      expr_loose s rest
      |> case_branches (add_local s i) cases
      |> output s [ Create; Ref s.local_c; Load ]
      |> output s [ Cases (BatVect.to_list !cases) ]
      |> output s [ Destroy ]
  | Kw "case" :: rest ->
      let cases = ref BatVect.empty in
      expr_loose s rest
      |> case_branches s cases
      |> output s [ Cases (BatVect.to_list !cases) ]
  | tokens -> expr s tokens

and case_branches s cases = function
  | Punct "{" :: rest -> case_branches s cases rest
  | Ident i :: Punct "->" :: rest ->
      let branch = mk_new_output s in
      let rest = expr_loose branch rest in
      cases :=
        BatVect.append (i, unwrap_output branch) !cases;
      case_branches s cases rest
  | Punct "}" :: rest -> rest
  | _ -> raise No_parse

(* precedence parsing *)
and expr_loose s tokens =
  bin_prec
    [
      [
        "==", "eq";
        "!=", "ne";
        "<", "lt";
        ">", "gt";
        "<=", "le";
        ">=", "ge";
      ];
      [ "+", "add"; "-", "sub"; "|", "or" ];
      [ "*", "mul"; "/", "div"; "%", "mod"; "&", "and" ];
    ]
    s (branch s) tokens
[@@ocamlformat "parens-tuple=multi-line-only"]

(*
     block := '{' stmt* '}'
     stmt := 'let' IDENT ':=' expr_loose
           | '^'? IDENT ':=' expr_loose
           | 'while' expr_loose block
           | 'for' IDENT ':=' expr_loose block
           | 'fn' IDENT '(' params ')' block
           | 'use' path
           | expr_loose
*)
and block s have_val =
  let drop () = if have_val then append s [ Drop ] in
  function
  | Punct "}" :: rest | ([] as rest) ->
      if not have_val then append s [ Unit ];
      rest
  | Kw "let" :: Ident i :: Punct ":=" :: rest ->
      drop ();
      expr_loose s rest |> output s [ Create ]
      |> block (add_local s i) false
      |> output s [ Destroy ]
  | Ident i :: Punct ":=" :: rest
  (* TODO: check semantics *)
  | Punct "^" :: Ident i :: Punct ":=" :: rest ->
      drop ();
      output s (lookup_ref s i) rest
      |> expr_loose s |> output s [ Store ] |> block s false
  | Kw "while" :: rest ->
      drop ();
      let test = mk_new_output s in
      let body = mk_new_output s in
      let rest' =
        expr_loose test rest
        |> require (Punct "{") |> block body false
      in
      append s
        [ While (unwrap_output test, unwrap_output body) ];
      block s false rest'
  | Kw "for" :: Ident i :: Punct ":=" :: rest ->
      drop ();
      let body = mk_new_output s in
      let rest' =
        expr_loose s rest |> require (Punct "{")
        |> block (add_local body i) false
      in
      append s [ For (unwrap_output body) ];
      block s false rest'
  | Kw "fn" :: Ident i :: rest ->
      drop ();
      (* in scope for child and rest of block *)
      let s = add_global s (s.current ^ "." ^ i) i in
      fn s i rest |> block s false
  | Kw "use" :: Ident head :: rest ->
      drop ();
      let full, name, rest =
        parse_path (head, head, rest)
      in
      let s = add_global s full name in
      block s false rest
  | tokens ->
      (* expr_stmt *)
      drop ();
      expr_loose s tokens |> block s true

and fn s name tokens =
  let args, rest = params tokens in
  let name = s.current ^ "." ^ name in
  let ns =
    BatVect.foldi
      (fun i ns arg -> BatMap.add arg (Local (name, i)) ns)
      s.ns args
  in
  let s' =
    {
      s with
      current = name;
      local_c = BatVect.length args;
      ns;
      output = ref BatVect.empty;
    }
  in

  match rest with
  | Punct "{" :: rest ->
      let rest = block s' false rest in
      s.items :=
        (name, Code (BatVect.to_list !(s'.output)))
        :: !(s.items);
      rest
  | _ -> raise No_parse

(*   file := 'module' path stmt*   *)
let parse_file tokens =
  match tokens with
  | Kw "module" :: Ident head :: rest ->
      let root, _, rest = parse_path (head, head, rest) in
      let s =
        {
          items = ref [];
          root;
          current = root;
          local_c = 0;
          ns = BatMap.empty;
          output = ref BatVect.empty;
        }
      in
      let rest = block s false rest in
      Sexplib.Std.sexp_of_list sexp_of_token rest
      |> Sexplib.Sexp.to_string |> print_endline;
      (*if not (List.length rest = 0) then
        failwith "incomplete parse";*)
      s.items :=
        (root, Code (BatVect.to_list !(s.output)))
        :: !(s.items);
      !(s.items)
  | _ -> raise No_parse
