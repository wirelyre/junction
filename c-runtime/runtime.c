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

Object obj_make_ref(Object *o)
{
    if (o->kind == KIND_REF) fail("makeref", "called on ref");
    if (o->kind == KIND_MODULE) fail("makeref", "called on module");

    Object ref = {
        .kind = KIND_REF,
        .ref = o,
    };
    return ref;
}

Object obj_make_module(const struct Module *m)
{
    Object mod = {
        .kind = KIND_MODULE,
        .module = m,
    };
    return mod;
}

Object obj_incref(Object o)
{
    switch (o.kind) {
        case KIND_GLOBAL:
        case KIND_NUM:
            break;

        case KIND_REF:
            fail("incref", "called on ref");
        case KIND_MODULE:
            fail("incref", "called on module");

        case KIND_ARRAY:
            o.array->refcount++;
            if (o.array->refcount == 0)
                fail("reference count overflow", "Array");
            break;

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

void obj_decref(Object o)
{
    switch (o.kind) {
        case KIND_GLOBAL:
        case KIND_NUM:
            break;

        case KIND_REF:
            fail("decref", "called on ref");
        case KIND_MODULE:
            fail("decref", "called on module");

        case KIND_ARRAY:
            if (o.array->refcount == 0) fail("decref after free", "Array");
            if (--o.array->refcount == 0) {
                dbg("[free Array: %p]\n", o.array);
                free(o.array);
            }
            break;

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
                for (u16 i = 0; i < o.data->field_count; i++) {
                    obj_decref(o.data->fields[i].value);
                }
                free(o.data);
            }
            break;
    }
}

Object obj_get_field(Object o, u32 name)
{
    switch (o.kind) {
        case KIND_NUM:   fail("no such field", "Num.%s",   identifiers[name]);
        case KIND_ARRAY: fail("no such field", "Array.%s", identifiers[name]);
        case KIND_BYTES: fail("no such field", "Bytes.%s", identifiers[name]);

        case KIND_REF: fail("field access", "called on ref");

        case KIND_GLOBAL:
            for (u16 i = 0; i < o.global->field_count; i++) {
                if (o.global->fields[i].name == name) {
                    // incref on child (future-proofing)
                    // no decref on self (global; unnecessary)
                    return obj_incref(o.global->fields[i].value);
                }
            }
            fail("no such field", "%s.%s", o.global->module->name, identifiers[name]);

        case KIND_DATA:
            for (u16 i = 0; i < o.data->field_count; i++) {
                if (o.data->fields[i].name == name) {
                    Object field = obj_incref(o.data->fields[i].value);
                    obj_decref(o);
                    return field;
                }
            }
            fail("no such field", "%s.%s", o.data->module->name, identifiers[name]);

        case KIND_MODULE:
            for (u32 i = 0; i < o.module->child_count; i++) {
                if (o.module->children[i].name == name) {
                    // no incref on child (global or module)
                    // no decref on self (module)
                    return o.module->children[i].value;
                }
            }
            fail("no such field", "%s.%s", o.module->name, identifiers[name]);
    }
}

u32 obj_get_tag(Object o)
{
    u32 tag;

    switch (o.kind) {
        case KIND_DATA:
            tag = o.data->tag;
            obj_decref(o);
            return tag;

        case KIND_GLOBAL:
            tag = o.global->tag;
            return tag;

        case KIND_ARRAY:  fail("get tag", "called on Array");
        case KIND_BYTES:  fail("get tag", "called on Bytes");
        case KIND_NUM:    fail("get tag", "called on Num");
        case KIND_MODULE: fail("get tag", "called on module");
        case KIND_REF:    fail("get tag", "called on ref");
    }
}

Object obj_alloc_data(const struct Module *m, u32 tag, u16 len)
{
    Object new = {
        .kind = KIND_DATA,
        .data = malloc(sizeof(struct Data) + len * sizeof(struct Field)),
    };
    new.data->module = m;
    new.data->refcount = 1;
    new.data->tag = tag;
    new.data->field_count = len;

    dbg("[alloc %s: %p]\n", m->name, new.data);

    return new;
}

Object _call(Object f, u32 argc, ...)
{
    assert(f.kind == KIND_MODULE);
    assert(f.module->function != NULL);

    va_list args;

    va_start(args, argc);
    Object ret = f.module->function(argc, &args);
    va_end(args);

    return ret;
}

static Function get_method(Object o, u32 name)
{
    if (o.kind == KIND_REF)
        o = *o.ref;

    const struct Module *module;

    switch (o.kind) {
        case KIND_GLOBAL: module = o.global->module; break;
        case KIND_NUM:    module = &NUM_MODULE;      break;
        case KIND_ARRAY:  module = &ARRAY_MODULE;    break;
        case KIND_BYTES:  module = &BYTES_MODULE;    break;
        case KIND_DATA:   module = o.data->module;   break;

        case KIND_REF:    fail("method lookup", "called on ref to ref");
        case KIND_MODULE: fail("method lookup", "called on module");
    }

    for (u32 i = 0; i < module->child_count; i++) {
        if (module->children[i].name == name) {
            dbg("[method %s.%s]\n", module->name, identifiers[name]);
            Object child = module->children[i].value;

            if (child.kind != KIND_MODULE || child.module->function == NULL)
                fail("not callable", "%s.%s", module->name, identifiers[name]);

            return child.module->function;
        }
    }

    fail("no such method", "%s.%s", module->name, identifiers[name]);
}

Object _method(u32 name, u32 argc, ...)
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

Object arg_data(va_list *l, const struct Module *m)
{
    Object o = va_arg(*l, Object);
    switch (o.kind) {
        case KIND_DATA:
            if (o.data->module != m)
                fail("argument", "expected %s, found %s", m->name, o.data->module->name);
            return o;

        case KIND_GLOBAL:
            if (o.global->module != m)
                fail("argument", "expected %s, found %s", m->name, o.global->module->name);
            return o;

        case KIND_ARRAY:  fail("argument", "expected %s, found Array",  m->name);
        case KIND_BYTES:  fail("argument", "expected %s, found Bytes",  m->name);
        case KIND_NUM:    fail("argument", "expected %s, found Num",    m->name);
        case KIND_MODULE: fail("argument", "expected %s, found module", m->name);
        case KIND_REF:    fail("argument", "expected %s, found ref",    m->name);
    }
}

Object arg_kind(va_list *l, u8 kind)
{
    Object o = va_arg(*l, Object);
    assert(o.kind == kind);
    return o;
}

Object arg_ref_kind(va_list *l, u8 kind)
{
    Object o = va_arg(*l, Object);
    assert(o.kind == KIND_REF && o.ref->kind == kind);
    return o;
}

Object arg_val(va_list *l)
{
    Object o = va_arg(*l, Object);
    assert(o.kind != KIND_REF && o.kind != KIND_MODULE);
    return o;
}
