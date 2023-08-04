#define IDENTIFIERS \
    T(Bool)   \
    T(True)   \
    T(False)  \
              \
    T(Bytes)  \
    T(append) \
    T(print)  \
              \
    T(Number) \
    T(sub)    \
    T(mul)    \
    T(gt)     \
    T(fmt)    \

enum Identifiers {
    #define T(i) Id_##i,
    IDENTIFIERS
    #undef T

    ID_COUNT, // `ID` different from all `Id_*`
};

extern const char *identifiers[ID_COUNT];
