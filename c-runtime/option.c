#include "runtime.h"
#include "identifiers.h"

#include <assert.h>

/*
    type Option[T](None | Some(inner: T))

    impl Option[T] {
        fn or(self, other: Option[T]): Option[T]
        fn unwrap(self): T
        fn unwrap_or(self, other: T): T
    }
*/

const struct Module OPTION_MODULE;

static const struct Data option_none = {
    .module = &OPTION_MODULE,
    .refcount = 1,
    .tag = Id_None,
};

FN(option_some, "Option.Some")
{
    assert(argc == 1);
    Object inner = arg_val(args);

    Object new = obj_alloc_data(&OPTION_MODULE, Id_Some, 1);
    new.data->fields[0].name = Id_inner;
    new.data->fields[0].value = inner;

    return new;
}

/*
    fn or(self, other: Self): Self {
        case self {
            None => other
            Some => self
        }
    }
*/
FN(option_or, "or")
{
    assert(argc == 2);
    Object self = arg_data(args, &OPTION_MODULE);
    Object other = arg_data(args, &OPTION_MODULE);

    if (obj_get_tag(obj_incref(self)) == Id_None) {
        obj_decref(self);
        return other;
    } else {
        obj_decref(other);
        return self;
    }
}

/*
    fn unwrap(self): T {
        case self {
            None => panic()
            Some => self.inner
        }
    }
*/
FN(option_unwrap, "unwrap")
{
    assert(argc == 1);
    Object self = arg_data(args, &OPTION_MODULE);

    assert(obj_get_tag(obj_incref(self)) == Id_Some);
    return obj_get_field(self, Id_inner);
}

/*
    fn unwrap_or(self, other: T): T {
        case self {
            None => other
            Some => self.inner
        }
    }
*/
FN(option_unwrap_or, "unwrap_or")
{
    assert(argc == 2);
    Object self = arg_data(args, &OPTION_MODULE);
    Object other = arg_val(args);

    if (obj_get_tag(obj_incref(self)) == Id_None) {
        obj_decref(self);
        return other;
    } else {
        obj_decref(other);
        return obj_get_field(self, Id_inner);
    }
}

const struct Module OPTION_MODULE = {
    .name = "Option",
    .child_count = 5,
    .children = {
        { .name = Id_None, .value = GLOBAL_OBJ(option_none) },
        { .name = Id_Some, .value = FN_OBJ(option_some) },

        { .name = Id_or,        .value = FN_OBJ(option_or)        },
        { .name = Id_unwrap,    .value = FN_OBJ(option_unwrap)    },
        { .name = Id_unwrap_or, .value = FN_OBJ(option_unwrap_or) },
    },
};
