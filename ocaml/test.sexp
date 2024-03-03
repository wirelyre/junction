; { 1 2 3 }
((expect (Nat 3)) (namespace
  ((main ((Literal 1) Drop
          (Literal 2) Drop
          (Literal 3))))))

; { 1 + 2 }
((expect (Nat 3)) (namespace
  ((main ((Literal 1) (Method add) (Literal 2) (Call 2))))))

; { 1 / 0 }
((expect (Nat 18446744073709551615)) (namespace
  ((main ((Literal 1) (Method div) (Literal 0) (Call 2))))))

; { 19 & 25 }
((expect (Nat 17)) (namespace
  ((main ((Literal 19) (Method and) (Literal 25) (Call 2))))))

; { {2 - 5} / {1000000 - 1} }
((expect (Nat 18446762520472)) (namespace
  ((main ((Literal 2) (Method sub) (Literal 5) (Call 2)
          (Method div)
          (Literal 1000000) (Method sub) (Literal 1) (Call 2)
          (Call 2))))))

; { 10 < 11 }
((expect (Bool true)) (namespace
  ((main ((Literal 10) (Method lt) (Literal 11) (Call 2))))))

; { 15 >= 3 }
((expect (Bool true)) (namespace
  ((main ((Literal 15) (Method ge) (Literal 3) (Call 2))))))

; !{4 > 5}
((expect (Bool true)) (namespace
  ((main ((Literal 4) (Method gt) (Literal 5) (Call 2) (Method not) (Call 1))))))

; if 0 == 1 { 2 } else { 3 }
((expect (Nat 3)) (namespace
  ((main ((Literal 0) (Method eq) (Literal 1) (Call 2)
          (Cases (("True" ((Literal 2))) ("False" ((Literal 3))))))))))

; if 0 != 1 { 2 } else { 3 }
((expect (Nat 2)) (namespace
  ((main ((Literal 0) (Method ne) (Literal 1) (Call 2)
          (Cases (("True" ((Literal 2))) ("False" ((Literal 3))))))))))

; { while 1 < 0 { 2 } 3 }
((expect (Nat 3)) (namespace
  ((main ((While
           ((Literal 1) (Method lt) (Literal 0) (Call 2))
           ((Literal 2)))
          (Literal 3))))))

; first Fibonacci >= 100
((expect (Nat 144)) (namespace
  ((main ((Literal 0) Create ; a := 0
          (Literal 1) Create ; b := 1
          ; while a < 100
          (While ((Ref 0) Load (Method lt) (Literal 100) (Call 2))
            ; tmp := a + b
            ((Ref 0) Load (Method add) (Ref 1) Load (Call 2) Create
             (Ref 0) (Ref 1) Load Store ; a := b
             (Ref 1) (Ref 2) Load Store ; b := tmp
             Unit
             Destroy ; tmp
          ))
          (Ref 0) Load ; a
          Destroy ; b
          Destroy ; a
)))))

; factorial(10)
((expect (Nat 3628800)) (namespace
  ((main ((Global factorial) (Literal 10) (Call 1)))
  (factorial (
  ; factorial(n: Nat): Nat
    (Ref 0) Load (Method eq) (Literal 0) (Call 2) ; if n == 0
    (Cases
      ((True ((Literal 1)))
       (False (
        ; n * factorial(n - 1)
        (Ref 0) Load (Method mul)
          (Global factorial)
            (Ref 0) Load (Method sub) (Literal 1) (Call 2)
          (Call 1)
        (Call 2))))))))))

; is_even(5)
((expect (Bool false)) (namespace
  ((main ((Global is_even) (Literal 5) (Call 1)))
   (is_even
     ; if n == 0 { True } else { is_odd(n - 1) }
     ((Ref 0) Load (Method eq) (Literal 0) (Call 2)
      (Cases
        ((True ((Global Bool.True) (Call 0)))
         (False ((Global is_odd) (Ref 0) Load (Method sub) (Literal 1) (Call 2) (Call 1)))))))
   (is_odd
     ; if n == 0 { False } else { is_even(n - 1) }
     ((Ref 0) Load (Method eq) (Literal 0) (Call 2)
      (Cases
        ((True  ((Global Bool.False) (Call 0)))
         (False ((Global is_odd) (Ref 0) Load (Method sub) (Literal 1) (Call 2) (Call 1)))))))
  ; Bool.True and .False currently functions
  (Bool.True ((Literal 0) (Method eq) (Literal 0) (Call 2)))
  (Bool.False ((Literal 0) (Method eq) (Literal 1) (Call 2))))))

; min(6, 7)
((expect (Nat 6)) (namespace
  ((main ((Global min) (Literal 6) (Literal 7) (Call 2)))
   (min
     ; min[T: Ord](a: T, b: T): T
     ; { if a <= b { a } else { b } }
     ((Ref 0) Load (Method le) (Ref 1) Load (Call 2)
      (Cases ((True  ((Ref 0) Load))
              (False ((Ref 1) Load)))))))))

((expect (Nat 3)) (namespace
  ((main
     ((Global test.Date)
      (Literal 2024) (Literal 3) (Literal 1) (Call 3)
      (Field month)))
   (test.Date
     ((Ref 0) Load (Ref 1) Load (Ref 2) Load
      (Construct test.Date None (year month day)))))))
