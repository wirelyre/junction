#include "identifiers.h"

const char *identifiers[] = {
    #define T(i) #i,
    IDENTIFIERS
    #undef T
};
