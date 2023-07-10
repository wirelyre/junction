#include "runtime.h"

#include <assert.h>
#include <stdlib.h>

// Reference-counted bool.

enum BoolTag {
    // right now, this shouldn't rely on TAG_False == 0 and TAG_True != 0
    // it might later because that seems like a good idea
    TAG_False = 1,
    TAG_True = 2,
};

struct Bool {
    u32 refcount;
    enum BoolTag tag;
};

Bool *bool_init(bool b)
{
    Bool *new = malloc(sizeof(Bool));
    new->refcount = 1;
    new->tag = b ? TAG_True : TAG_False;
    return new;
}

Bool *bool_incref(Bool *b)
{
    b->refcount++;
    return b;
}

void bool_decref(Bool *b)
{
    b->refcount--;
    if (b->refcount == 0)
        free(b);
}



bool bool_get(Bool *b)
{
    assert(b->tag == TAG_True || b->tag == TAG_False);
    bool res = b->tag == TAG_True;
    bool_decref(b);
    return res;
}
