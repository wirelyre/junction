#include "runtime.h"
#include "identifiers.h"

void print(Object o)
{
    Object b = obj_make_bytes("");
    method(Id_fmt, o, obj_make_ref(&b));
    method(Id_print, b);
}

int main(int argc, char *argv[])
{
    // object model: values are pointers to heap allocations
    // they are immutable (conceptually)
    // they have reference counts to keep track of when to free them
    Object b1 = obj_make_bytes("Hello, wo"); // b1: Bytes
    Object b2 = obj_make_bytes("rld!\n");    // b2: Bytes

    // a `Bytes *` takes ownership; increment the refcount to keep your own copy
    // a `Bytes **` doesn't; it's like a mutable pointer to immutable data
    method(Id_append, obj_make_ref(&b1), b2); // gives away `b2`
    method(Id_print, b1);                // gives away `b1`
    // now `b1` and `b2` must not be used (in fact, they have been freed)

    b1 = obj_make_bytes("hello ");
    b2 = obj_incref(b1);
    // `b1` and `b2` are basically different objects now
    // they will only be modified as an optimization if the refcount is 1

    method(Id_append, obj_make_ref(&b1), obj_incref(b2)); // `b1` and `b2` are kept
    method(Id_append, obj_make_ref(&b1), obj_incref(b2)); // still kept
    method(Id_append, obj_make_ref(&b1), b2); // `b2` is gone

    method(Id_print, obj_incref(b1)); // `b1` is kept
    method(Id_print, b1); // `b1` is gone

    method(Id_print, obj_make_bytes("\n")); // value is allocated and freed (no leak)



    // calculate 10 factorial

    Object n = obj_make_num(1);  // n: Num
    Object i = obj_make_num(10); // i: Num
    while (obj_get_bool(method(Id_gt, obj_incref(i), obj_make_num(0)))) {
        n = method(Id_mul, n, obj_incref(i));
        i = method(Id_sub, i, obj_make_num(1));
    }
    obj_decref(i);

    Object b = obj_make_bytes("10! = "); // b: Bytes
    method(Id_fmt, n, obj_make_ref(&b));
    method(Id_append, obj_make_ref(&b), obj_make_bytes("\n"));
    method(Id_print, b);



    // find maximum of list

    // This is not the proper way to initialize an array (it's not type safe),
    // but it will give an error below if it's not fully initialized, which is
    // a useful check for this implementation right now.
    Object arr = obj_make_array(5, UNIT); // arr: Array[Unit]
    Object arr2 = obj_incref(arr);        // arr2: Array[Unit]
    method(Id_set, obj_make_ref(&arr), obj_make_num(0), obj_make_num(3));
    method(Id_set, obj_make_ref(&arr), obj_make_num(1), obj_make_num(1));
    method(Id_set, obj_make_ref(&arr), obj_make_num(2), obj_make_num(2));
    method(Id_set, obj_make_ref(&arr), obj_make_num(3), obj_make_num(9));
    method(Id_set, obj_make_ref(&arr), obj_make_num(4), obj_make_num(3));
    // now arr: Array[Num]

    Object max = obj_make_num(0);
    i = obj_make_num(5);
    while(obj_get_bool(method(Id_gt, obj_incref(i), obj_make_num(0)))) {
        i = method(Id_sub, i, obj_make_num(1));
        n = method(Id_get, obj_incref(arr), obj_incref(i));

        if (obj_get_bool(method(Id_gt, obj_incref(n), obj_incref(max)))) {
            obj_decref(max);
            max = n;
        } else {
            obj_decref(n);
        }
    }
    obj_decref(i);
    obj_decref(arr);
    obj_decref(arr2);

    b = obj_make_bytes("max[3, 1, 2, 9, 3] = ");
    method(Id_fmt, max, obj_make_ref(&b));
    method(Id_append, obj_make_ref(&b), obj_make_bytes("\n"));
    method(Id_print, b);



    Object Option = obj_make_module(&OPTION_MODULE);
    Object Option__None = obj_get_field(Option, Id_None);
    Object Option__Some = obj_get_field(Option, Id_Some);

    Object my_option = call(Option__Some, obj_make_num(5));
    Object my_option2 = call(Option__Some, obj_make_num(6));

    // print(my_option | my_option2)
    Object result = method(Id_or, obj_incref(my_option), obj_incref(my_option2));
    print(obj_get_field(result, Id_inner)); // 5

    /*
        print(my_option->unwrap())
        print(my_option2->unwrap_or(7))
        print(None->unwrap_or(7))
    */
    print(method(Id_unwrap, obj_incref(my_option))); // 5
    print(method(Id_unwrap_or, obj_incref(my_option2), obj_make_num(7))); // 6
    print(method(Id_unwrap_or, Option__None, obj_make_num(7)));           // 7

    Object nested = call(Option__Some, obj_incref(my_option));

    obj_decref(nested);
    obj_decref(my_option);
    obj_decref(my_option2);

    method(Id_print, obj_make_bytes("\n"));

    return 0;
}
