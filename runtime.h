#include <inttypes.h>
#include <stdbool.h>

typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef struct Bool Bool;

Bool *bool_init  (bool);
Bool *bool_incref(Bool *);
void  bool_decref(Bool *);

bool bool_get(Bool *);

typedef struct Bytes Bytes;

Bytes *bytes_init  (const char *);
Bytes *bytes_incref(Bytes *);
void   bytes_decref(Bytes *);

void   bytes_print (Bytes *);
void   bytes_append(Bytes **, Bytes *);

typedef struct Num Num;

Num *num_init  (u64);
Num *num_incref(Num *);
void num_decref(Num *);

Num  *num_sub(Num *, Num *);
Num  *num_mul(Num *, Num *);
Bool *num_gt (Num *, Num *);
void  num_fmt(Num *, Bytes **);
