#include "runtime.h"
#include "identifiers.h"

int main(int argc, char *argv[])
{
    // object model: values are pointers to heap allocations
    // they are immutable (conceptually)
    // they have reference counts to keep track of when to free them
    Object b1 = bytes_init("Hello, wo"); // b1: Bytes
    Object b2 = bytes_init("rld!\n");    // b2: Bytes

    // a `Bytes *` takes ownership; increment the refcount to keep your own copy
    // a `Bytes **` doesn't; it's like a mutable pointer to immutable data
    method(Id_append, 2, makeref(&b1), b2); // gives away `b2`
    method(Id_print, 1, b1);                // gives away `b1`
    // now `b1` and `b2` must not be used (in fact, they have been freed)

    b1 = bytes_init("hello ");
    b2 = incref(b1);
    // `b1` and `b2` are basically different objects now
    // they will only be modified as an optimization if the refcount is 1

    method(Id_append, 2, makeref(&b1), incref(b2)); // `b1` and `b2` are kept
    method(Id_append, 2, makeref(&b1), incref(b2)); // still kept
    method(Id_append, 2, makeref(&b1), b2); // `b2` is gone

    method(Id_print, 1, incref(b1)); // `b1` is kept
    method(Id_print, 1, b1); // `b1` is gone

    method(Id_print, 1, bytes_init("\n")); // value is allocated and freed (no leak)



    // calculate 10 factorial

    Object n = num_init(1);  // n: Num
    Object i = num_init(10); // i: Num
    while (bool_get(method(Id_gt, 2, incref(i), num_init(0)))) {
        n = method(Id_mul, 2, n, incref(i));
        i = method(Id_sub, 2, i, num_init(1));
    }
    decref(i);

    Object b = bytes_init("10! = "); // b: Bytes
    method(Id_fmt, 2, n, makeref(&b));
    method(Id_append, 2, makeref(&b), bytes_init("\n"));
    method(Id_print, 1, b);

    return 0;
}
