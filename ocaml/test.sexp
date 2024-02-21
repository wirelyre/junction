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
