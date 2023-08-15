#include <inttypes.h>
#include <stdarg.h>
#include <stdbool.h>

typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

void dbg(const char *format, ...);
_Noreturn void fail(const char *error, const char *format, ...);



typedef struct Object {
    // Any object --- anything that can have a name in source code:
    //   - Values (things which can be stored in variables)
    //   - References (created upon entering a function)
    //   - Modules (non-values accessible from the global namespace)
    // These share a type in C to make things a little more fool-proof.

    enum {
        // Heap-allocated values
        KIND_ARRAY,  // fixed-size array of values
        KIND_BYTES,  // flexible-size byte sequence
        KIND_DATA,   // generalized struct / enum with optional fields

        // Non-heap-allocated values
        KIND_GLOBAL, // globally constant data
        KIND_NUM,    // 64-bit unsigned integer

        // Non-values
        KIND_MODULE, // objects and functions in the global namespace
        KIND_REF,    // reference to a variable in a higher stack frame
    } kind;

    union {
        u64 num;
        struct Array  *array;
        struct Bytes  *bytes;
        struct Data   *data;
        struct Object *ref;
        const struct Data   *global;
        const struct Module *module;
    };
} Object;

// The calling convention for functions starts with an argument count.
// All parameters must be `Object`.
typedef Object (*Function)(u32 argc, va_list *);



// Manipulate the reference count of a value.
//   - Must only be called on values.
//   - Need not be called on globals and nums.
//   - Automatically frees the value when the reference count is 0.
Object obj_incref(Object);   // Returns the supplied object
void   obj_decref(Object);

// Make various kinds of values.
Object obj_make_array(u16 len, Object el); // `Array` of `len` copies of `el`
Object obj_make_bool (bool);               // `Bool` values; global
Object obj_make_bytes(const char *);       // `Bytes` from a C string
Object obj_make_num  (u64);                // `Num` from C u64

// Make non-values
Object obj_make_module(const struct Module *);
Object obj_make_ref   (Object *);

// Allocate and partially initialize data.
// Everything except the data fields (names and values) is initialized.
Object obj_alloc_data(const struct Module *, u32 tag, u16 len);

bool   obj_get_bool (Object);              // Extract a C bool from a `Bool`
Object obj_get_field(Object, u32 name);    // Only callable on data and modules
u32    obj_get_tag  (Object);              // Only callable on data



// The value `{}`.
extern const Object UNIT;



// Call function `F`.
// Automatically counts the arguments.
#define call(F, ...) _call(F, VA_ARGC(__VA_ARGS__), __VA_ARGS__)
Object _call(Object f, u32 argc, ...);

// Call method `NAME` with the first argument as receiver.
// The receiver must be a value or a reference.
// Automatically counts the arguments.
#define method(NAME, ...) _method(NAME, VA_ARGC(__VA_ARGS__), __VA_ARGS__)
Object _method(u32 name, u32 argc, ...);

#define VA_ARGC(...) VA_ARGC_(__VA_ARGS__, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0)
#define VA_ARGC_(_1, _2, _3, _4, _5, _6, _7, _8, _9, _10, N, ...) N



// Defining modules

// Define a C function and wrap it in a module.
#define FN(fn_name, id)                    \
    static Object fn_name(u32, va_list *); \
    static struct Module mod_##fn_name = { \
        .name = id,                        \
        .function = fn_name,               \
        .child_count = 0,                  \
    };                                     \
    static Object fn_name(u32 argc, va_list *args)

// Reference a function / module as a child of a module.
#define FN_OBJ(fn_name) { .kind = KIND_MODULE, .module = &mod_##fn_name }

// Reference global data as a child of a module.
#define GLOBAL_OBJ(name) { .kind = KIND_GLOBAL, .global = &name }

// Retrieve an argument from varargs, asserting its type or kind.
Object arg_data    (va_list *, const struct Module *);
Object arg_kind    (va_list *, u8);
Object arg_ref_kind(va_list *, u8);
Object arg_val     (va_list *);



// Object representations

struct Array {
    u32 refcount;
    u16 len;
    Object contents[];
};

struct Bytes {
    u32 refcount;
    u32 len; // number of meaningful bytes in `contents`
    u32 cap; // capacity; always 0 or a power of 2
    char contents[];
};

struct Field {
    u32 name;
    Object value;
};

struct Data {
    const struct Module *module;
    u32 refcount;
    u32 tag;
    u16 field_count;
    struct Field fields[];
};

struct Module {
    const char *name;
    Function function;
    u32 child_count;
    struct Field children[]; // only KIND_MODULE and KIND_GLOBAL allowed
};



// Well-known modules.

extern const struct Module ARRAY_MODULE;
extern const struct Module BYTES_MODULE;
extern const struct Module NUM_MODULE;
extern const struct Module OPTION_MODULE;
