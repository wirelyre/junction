#include <inttypes.h>
#include <stdarg.h>
#include <stdbool.h>

typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef struct VTable VTable;

typedef struct Value {
    VTable *vtable;
    u32 refcount;
    u32 tag;
} Value;

typedef Value *(*Method)(Value **self, va_list *);

struct VTable {
    u32 entry_count;
    struct {
        u32 name;
        Method m;
    } entries[];
};

Value *value_alloc(VTable *, u32 tag);
Value *incref(Value *);
void   decref(Value *);

Value *method_v(Value *self, u32 name, ...);  // (self, ...) -> ?
Value *method_r(Value **self, u32 name, ...); // (^self, ...) -> ?

Value *bool_init (bool);         // (C bool)   -> Bool
Value *bytes_init(const char *); // (C string) -> Bytes
Value *num_init  (u64);          // (u64)      -> Num
bool   bool_get  (Value *);      // (Bool)     -> C bool
