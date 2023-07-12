#include "runtime.h"
#include "identifiers.h"

int main(int argc, char *argv[])
{
    // object model: values are pointers to heap allocations
    // they are immutable (conceptually)
    // they have reference counts to keep track of when to free them
    Value *b1 = bytes_init("Hello, wo"); // b1: Bytes
    Value *b2 = bytes_init("rld!\n");    // b2: Bytes

    // a `Bytes *` takes ownership; increment the refcount to keep your own copy
    // a `Bytes **` doesn't; it's like a mutable pointer to immutable data
    method_r(&b1, Id_append, b2); // gives away `b2`
    method_v(b1, Id_print);       // gives away `b1`
    // now `b1` and `b2` must not be used (in fact, they have been freed)

    b1 = bytes_init("hello ");
    b2 = incref(b1);
    // `b1` and `b2` are basically different objects now
    // they will only be modified as an optimization if the refcount is 1

    method_r(&b1, Id_append, incref(b2)); // `b1` and `b2` are kept
    method_r(&b1, Id_append, incref(b2)); // still kept
    method_r(&b1, Id_append, b2); // `b2` is gone

    method_v(incref(b1), Id_print); // `b1` is kept
    method_v(b1, Id_print); // `b1` is gone

    method_v(bytes_init("\n"), Id_print); // value is allocated and freed (no leak)



    // calculate 10 factorial

    Value *n = num_init(1);  // n: Num
    Value *i = num_init(10); // i: Num
    while (bool_get(method_v(incref(i), Id_gt, num_init(0)))) {
        n = method_v(n, Id_mul, incref(i));
        i = method_v(i, Id_sub, num_init(1));
    }
    decref(i);

    Value *b = bytes_init("10! = "); // b: Bytes
    method_v(n, Id_fmt, &b);
    method_r(&b, Id_append, bytes_init("\n"));
    method_v(b, Id_print);

    return 0;
}
