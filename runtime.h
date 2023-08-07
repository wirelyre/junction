#include <inttypes.h>
#include <stdarg.h>
#include <stdbool.h>

typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

void dbg(const char *format, ...);
_Noreturn void fail(const char *error, const char *format, ...);



typedef struct Object Object;
typedef Object (*Function)(u32 argc, va_list *);

extern const Object UNIT;
extern const Object FALSE;
extern const Object TRUE;

Object makeref(Object *);
Object incref(Object);
void   decref(Object);

Object bytes_init(const char *); // (C string) -> Bytes
Object num_init  (u64);          // (u64)      -> Num
Object bool_init (bool);         // (C bool)   -> Bool
bool   bool_get  (Object);       // (Bool)     -> C bool

#define method(NAME, ...) _method(NAME, VA_ARGC(__VA_ARGS__), __VA_ARGS__)
Object _method(u32 name, u32 argc, ...); // first vararg is the method receiver
#define VA_ARGC(...) VA_ARGC_(__VA_ARGS__, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
#define VA_ARGC_(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, N, ...) N



struct Object {
    enum {
        KIND_UNIT,
        KIND_FALSE,
        KIND_TRUE,
        KIND_NUM,
        KIND_BYTES,
        KIND_DATA,
        KIND_REF,
        KIND_MODULE,
    } kind;

    union {
        u64 num;
        struct Bytes  *bytes;
        struct Data   *data;
        struct Object *ref;
        const struct Module *module;
    };
};

struct Bytes {
    u32 refcount;
    u32 len; // number of meaningful bytes in `contents`
    u32 cap; // capacity; always 0 or a power of 2
    char contents[];
};

struct Data {
    const struct Module *module;
    u32 refcount;
    u32 tag;
};

struct Module {
    const char *name;
    u32 child_count;
    struct {
        u32 name;
        Function f;
    } children[];
};

extern const struct Module BOOL_MODULE;
extern const struct Module BYTES_MODULE;
extern const struct Module NUM_MODULE;
extern const struct Module UNIT_MODULE;
