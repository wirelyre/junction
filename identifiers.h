#define IDENTIFIERS \
    T(Array)  \
    T(get)    \
    T(set)    \
              \
    T(Bool)   \
    T(True)   \
    T(False)  \
              \
    T(Bytes)  \
    T(append) \
    T(print)  \
              \
    T(Number) \
    T(add)    \
    T(sub)    \
    T(mul)    \
    T(div)    \
    T(not)    \
    T(and)    \
    T(or)     \
    T(xor)    \
    T(gt)     \
    T(fmt)    \
              \
    T(Unit)

enum Identifiers {
    #define T(i) Id_##i,
    IDENTIFIERS
    #undef T

    ID_COUNT, // `ID` different from all `Id_*`
};

extern const char *identifiers[ID_COUNT];
