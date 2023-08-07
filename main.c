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
    method(Id_append, makeref(&b1), b2); // gives away `b2`
    method(Id_print, b1);                // gives away `b1`
    // now `b1` and `b2` must not be used (in fact, they have been freed)

    b1 = bytes_init("hello ");
    b2 = incref(b1);
    // `b1` and `b2` are basically different objects now
    // they will only be modified as an optimization if the refcount is 1

    method(Id_append, makeref(&b1), incref(b2)); // `b1` and `b2` are kept
    method(Id_append, makeref(&b1), incref(b2)); // still kept
    method(Id_append, makeref(&b1), b2); // `b2` is gone

    method(Id_print, incref(b1)); // `b1` is kept
    method(Id_print, b1); // `b1` is gone

    method(Id_print, bytes_init("\n")); // value is allocated and freed (no leak)



    // calculate 10 factorial

    Object n = num_init(1);  // n: Num
    Object i = num_init(10); // i: Num
    while (bool_get(method(Id_gt, incref(i), num_init(0)))) {
        n = method(Id_mul, n, incref(i));
        i = method(Id_sub, i, num_init(1));
    }
    decref(i);

    Object b = bytes_init("10! = "); // b: Bytes
    method(Id_fmt, n, makeref(&b));
    method(Id_append, makeref(&b), bytes_init("\n"));
    method(Id_print, b);



    // find maximum of list

    // This is not the proper way to initialize an array (it's not type safe),
    // but it will give an error below if it's not fully initialized, which is
    // a useful check for this implementation right now.
    Object arr = array_init(5, UNIT); // arr: Array[Unit]
    Object arr2 = incref(arr);        // arr2: Array[Unit]
    method(Id_set, makeref(&arr), num_init(0), num_init(3));
    method(Id_set, makeref(&arr), num_init(1), num_init(1));
    method(Id_set, makeref(&arr), num_init(2), num_init(2));
    method(Id_set, makeref(&arr), num_init(3), num_init(9));
    method(Id_set, makeref(&arr), num_init(4), num_init(3));
    // now arr: Array[Num]

    Object max = num_init(0);
    i = num_init(5);
    while(bool_get(method(Id_gt, incref(i), num_init(0)))) {
        i = method(Id_sub, i, num_init(1));
        n = method(Id_get, incref(arr), incref(i));

        if (bool_get(method(Id_gt, incref(n), incref(max)))) {
            decref(max);
            max = n;
        } else {
            decref(n);
        }
    }
    decref(i);
    decref(arr);
    decref(arr2);

    b = bytes_init("max[3, 1, 2, 9, 3] = ");
    method(Id_fmt, max, makeref(&b));
    method(Id_append, makeref(&b), bytes_init("\n"));
    method(Id_print, b);

    return 0;
}
