#include "runtime.h"
#include "identifiers.h"

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

void dbg(const char *format, ...)
{
    #ifdef DEBUG
        fprintf(stderr, "\033[2m");

        va_list args;
        va_start(args, format);
        vfprintf(stderr, format, args);
        va_end(args);

        fprintf(stderr, "\033[0m");
    #endif
}

_Noreturn void fail(const char *error, const char *format, ...)
{
    fprintf(stderr, "\033[0;m");
    fprintf(stderr, "\033[1;m\033[5;31m%s:\033[0;m ", error);

    va_list args;
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);

    fprintf(stderr, "\n");
    exit(1);
}

const Object UNIT  = { .kind = KIND_UNIT  };
const Object FALSE = { .kind = KIND_FALSE };
const Object TRUE  = { .kind = KIND_TRUE  };

Object makeref(Object *o)
{
    if (o->kind == KIND_REF) fail("makeref", "called on ref");
    if (o->kind == KIND_MODULE) fail("makeref", "called on module");

    Object ref = {
        .kind = KIND_REF,
        .ref = o,
    };
    return ref;
}

Object incref(Object o)
{
    switch (o.kind) {
        case KIND_UNIT:
        case KIND_FALSE:
        case KIND_TRUE:
        case KIND_NUM:
            break;

        case KIND_REF:
            fail("incref", "called on ref");
        case KIND_MODULE:
            fail("incref", "called on module");

        case KIND_BYTES:
            o.bytes->refcount++;
            if (o.bytes->refcount == 0)
                fail("reference count overflow", "Bytes");
            break;

        case KIND_DATA:
            o.data->refcount++;
            if (o.bytes->refcount == 0)
                fail("reference count overflow", "%s", o.data->module->name);
            break;
    }
    return o;
}

void decref(Object o)
{
    switch (o.kind) {
        case KIND_UNIT:
        case KIND_FALSE:
        case KIND_TRUE:
        case KIND_NUM:
            break;

        case KIND_REF:
            fail("decref", "called on ref");
        case KIND_MODULE:
            fail("decref", "called on module");

        case KIND_BYTES:
            if (o.bytes->refcount == 0) fail("decref after free", "Bytes");
            if (--o.bytes->refcount == 0) {
                dbg("[free Bytes: %p]\n", o.bytes);
                free(o.bytes);
            }
            break;

        case KIND_DATA:
            if (o.data->refcount == 0) fail("decref after free", "%s", o.data->module->name);
            if (--o.data->refcount == 0) {
                dbg("[free %s: %p]\n", o.data->module->name, o.data);
                free(o.data);
            }
            break;
    }
}

static Function get_method(Object o, u32 name)
{
    if (o.kind == KIND_REF)
        o = *o.ref;

    const struct Module *module;

    switch (o.kind) {
        case KIND_UNIT:  module = &UNIT_MODULE;   break;
        case KIND_FALSE: module = &BOOL_MODULE;   break;
        case KIND_TRUE:  module = &BOOL_MODULE;   break;
        case KIND_NUM:   module = &NUM_MODULE;    break;
        case KIND_BYTES: module = &BYTES_MODULE;  break;
        case KIND_DATA:  module = o.data->module; break;

        case KIND_REF:    fail("method lookup", "called on ref to ref");
        case KIND_MODULE: fail("method lookup", "called on module");
    }

    for (u32 i = 0; i < module->child_count; i++) {
        if (module->children[i].name == name) {
            dbg("[method %s.%s]\n", module->name, identifiers[name]);
            return module->children[i].f;
        }
    }

    fail("no such method", "%s.%s", module->name, identifiers[name]);
}

Object method(u32 name, u32 argc, ...)
{
    va_list args;

    assert(argc >= 1);
    va_start(args, argc);
    Object receiver = va_arg(args, Object);
    va_end(args);

    va_start(args, argc);
    Object ret = get_method(receiver, name)(argc, &args);
    va_end(args);

    return ret;
}

const struct Module UNIT_MODULE = {
    .name = "Unit",
    .child_count = 0,
    .children = {},
};
