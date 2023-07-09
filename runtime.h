#include <inttypes.h>

typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef struct Bytes Bytes;

Bytes *bytes_init  (const char *);
Bytes *bytes_incref(Bytes *);
void   bytes_decref(Bytes *);

void   bytes_print (Bytes *);
void   bytes_append(Bytes **, Bytes *);
