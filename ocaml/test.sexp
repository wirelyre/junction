((sources ("module main   1 2 3")) (expect (Nat 3))
 (namespace
  ((main ((Code
           (Literal 1) Drop
           (Literal 2) Drop
           (Literal 3)))))))

((sources ("module main   1 + 2")) (expect (Nat 3))
 (namespace
  ((main ((Code (Literal 1) (Method add) (Literal 2) (Call 2)))))))

((sources ("module main   1 / 0")) (expect (Nat 18446744073709551615))
 (namespace
  ((main ((Code (Literal 1) (Method div) (Literal 0) (Call 2)))))))

((sources ("module main   19 & 25")) (expect (Nat 17))
 (namespace
  ((main ((Code (Literal 19) (Method and) (Literal 25) (Call 2)))))))

((sources ("module main   {2 - 5} / {1000000 - 1}")) (expect (Nat 18446762520472))
 (namespace
  ((main ((Code
           (Literal 2) (Method sub) (Literal 5) (Call 2)
           (Method div)
           (Literal 1000000) (Method sub) (Literal 1) (Call 2)
           (Call 2)))))))

((sources ("module main   10 < 11")) (expect (Data (type_ core.Bool) (tag True)))
 (namespace
  ((main ((Code (Literal 10) (Method lt) (Literal 11) (Call 2)))))))

((sources ("module main   { 15 >= 3 }")) (expect (Data (type_ core.Bool) (tag True)))
 (namespace
  ((main ((Code (Literal 15) (Method ge) (Literal 3) (Call 2)))))))

((sources ("module main   !{4 > 5}")) (expect (Data (type_ core.Bool) (tag True)))
 (namespace
  ((main ((Code (Literal 4) (Method gt) (Literal 5) (Call 2) (Method not) (Call 1)))))))

((sources ("module main   if 0 == 1 { 2 } else { 3 }")) (expect (Nat 3))
 (namespace
  ((main ((Code
           (Literal 0) (Method eq) (Literal 1) (Call 2)
           (Cases (("True" ((Literal 2))) ("False" ((Literal 3)))))))))))

((sources ("module main   if 0 != 1 { 2 } else { 3 }")) (expect (Nat 2))
 (namespace
  ((main ((Code
           (Literal 0) (Method ne) (Literal 1) (Call 2)
           (Cases (("True" ((Literal 2))) ("False" ((Literal 3)))))))))))

((sources ("module main   while 1 < 0 { 2 } 3")) (expect (Nat 3))
 (namespace
  ((main ((Code
           (While
            ((Literal 1) (Method lt) (Literal 0) (Call 2))
            ((Literal 2)))
           (Literal 3)))))))

