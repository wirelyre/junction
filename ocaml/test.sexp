; { 1 2 3 }
(
  (Literal 1) Drop
  (Literal 2) Drop
  (Literal 3)
)

; { 1 + 2 }
((Literal 1) (Method add) (Literal 2) (Call 2))

; { 1 / 0 }
((Literal 1) (Method div) (Literal 0) (Call 2))

; { 19 & 25 }
((Literal 19) (Method and) (Literal 25) (Call 2))

; { {2 - 5} / {1000000 - 1} }
(
  (Literal 2) (Method sub) (Literal 5) (Call 2)
  (Method div)
  (Literal 1000000) (Method sub) (Literal 1) (Call 2)
  (Call 2)
)

; { 10 < 11 }
((Literal 10) (Method lt) (Literal 11) (Call 2))

; { 15 >= 3 }
((Literal 15) (Method ge) (Literal 3) (Call 2))

; !{4 > 5}
((Literal 4) (Method gt) (Literal 5) (Call 2) (Method not) (Call 1))

; if 0 == 1 { 2 } else { 3 }
(
  (Literal 0) (Method eq) (Literal 1) (Call 2)
  (Cases ( ("True" ((Literal 2))) ("False" ((Literal 3))) ))
)

; if 0 != 1 { 2 } else { 3 }
(
  (Literal 0) (Method ne) (Literal 1) (Call 2)
  (Cases (("True" ((Literal 2))) ("False" ((Literal 3)))))
)

; { while 1 < 0 { 2 } 3 }
((While 
  ((Literal 1) (Method lt) (Literal 0) (Call 2))
  ((Literal 2)))
 (Literal 3))

; first Fibonacci >= 100
(
  (Literal 0) Create ; a := 0
  (Literal 1) Create ; b := 1
  ; while a < 100
  (While ((Ref 0) Load (Method lt) (Literal 100) (Call 2)) (
    ; tmp := a + b
    (Ref 0) Load (Method add) (Ref 1) Load (Call 2) Create
    (Ref 0) (Ref 1) Load Store ; a := b
    (Ref 1) (Ref 2) Load Store ; b := tmp
    Unit
    Destroy ; tmp
  ))
  (Ref 0) Load ; a
  Destroy ; b
  Destroy ; a
)
