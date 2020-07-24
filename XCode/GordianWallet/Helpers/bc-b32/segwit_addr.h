/* Copyright (c) 2017 Pieter Wuille
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#ifndef _SEGWIT_ADDR_H_
#define _SEGWIT_ADDR_H_ 1

#include <stdint.h>

typedef enum bech32_version_t {
    version_bech32,
    version_bech32_bis
} bech32_version;

/** Encode a SegWit address
 *
 *  Out: output:   Pointer to a buffer of size 73 + strlen(hrp) that will be
 *                 updated to contain the null-terminated address.
 *  In:  hrp:      Pointer to the null-terminated human readable part to use
 *                 (chain/network specific).
 *       ver:      Version of the witness program (between 0 and 16 inclusive).
 *       prog:     Data bytes for the witness program (between 2 and 40 bytes).
 *       prog_len: Number of data bytes in prog.
 *       version:  The version of the Bech32 algorithm to use.
 *  Returns 1 if successful.
 */
int segwit_addr_encode(
    char *output,
    const char *hrp,
    int ver,
    const uint8_t *prog,
    size_t prog_len,
    bech32_version version
);

/** Decode a SegWit address
 *
 *  Out: ver:      Pointer to an int that will be updated to contain the witness
 *                 program version (between 0 and 16 inclusive).
 *       prog:     Pointer to a buffer of size 40 that will be updated to
 *                 contain the witness program bytes.
 *       prog_len: Pointer to a size_t that will be updated to contain the length
 *                 of bytes in prog.
 *  In:  hrp:      Pointer to the null-terminated human readable part that is
 *                 expected (chain/network specific).
 *       addr:     Pointer to the null-terminated address.
 *  Returns 1 if successful.
 */
int segwit_addr_decode(
    int* ver,
    uint8_t* prog,
    size_t* prog_len,
    const char* hrp,
    const char* addr,
    bech32_version version
);

/** Encode a Bech32 string
 *
 *  Out: output:  Pointer to a buffer of size strlen(hrp) + data_len + 8 that
 *                will be updated to contain the null-terminated Bech32 string.
 *  In: hrp :     Pointer to the null-terminated human readable part.
 *      data :    Pointer to an array of 5-bit values.
 *      data_len: Length of the data array.
 *  Returns 1 if successful.
 */
int bech32_encode(
    char *output,
    const char *hrp,
    const uint8_t *data,
    size_t data_len,
    bech32_version version
);

/** Decode a Bech32 string
 *
 *  Out: hrp:      Pointer to a buffer of size strlen(input) - 6. Will be
 *                 updated to contain the null-terminated human readable part.
 *       data:     Pointer to a buffer of size strlen(input) - 8 that will
 *                 hold the encoded 5-bit data values.
 *       data_len: Pointer to a size_t that will be updated to be the number
 *                 of entries in data.
 *  In: input:     Pointer to a null-terminated Bech32 string.
 *  Returns 1 if succesful.
 */
int bech32_decode(
    char *hrp,
    uint8_t *data,
    size_t *data_len,
    const char *input,
    bech32_version version
);

/** Encode an arbitrary seed in BC32 format
 *
 *  Out: output:  Pointer to a buffer of size strlen("seed") + data_len + 8 that
 *                will be updated to contain the null-terminated Bech32 string.
 *  In: seed:     Pointer to the seed.
 *      seed_len: Length of the seed, in [1-64].
 *
 * Returns 1 if successful.
 */
int bc32_seed_encode(
    char* output,
    const uint8_t *seed,
    size_t seed_len
);

/** Decode a BC32 seed
 *
 * Out: seed:     Pointer to a buffer of size 64 that will be updated to
 *                contain the see.
 *      seed_len: Pointer to number of bytes in seed.
 * In: input:     Pointer to the null-terminated Bech32 seed string.
 *
 * Returns 1 if successful.
 */
int bc32_seed_decode(
    uint8_t* seed,
    size_t* seed_len,
    const char* input
);

/** Encode an arbitrary byte string in BC32 format
 *
 * In: input:      Pointer to input data.
 *     input_len:  Length of input data.
 *
 * Returns a pointer to a newly allocated string. Caller is response to free it.
 * Returns NULL if unsuccessful.
 */
char* bc32_encode(
    const uint8_t* input,
    size_t input_len
);

/** Decode a BC32-encoded byte string
 *
 * Out: output_len:  Length of the output data.
 * In: input:        The input BC32-encoded string.
 *
 * Returns a pointer to the newly allocated data. Caller is responsible to free it.
 * Returns NULL if unsuccessful (invalid BC32 encoding or checksum).
 */
uint8_t* bc32_decode(
    size_t* output_len,
    const char* input
);

#endif