; first Fibonacci >= 100
((sources
   ("module main
     let a := 0
     let b := 1
     while a < 100 {
         let tmp := a + b
         a := b
         b := tmp
     }
     a"))
 (expect (Nat 144))
 (namespace
  ((main ((Code
           (Literal 0) Create
           (Literal 1) Create
           (While ((Ref 0) Load (Method lt) (Literal 100) (Call 2))
             ((Ref 0) Load (Method add) (Ref 1) Load (Call 2) Create
              (Ref 0) (Ref 1) Load Store
              (Ref 1) (Ref 2) Load Store
              Unit
              Destroy))
           (Ref 0) Load
           Destroy
           Destroy))))))

; factorial(10)
((sources
   ("module main
     fn factorial(n: Nat): Nat {
         if n == 0 { 1 }
         else { n * factorial(n - 1) }
     }
     factorial(10)"))
 (expect (Nat 3628800))
 (namespace
  ((main ((Code (Global main.factorial) (Literal 10) (Call 1))))
   (main.factorial ((Code
     (Ref 0) Load (Method eq) (Literal 0) (Call 2)
     (Cases
       ((True ((Literal 1)))
        (False ((Ref 0) Load (Method mul)
                (Global main.factorial)
                (Ref 0) Load (Method sub) (Literal 1) (Call 2)
                (Call 1) (Call 2)))))))))))

; is_even(5)
((sources
   ("module main
     use core.Bool.True
     use core.Bool.False
     fn is_even(n: Nat): Bool {
         if n == 0 { True }
         else { is_odd(n - 1) }
     }
     fn is_odd(n: Nat): Bool {
         if n == 0 { False }
         else { is_even(n - 1) }
     }
     is_even(5)"))
 (expect (Data (type_ core.Bool) (tag False)))
 (namespace
  ((main ((Code (Global main.is_even) (Literal 5) (Call 1))))
   (main.is_even ((Code
     (Ref 0) Load (Method eq) (Literal 0) (Call 2)
     (Cases
       ((True ((Global core.Bool.True)))
        (False ((Global main.is_odd) (Ref 0) Load (Method sub) (Literal 1) (Call 2) (Call 1))))))))
   (main.is_odd ((Code
     (Ref 0) Load (Method eq) (Literal 0) (Call 2)
     (Cases
       ((True  ((Global core.Bool.False)))
        (False ((Global main.is_even) (Ref 0) Load (Method sub) (Literal 1) (Call 2) (Call 1)))))))))))

; min(6, 7)
((sources
   ("module main
    fn min[T: Ord](a: T, b: T): T {
        if a <= b { a } else { b }
    }
    min(6, 7)"))
 (expect (Nat 6))
 (namespace
  ((main ((Code (Global main.min) (Literal 6) (Literal 7) (Call 2))))
   (main.min ((Code
     (Ref 0) Load (Method le) (Ref 1) Load (Call 2)
     (Cases ((True  ((Ref 0) Load))
             (False ((Ref 1) Load))))))))))

((sources
   ("module main
     use test.Date
     Date(2024, 3, 1).month"

    "module test
     type Date(year: Nat, month: Nat, day: Nat)"))
 (expect (Nat 3))
 (namespace
  ((main ((Code
     (Global test.Date)
     (Literal 2024) (Literal 3) (Literal 1) (Call 3)
     (Field month))))
   (test ())
   (test.Date ((Constructor () (year month day)))))))

((sources
   ("module main
     use core
     core.Nat.add(2, 3)"))
 (expect (Nat 5))
 (namespace
  ((main ((Code
           (Global core) (Field Nat) (Field add)
           (Literal 2) (Literal 3) (Call 2)))))))

; ((sources
;    ("module main
;      use test
;      test.MyBool.True"

;     "module test
;      type MyBool (False | True)"))
;  (expect (Data (type_ test.MyBool) (tag True)))
;  (namespace
;   ((main ((Code (Global test) (Field MyBool) (Field True))))
;    (test ())
;    (test.MyBool ())
;    (test.MyBool ((Unit False)))
;    (test.MyBool ((Unit True))))))

;((expect (Data (type_ core.Option) (tag Some) (fields ((inner (Nat 1))))))
; (namespace
;  ((main ((Code (Global core.Option.Some) (Literal 1) (Call 1))))
;   (core.Option ())
;   (core.Option ((Unit None)))
;   (core.Option ((Constructor (Some) (inner)))))))
;
;; 1 + 2 + ... + 100
;((expect (Nat 5050)) (namespace
;  ((main ((Code
;   ; let sum := 0
;   ; for n := range(1, 101) { sum := sum + n }
;   ; sum
;     (Literal 0) Create
;     (Global std.range) (Literal 1) (Literal 101) (Call 2)
;     (For (
;       (Ref 0) (Ref 0) Load (Method add) (Ref 1) Load (Call 2) Store
;       Unit))
;     (Ref 0) Load
;     Destroy)))
;   
;   ; type Option[T](None | Some(inner: T))
;   (core.Option ())
;   (core.Option ((Unit None)))
;   (core.Option ((Constructor (Some) (inner))))
;   
;   ; type range(start: Nat, end: Nat)
;   (std.range ((Constructor () (start end))))
;   
;   ; impl range {
;   ;     fn next(^self): Option[Nat] {
;   ;         if self.start < self.end {
;   ;             ^self := range(self.start + 1, self.end)
;   ;             Some(self.start - 1)
;   ;         } else { None }
;   ;     }
;   ; }
;   (std.range.next ((Code
;     (Ref 0) Load (Field start) (Method lt)
;     (Ref 0) Load (Field end) (Call 2)
;     (Cases
;       ((True (
;         (Ref 0)
;           (Global std.range)
;           (Ref 0) Load (Field start) (Method add) (Literal 1) (Call 2)
;           (Ref 0) Load (Field end)
;           (Call 2)
;         Store
;         (Global core.Option.Some)
;           (Ref 0) Load (Field start) (Method sub) (Literal 1) (Call 2)
;         (Call 1)))
;       (False ((Global core.Option.None)))))))))))
