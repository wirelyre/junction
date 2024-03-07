; { 1 2 3 }
((expect (Nat 3)) (namespace
  ((main ((Code
           (Literal 1) Drop
           (Literal 2) Drop
           (Literal 3)))))))

; { 1 + 2 }
((expect (Nat 3)) (namespace
  ((main ((Code (Literal 1) (Method add) (Literal 2) (Call 2)))))))

; { 1 / 0 }
((expect (Nat 18446744073709551615)) (namespace
  ((main ((Code (Literal 1) (Method div) (Literal 0) (Call 2)))))))

; { 19 & 25 }
((expect (Nat 17)) (namespace
  ((main ((Code (Literal 19) (Method and) (Literal 25) (Call 2)))))))

; { {2 - 5} / {1000000 - 1} }
((expect (Nat 18446762520472)) (namespace
  ((main ((Code
           (Literal 2) (Method sub) (Literal 5) (Call 2)
           (Method div)
           (Literal 1000000) (Method sub) (Literal 1) (Call 2)
           (Call 2)))))))

; { 10 < 11 }
((expect (Data (type_ core.Bool) (tag True))) (namespace
  ((main ((Code (Literal 10) (Method lt) (Literal 11) (Call 2)))))))

; { 15 >= 3 }
((expect (Data (type_ core.Bool) (tag True))) (namespace
  ((main ((Code (Literal 15) (Method ge) (Literal 3) (Call 2)))))))

; !{4 > 5}
((expect (Data (type_ core.Bool) (tag True))) (namespace
  ((main ((Code (Literal 4) (Method gt) (Literal 5) (Call 2) (Method not) (Call 1)))))))

; if 0 == 1 { 2 } else { 3 }
((expect (Nat 3)) (namespace
  ((main ((Code
           (Literal 0) (Method eq) (Literal 1) (Call 2)
           (Cases (("True" ((Literal 2))) ("False" ((Literal 3)))))))))))

; if 0 != 1 { 2 } else { 3 }
((expect (Nat 2)) (namespace
  ((main ((Code
           (Literal 0) (Method ne) (Literal 1) (Call 2)
           (Cases (("True" ((Literal 2))) ("False" ((Literal 3)))))))))))

; { while 1 < 0 { 2 } 3 }
((expect (Nat 3)) (namespace
  ((main ((Code
           (While
            ((Literal 1) (Method lt) (Literal 0) (Call 2))
            ((Literal 2)))
           (Literal 3)))))))

; first Fibonacci >= 100
((expect (Nat 144)) (namespace
  ((main ((Code
           (Literal 0) Create ; a := 0
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
))))))

; factorial(10)
((expect (Nat 3628800)) (namespace
  ((main ((Code (Global factorial) (Literal 10) (Call 1))))
   (factorial ((Code
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
         (Call 2)))))))))))

; is_even(5)
((expect (Data (type_ core.Bool) (tag False))) (namespace
  ((main ((Code (Global is_even) (Literal 5) (Call 1))))
   (is_even ((Code
     ; if n == 0 { True } else { is_odd(n - 1) }
     (Ref 0) Load (Method eq) (Literal 0) (Call 2)
     (Cases
       ((True ((Global core.Bool.True)))
        (False ((Global is_odd) (Ref 0) Load (Method sub) (Literal 1) (Call 2) (Call 1))))))))
   (is_odd ((Code
     ; if n == 0 { False } else { is_even(n - 1) }
     (Ref 0) Load (Method eq) (Literal 0) (Call 2)
     (Cases
       ((True  ((Global core.Bool.False)))
        (False ((Global is_odd) (Ref 0) Load (Method sub) (Literal 1) (Call 2) (Call 1)))))))))))

; min(6, 7)
((expect (Nat 6)) (namespace
  ((main ((Code (Global min) (Literal 6) (Literal 7) (Call 2))))
   (min ((Code
     ; min[T: Ord](a: T, b: T): T
     ; { if a <= b { a } else { b } }
     (Ref 0) Load (Method le) (Ref 1) Load (Call 2)
     (Cases ((True  ((Ref 0) Load))
             (False ((Ref 1) Load))))))))))

((expect (Nat 3)) (namespace
  ((main ((Code
     (Global test.Date)
     (Literal 2024) (Literal 3) (Literal 1) (Call 3)
     (Field month))))
   (test.Date ((Constructor () (year month day)))))))

((expect (Nat 5)) (namespace
  ((main ((Code
           (Global core) (Field Nat) (Field add)
           (Literal 2) (Literal 3) (Call 2)))))))

((expect (Data (type_ test.MyBool) (tag True))) (namespace
  ((main ((Code (Global test) (Field MyBool) (Field True))))
   (test ())
   (test.MyBool ())
   (test.MyBool ((Unit False)))
   (test.MyBool ((Unit True))))))

((expect (Data (type_ core.Option) (tag Some) (fields ((inner (Nat 1))))))
 (namespace
  ((main ((Code (Global core.Option.Some) (Literal 1) (Call 1))))
   (core.Option ())
   (core.Option ((Unit None)))
   (core.Option ((Constructor (Some) (inner)))))))
