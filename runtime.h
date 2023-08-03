#include <inttypes.h>
#include <stdarg.h>
#include <stdbool.h>

typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef struct TypeInfo TypeInfo;

typedef struct Value {
    TypeInfo *info;
    u32 refcount;

    union {
        struct {
            u32 len; // number of meaningful bytes in `contents`
            u32 cap; // capacity; always 0 or a power of 2
            char contents[];
        } bytes;

        u64 num;

        struct {
            u32 tag;
        } data;
    };
} Value;

typedef Value *(*Method)(Value **self, va_list *);

struct TypeInfo {
    const char *name;
    u32 method_count;
    struct {
        u32 name;
        Method m;
    } methods[];
};

Value *value_alloc(TypeInfo *, u32 size);
Value *incref(Value *);
void   decref(Value *);

Value *method_v(Value *self, u32 name, ...);  // (self, ...) -> ?
Value *method_r(Value **self, u32 name, ...); // (^self, ...) -> ?

Value *bytes_init(const char *); // (C string) -> Bytes
Value *num_init  (u64);          // (u64)      -> Num

bool   bool_get  (Value *);      // (Bool)     -> C bool
extern Value TRUE;
extern Value FALSE;
