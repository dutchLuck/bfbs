/*
 * M P F R _ W R A P P E R . C
 *
 * mpfr_wrapper.c last edited on Wed Mar 18 14:41:34 2026
 *
 * Wrapper function for MPFR library to be used in Swift.
 * This file is compiled as C code and linked with the Swift code.
 * It supports Arbitrary Precision Basic Statistics for one or
 * more files of one or more CSV columns of data.
 */

#include "mpfr.h"
#include <stdio.h>
#include <stdlib.h>

char* mpfr_to_string(mpfr_t val, int digits) {

    // allocate buffer (safe upper bound)
    size_t size = digits + 32;

    char* buffer = (char*)malloc(size);

    if (!buffer) return NULL;

    mpfr_snprintf(buffer, size, "%.*Rg", digits, val);
    /* mpfr_snprintf(buffer, size, "%.*Rf", digits, val); */

    return buffer;
}

