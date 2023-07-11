#include <inttypes.h>
#include <stdbool.h>

typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef struct Value {
    u32 refcount;
    u32 tag;
} Value;

Value *value_alloc(u32 tag);
Value *incref(Value *);
void   decref(Value *);

Value *bool_init (bool);         // (C bool)   -> Bool
Value *bytes_init(const char *); // (C string) -> Bytes
Value *num_init  (u64);          // (u64)      -> Num
bool   bool_get  (Value *);      // (Bool)     -> C bool

void   bytes_append(Value **, Value *); // (&Bytes, Bytes)
void   bytes_print (Value *);           // (Bytes)
Value *num_sub     (Value *, Value *);  // (Num, Num) -> Num
Value *num_mul     (Value *, Value *);  // (Num, Num) -> Num
Value *num_gt      (Value *, Value *);  // (Num, Num) -> Bool
void   num_fmt     (Value *, Value **); // (Num, &Bytes)
