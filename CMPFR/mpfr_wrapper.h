#ifndef MPFR_WRAPPER_H
#define MPFR_WRAPPER_H

#include "mpfr.h"

#ifdef __cplusplus
extern "C" {
#endif

char* mpfr_to_string(mpfr_t val, int digits);

#ifdef __cplusplus
}
#endif

#endif
