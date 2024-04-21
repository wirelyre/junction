exception No_parse

module Lex : sig
  type token =
    | Ident of string
    | Kw of string
    | Num of Uint64.t
    | Punct of string
    | String of string
  [@@deriving sexp]

  val lex : string -> token list
  val identify : string -> token
  val string : Str.regexp
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
    | "mod" | "trait" | "type" | "use" | "while" ->
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

type binding = Global of string | Local of string * int

type state = {
  modules : (string * Bytecode.inst list) list ref;
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

let output s (x : Lex.token list) after =
  append s after;
  x

let replicate x i =
  Seq.repeat x |> Seq.take i |> List.of_seq

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

type parser = Lex.token list -> Lex.token list

(*


*)

let rec bin_prec ops s finally : parser =
 fun tokens ->
  match ops with
  | [] -> finally tokens
  | this :: higher ->
      let higher = bin_prec higher s finally in
      let rec tail = function
        | Lex.Punct p :: rest when List.mem_assoc p this ->
            append s [ Bytecode.Method (List.assoc p this) ];
            output s (higher rest) [ Call 2 ] |> tail
        | tokens -> tokens
      in
      higher tokens |> tail

(*   path := IDENT ('.' IDENT)*   *)
let rec parse_path : string * string * Lex.token list -> _ =
  function
  | head, _, Punct "." :: Ident tail :: rest ->
      parse_path (head ^ "." ^ tail, tail, rest)
  | path, last, tokens -> (path, last, tokens)

let args : Lex.token list -> _ =
  let rec args' building : Lex.token list -> _ = function
    | Ident i :: Punct ")" :: rest
    | Ident i :: Punct "," :: Punct ")" :: rest ->
        (BatVect.append i building, rest)
    | Ident i :: Punct "," :: rest ->
        args' (BatVect.append i building) rest
    | _ -> raise No_parse
  in
  function
  | Punct "(" :: Punct ")" :: rest -> (BatVect.empty, rest)
  | Punct "(" :: rest -> args' BatVect.empty rest
  | _ -> raise No_parse

(*  expr := ('!' | '-')* ...   *)
let rec expr_pre s : parser = function
  | Punct "!" :: rest ->
      output s (expr_pre s rest) [ Method "not"; Call 1 ]
  | Punct "-" :: rest ->
      output s (expr_pre s rest) [ Method "neg"; Call 1 ]
  | Punct "^" :: Ident _i :: _rest -> failwith "todo"
  | tokens -> expr_core s tokens

(*   ... (NUM | IDENT | IDENT '<-' IDENT call) ...   *)
and expr_core s : parser = function
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
and expr_post s : parser = function
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
  | Lex.Punct ")" :: rest | Punct "," :: Punct ")" :: rest
    ->
      append s [ Call argc ];
      rest
  | Lex.Punct "," :: rest -> expr_call s (argc + 1) rest
  | _ -> raise No_parse

and branch s : parser = function
  | Lex.Kw "if" :: condition ->
      let if_true = mk_new_output s in
      let if_false = mk_new_output s in

      let true_branch = expr_loose s condition in
      let false_branch =
        match true_branch with
        | Lex.Punct "{" :: rest -> block if_true false rest
        | _ -> raise No_parse
      in
      let rest =
        match false_branch with
        | Lex.Kw "else" :: rest -> branch if_false rest
        | rest -> output if_false rest [ Unit ]
      in

      output s rest (* TODO: is correct precedence? *)
        [
          Cases
            [
              ("True", unwrap_output if_true);
              ("False", unwrap_output if_false);
            ];
        ]
  | Lex.Kw "case" :: Ident i :: Punct ":=" :: rest ->
      let cases = ref BatVect.empty in
      let rest =
        expr_loose s rest
        |> case_branches (add_local s i) cases
      in
      append s [ Create; Ref s.local_c; Load ];
      append s [ Cases (BatVect.to_list !cases) ];
      output s rest [ Destroy ]
  | Lex.Kw "case" :: rest ->
      let cases = ref BatVect.empty in
      let rest =
        expr_loose s rest |> case_branches s cases
      in
      output s rest [ Cases (BatVect.to_list !cases) ]
  | tokens -> expr_pre s tokens

and case_branches s cases : parser = function
  | Lex.Punct "{" :: rest -> case_branches s cases rest
  | Lex.Ident i :: Punct "->" :: rest ->
      let branch = mk_new_output s in
      let rest = expr_loose branch rest in
      cases :=
        BatVect.append (i, unwrap_output branch) !cases;
      case_branches s cases rest
  | Lex.Punct "}" :: rest -> rest
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

and block s have_val : parser =
  let drop () = if have_val then append s [ Drop ] in
  function
  | Punct "}" :: rest | ([] as rest) ->
      if not have_val then append s [ Unit ];
      rest
  | Kw "let" :: Ident i :: Punct ":=" :: rest ->
      drop ();
      let rest = output s (expr_loose s rest) [ Create ] in
      output s
        (block (add_local s i) false rest)
        [ Destroy ]
  | Ident i :: Punct ":=" :: rest ->
      drop ();
      append s (lookup_ref s i);
      output s (expr_loose s rest) [ Store ]
      |> block s false
  | Kw "while" :: rest ->
      drop ();
      let test = mk_new_output s in
      let body = mk_new_output s in
      let rest' =
        match expr_loose test rest with
        | Punct "{" :: rest -> block body false rest
        | _ -> raise No_parse
      in
      append s
        [ While (unwrap_output test, unwrap_output body) ];
      block s false rest'
  | Kw "fn" :: Ident i :: rest ->
      drop ();
      (* in scope for child and rest of block *)
      let s = add_global s (s.current ^ "." ^ i) i in
      let rest = fn s i rest in
      block s false rest
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

and fn (s : state) name tokens =
  let args, rest = args tokens in
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
      s.modules :=
        (name, BatVect.to_list !(s'.output)) :: !(s.modules);
      rest
  | _ -> raise No_parse

(*   file := 'mod' path stmt*   *)
let parse_file (tokens : Lex.token list) :
    (string * Bytecode.inst list) list =
  match tokens with
  | Kw "mod" :: Ident head :: rest ->
      let root, _, rest = parse_path (head, head, rest) in
      let s =
        {
          modules = ref [];
          root;
          current = root;
          local_c = 0;
          ns = BatMap.empty;
          output = ref BatVect.empty;
        }
      in
      let rest = block s false rest in
      Sexplib.Std.sexp_of_list Lex.sexp_of_token rest
      |> Sexplib.Sexp.to_string |> print_endline;
      (*if not (List.length rest = 0) then
        failwith "incomplete parse";*)
      s.modules :=
        (root, BatVect.to_list !(s.output)) :: !(s.modules);
      !(s.modules)
  | _ -> raise No_parse

(*
module Lex2 = struct
  type lexer = { source : string; position : int }

  let at_end l = !l.position = String.length !l.source

  let peek l =
    if !l.position = String.length !l.source then None
    else Some !l.source.[!l.position]

  let advance l =
    l := { !l with position = !l.position + 1 }

  let scan (f : char -> bool) (l : lexer ref) : string =
    let start = !l.position in
    while
      match peek l with None -> false | Some c -> f c
    do
      advance l
    done;
    String.sub !l.source start !l.position

  let rec skip_comment l =
    match peek l with
    | None -> ()
    | Some '\n' -> advance l
    | Some ' ' .. '~' ->
        advance l;
        skip_comment l
    | _ -> failwith "invalid character"

  let rec skip_ws l =
    match peek l with
    | Some (' ' | '\n') ->
        advance l;
        skip_ws l
    | Some '#' ->
        advance l;
        skip_comment l
    | _ -> ()

  let next_token l : Lex.token option =
    let ident =
      scan (function
        | '0' .. '9' | 'A' .. 'Z' | 'a' .. 'z' | '_' -> true
        | _ -> false)
    in
    let num =
      scan (function
        | '0' .. '9' -> true
        | 'A' .. 'Z' | 'a' .. 'z' | '_' ->
            failwith "invalid number"
        | _ -> false)
    in
    match peek l with
    | None -> None
    | Some '0' .. '9' -> Some (Num (num l))
    | Some ('A' .. 'Z' | 'a' .. 'z' | '_') -> (
        match ident l with
        | ( "case" | "else" | "fn" | "for" | "if" | "impl"
          | "let" | "mod" | "trait" | "type" | "while" ) as
          s ->
            Some (Kw s)
        | s -> Some (Ident s))
    | Some
        (( '+' | '-' | '*' | '/' | '%' | '!' | '|' | '&'
         | '<' | '=' | '>' | '(' | ')' | '{' | '}' | '['
         | ']' | ',' | '.' | ':' | '^' ) as c) ->
        Some (Punct (String.make 1 c))
    | _ -> failwith "invalid character"
end
*)

(*exception No_parse

type binding =
  | Global of string
  | Local of { scope : string; index : int }

type parser_input = {
  remaining_tokens : string list;
  top_level_module : string;
  scope : (string * binding) list;
}

(* looks up a value (or module) *)
let lookup_val top_level_module this_module scope name =
  match List.assoc_opt name scope with
  | None ->
      [ Bytecode.Global (top_level_module ^ "." ^ name) ]
  | Some (Global n) -> [ Bytecode.Global n ]
  | Some (Local l) when l.scope = this_module ->
      [ Bytecode.Ref l.index; Bytecode.Load ]
  | _ -> raise No_parse

(* looks up ref suitable for <- operator *)
let lookup_ref this_module scope (name : string) =
  match List.assoc_opt name scope with
  | Some (Local l) when l.scope = this_module ->
      [ Bytecode.Ref l.index ]
  | _ -> raise No_parse




  and parse_expr = function
    | Keyword "if" :: _rest -> failwith "todo"
    | Keyword "else" :: _rest -> failwith "todo"
    | Keyword "match" :: _rest -> failwith "todo"
    | tokens -> parse_loose tokens

  and parse_stmt = function
    | Keyword "let"
      :: Identifier _name
      :: Punctuation ":="
      :: rest ->
        output (parse_expr rest) [ Create ]
        (* TODO: add binding until end of block *)
        (* TODO: add Destroy at end of block *)
    | tokens -> output (parse_expr tokens) [ Drop ]
    (* TODO: only Drop before next statement in block
             expr_stmt stmt -> expr_stmt Drop stmt *)
  and parse_block = function _ -> () in

  assert (List.length (parse_stmt tokens) = 0);
  BatVect.to_list !insts
[@@ocamlformat "parens-tuple=multi-line-only"]
(* [@@ocamlformat "disable"] *)

(*
  and parse_loose tokens =
    parse_tight tokens |> parse_loose_tail
  and parse_loose_tail = function
    | Punctuation "+" :: rest ->
        output (parse_tight rest) [ Method "add"; Call 2 ]
        |> parse_loose_tail
    | Punctuation "-" :: rest ->
        output (parse_tight rest) [ Method "sub"; Call 2 ]
        |> parse_loose_tail
    | Punctuation "|" :: rest ->
        output (parse_tight rest) [ Method "or"; Call 2 ]
        |> parse_loose_tail
    | tokens -> tokens
  and parse_tight tokens =
    parse_not tokens |> parse_tight_tail
  and parse_tight_tail = function
    | Punctuation "*" :: rest ->
        output (parse_not rest) [ Method "mul"; Call 2 ]
        |> parse_tight_tail
    | Punctuation "/" :: rest ->
        output (parse_not rest) [ Method "div"; Call 2 ]
        |> parse_tight_tail
    | Punctuation "%" :: rest ->
        output (parse_not rest) [ Method "mod"; Call 2 ]
        |> parse_tight_tail
    | tokens -> tokens
*)

(*








 *)



 *)
