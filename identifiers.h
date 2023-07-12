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

    ID_LAST, // `ID` different from all `Id_*`
};

extern const char *identifiers[ID_LAST];
