/**
 * @file procedures.c
 * @author Michael Drobot (mdrobot7@iastate.edu)
 * @brief Software divide and modulo procedures and test code (Linux C).
 * Used to initially develop and test the procedures implemented in
 * procedures.s. Should NOT be compiled in Caravel, used only to show the
 * higher-level functionality of the procedures and for future reference.
 * @version 1.0
 * @date 2025-11-29
 */

#include <limits.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

// Test points of interest
#define NUM_TESTS (13)
const uint32_t utests[] = {0, 1, 2, 9, 10, 1000, 1000000, 1000000000, 0x7FFFFFFF, 0x80000000, 0xAF013F8B, 0xFFFFFFFE, 0xFFFFFFFF};
const int32_t itests[] = {0, 1, 2, 9, 10, 1000, 1000000, 1000000000, 0x7FFFFFFF, 0x80000000, 0xAF013F8B, 0xFFFFFFFE, 0xFFFFFFFF};

// abs(), but returning an unsigned int
#define UABS(x) (x < 0 ? (uint32_t)(~x + 1) : x)

#define DECIMAL_POS (10)
#define FLOAT_TO_FIXED(n) ((int32_t)((float)(n) * (1 << DECIMAL_POS)))
#define FIXED_TO_FLOAT(n) ((float)(n) / (1 << DECIMAL_POS))
#define EPSILON (0.005f)
#define FLOAT_EQUAL(a, b) (fabsf((a) - (b)) < EPSILON)
const int32_t fixedtests[] = {FLOAT_TO_FIXED(0), FLOAT_TO_FIXED(1), FLOAT_TO_FIXED(2), FLOAT_TO_FIXED(9), FLOAT_TO_FIXED(10), FLOAT_TO_FIXED(1000), FLOAT_TO_FIXED(1000000), FLOAT_TO_FIXED(2097151), FLOAT_TO_FIXED(-2097152), FLOAT_TO_FIXED(-221947.123), FLOAT_TO_FIXED(-123457), FLOAT_TO_FIXED(-2), FLOAT_TO_FIXED(-1)};

/**
 * These div/mod procedures run on the following rules:
 * - n / 0 = 0
 * - n / d = 0 when n < d
 * - If we pass both of the checks above, the following
 *   must be true:
 * - You must be able to fit d into n at least 1 time.
 * - You can't fit d into n more than n times.
 * - Mods return a negative number only if the dividend is negative.
 *
 * You need to find the number of times d fits into n.
 * You could repeatedly run (n - d) until you can't anymore,
 * count the number of iterations and get your quotient.
 * This is slow. Instead, we want to take chunks out
 * of n. Ideally, as large of a chunk as possible. In long
 * division you do this with powers of 10, here it's more
 * convenient to do it with powers of 2.
 *
 * Notable quirks of C division using 32-bit ints:
 * - abs(INT_MIN) is undefined
 * - INT_MIN / -1 returns INT_MIN, *not* -INT_MIN, because -INT_MIN is
 *   out of int32_t range. But only **sometimes**.
 *   - onlinegdb returns INT_MIN
 *   - gdb (MSYS) returns INT_MIN
 *   - MSYS UCRT runtime returns SIGFPE and locks up
 *   - As far as I can tell this is undefined behavior. We'll return
 *     -INT_MIN for the purposes of these algorithms.
 *   - This applies to fixed point as well: FIXED_MIN / -1 will
 *     return FIXED_MIN under this policy.
 * - INT_MIN % -1 returns 0, as expected, but MSYS UCRT throws
 *   SIGFPE instead of returning correctly. Onlinegdb throws
 *   a warning. We'll use 0 as the correct output here.
 * - Int division by 0 will sometimes return 0 on embedded
 *   systems, but it's platform-dependent. On a Linux system
 *   it throws SIGFPE.
 */

void div_loop(uint32_t *q, uint32_t *rem, uint32_t n, uint32_t d)
{
  *q = 0;
  int32_t shift = 31;
  while (shift >= 0 && n != 0)
  {
    // Check that we don't overflow our 32-bit comparison
    // AND whether or not we can fit our denominator into our numerator.
    if (n - (d << shift) <= n && (d << shift) >> shift == d)
    {
      n = n - (d << shift);
      *q = *q | (1 << shift);
    }
    shift = shift - 1;
  }
  *rem = n;
}

uint32_t div_uint(uint32_t n, uint32_t d)
{
  uint32_t ret;
  if (n == 0 || d == 0 || n < d)
  {
    ret = 0;
  }
  else if (d == 1)
  {
    ret = n;
  }
  else if (n == d)
  {
    ret = 1;
  }
  else
  {
    uint32_t q, rem;
    div_loop(&q, &rem, n, d);
    ret = q;
  }
  return ret;
}

int32_t div_int(int32_t n, int32_t d)
{
  int32_t ret;
  ret = div_uint(UABS(n), UABS(d));
  if ((n & 0x80000000) != (d & 0x80000000))
  {
    ret = -ret;
  }
  return ret;
}

int32_t div_fixed(int32_t n, int32_t d)
{
  return div_int(n, d >> DECIMAL_POS);
}

uint32_t mod_uint(uint32_t n, uint32_t d)
{
  uint32_t ret;
  if (n == 0 || d == 0 || d == 1)
  {
    ret = 0;
  }
  else
  {
    uint32_t q, rem;
    div_loop(&q, &rem, n, d);
    ret = rem;
  }
  return ret;
}

int32_t mod_int(int32_t n, int32_t d)
{
  int32_t ret;
  ret = mod_uint(UABS(n), UABS(d));
  if (n < 0)
  {
    ret = -ret;
  }
  return ret;
}

int32_t mod_fixed(int32_t n, int32_t d)
{
  return mod_int(n, d);
}

// -------------------------------------------------------------------------------------- //

int test_udiv()
{
  for (int i = 0; i < NUM_TESTS; i++)
  {
    for (int j = 0; j < NUM_TESTS; j++)
    {
      uint32_t i32 = (uint32_t)utests[i];
      uint32_t j32 = (uint32_t)utests[j];

      uint32_t quotient = div_uint(i32, j32);
      if (j32 == 0)
      {
        // Special case: div operator doesn't handle div by 0
        if (quotient != 0)
        {
          printf("FAIL: %u / %u => %u, expected 0\n", i32, j32, quotient);
          return 1;
        }
        continue;
      }

      if (quotient != (i32 / j32))
      {
        printf("FAIL: %u / %u => %u, expected %d\n", i32, j32, quotient, (i32 / j32));
        printf("FAIL: 0x%x / 0x%x => 0x%x, expected 0x%x\n", i32, j32, quotient, (i32 / j32));
        return 1;
      }
    }
  }
  printf("udiv: SUCCESS\n");
  return 0;
}

int test_idiv()
{
  for (int i = 0; i < NUM_TESTS; i++)
  {
    for (int j = 0; j < NUM_TESTS; j++)
    {
      int32_t i32 = (int32_t)itests[i];
      int32_t j32 = (int32_t)itests[j];

      int32_t quotient = div_int(i32, j32);
      if (j32 == 0)
      {
        // Special case: div operator doesn't handle div by 0
        if (quotient != 0)
        {
          printf("FAIL: %d / %d => %d, expected 0\n", i32, j32, quotient);
          return 1;
        }
        continue;
      }
      if (i32 == INT32_MIN && j32 == -1)
      {
        // Special case: MSYS can't handle INT_MIN / -1
        if (quotient != INT32_MIN)
        {
          printf("FAIL: %d / %d => %d, expected %d\n", i32, j32, quotient, INT32_MIN);
          return 1;
        }
        continue;
      }

      if (quotient != (i32 / j32))
      {
        printf("FAIL: %d / %d => %d, expected %d\n", i32, j32, quotient, (i32 / j32));
        printf("FAIL: 0x%x / 0x%x => 0x%x, expected 0x%x\n", i32, j32, quotient, (i32 / j32));
        return 1;
      }
    }
  }
  printf("idiv: SUCCESS\n");
  return 0;
}

int test_fixeddiv()
{
  for (int i = 0; i < NUM_TESTS; i++)
  {
    for (int j = 0; j < NUM_TESTS; j++)
    {
      int32_t i32 = (int32_t)fixedtests[i];
      int32_t j32 = (int32_t)fixedtests[j];

      int32_t quotient = div_fixed(i32, j32);
      if (j32 == 0)
      {
        // Special case: div operator doesn't handle div by 0
        if (quotient != 0)
        {
          printf("FAIL: %d / %d => %d, expected 0\n", i32, j32, quotient);
          return 1;
        }
        continue;
      }
      if (i32 == FLOAT_TO_FIXED(-2097152) && j32 == FLOAT_TO_FIXED(-1))
      {
        // Special case: INT_MIN / -1 = INT_MIN, floats don't understand this.
        if (quotient != FLOAT_TO_FIXED(-2097152))
        {
          printf("FAIL: %f / %f => %f, expected %f\n", FIXED_TO_FLOAT(i32), FIXED_TO_FLOAT(j32), FIXED_TO_FLOAT(quotient), -2097152.0f);
          return 1;
        }
        continue;
      }

      float expected = FIXED_TO_FLOAT(i32) / FIXED_TO_FLOAT(j32);
      if (!FLOAT_EQUAL(FIXED_TO_FLOAT(quotient), expected))
      {
        printf("FAIL: %f / %f => %f, expected %f\n", FIXED_TO_FLOAT(i32), FIXED_TO_FLOAT(j32), FIXED_TO_FLOAT(quotient), expected);
        printf("FAIL: 0x%x / 0x%x => 0x%x, expected 0x%x\n", i32, j32, quotient, (i32 / j32));
        return 1;
      }
    }
  }
  printf("fixeddiv: SUCCESS\n");
  return 0;
}

int test_umod()
{
  for (int i = 0; i < NUM_TESTS; i++)
  {
    for (int j = 0; j < NUM_TESTS; j++)
    {
      uint32_t i32 = (uint32_t)utests[i];
      uint32_t j32 = (uint32_t)utests[j];

      uint32_t quotient = mod_uint(i32, j32);
      if (j32 == 0)
      {
        // Special case: div operator doesn't handle div by 0
        if (quotient != 0)
        {
          printf("FAIL: %u %% %u => %u, expected 0\n", i32, j32, quotient);
          return 1;
        }
        continue;
      }

      if (quotient != (i32 % j32))
      {
        printf("FAIL: %u %% %u => %u, expected %d\n", i32, j32, quotient, (i32 % j32));
        printf("FAIL: 0x%x %% 0x%x => 0x%x, expected 0x%x\n", i32, j32, quotient, (i32 % j32));
        return 1;
      }
    }
  }
  printf("umod: SUCCESS\n");
  return 0;
}

int test_imod()
{
  for (int i = 0; i < NUM_TESTS; i++)
  {
    for (int j = 0; j < NUM_TESTS; j++)
    {
      int32_t i32 = (int32_t)itests[i];
      int32_t j32 = (int32_t)itests[j];

      int32_t quotient = mod_int(i32, j32);
      if (j32 == 0 || (i32 == INT32_MIN && j32 == -1))
      {
        // Special case: div operator doesn't handle div by 0
        // Special case: MSYS can't handle INT_MIN % -1
        if (quotient != 0)
        {
          printf("FAIL: %d %% %d => %d, expected 0\n", i32, j32, quotient);
          return 1;
        }
        continue;
      }

      if (quotient != (i32 % j32))
      {
        printf("FAIL: %d %% %d => %d, expected %d\n", i32, j32, quotient, (i32 % j32));
        printf("FAIL: 0x%x %% 0x%x => 0x%x, expected 0x%x\n", i32, j32, quotient, (i32 % j32));
        return 1;
      }
    }
  }
  printf("imod: SUCCESS\n");
  return 0;
}

int test_fixedmod()
{
  for (int i = 0; i < NUM_TESTS; i++)
  {
    for (int j = 0; j < NUM_TESTS; j++)
    {
      int32_t i32 = (int32_t)fixedtests[i];
      int32_t j32 = (int32_t)fixedtests[j];

      int32_t quotient = mod_fixed(i32, j32);
      if (j32 == 0 || (i32 == INT32_MIN && j32 == -1))
      {
        // Special case: div operator doesn't handle div by 0
        // Special case: INT_MIN / -1 = INT_MIN, floats don't understand this.
        if (quotient != 0)
        {
          printf("FAIL: %d %% %d => %d, expected 0\n", i32, j32, quotient);
          return 1;
        }
        continue;
      }

      float expected = fmod(FIXED_TO_FLOAT(i32), FIXED_TO_FLOAT(j32));
      if (!FLOAT_EQUAL(FIXED_TO_FLOAT(quotient), expected))
      {
        printf("FAIL: %f %% %f => %f, expected %f\n", FIXED_TO_FLOAT(i32), FIXED_TO_FLOAT(j32), FIXED_TO_FLOAT(quotient), expected);
        printf("FAIL: 0x%x %% 0x%x => 0x%x, expected 0x%x\n", i32, j32, quotient, (i32 % j32));
        return 1;
      }
    }
  }
  printf("fixedmod: SUCCESS\n");
  return 0;
}

int main()
{
  if (test_udiv())
  {
    return 1;
  }
  if (test_idiv())
  {
    return 1;
  }
  if (test_fixeddiv())
  {
    return 1;
  }
  if (test_umod())
  {
    return 1;
  }
  if (test_imod())
  {
    return 1;
  }
  if (test_fixedmod())
  {
    return 1;
  }


  // Hacky thing to generate a binary results file to compare against the core sim
  FILE * f = fopen("./test_procedure_results.bin", "wb");
  uint32_t zero = 0;

  fwrite(utests, NUM_TESTS, 4, f); // 0x00
  fwrite(&zero, 1, 4, f);// Pad
  fwrite(&zero, 1, 4, f);// Pad
  fwrite(&zero, 1, 4, f);// Pad
  fwrite(itests, NUM_TESTS, 4, f); // 0x40
  fwrite(&zero, 1, 4, f);// Pad
  fwrite(&zero, 1, 4, f);// Pad
  fwrite(&zero, 1, 4, f);// Pad
  fwrite(fixedtests, NUM_TESTS, 4, f); // 0x80
  fwrite(&zero, 1, 4, f);// Pad
  fwrite(&zero, 1, 4, f);// Pad
  fwrite(&zero, 1, 4, f);// Pad

  for (int i = 0; i < (0x2404 - 0xC0) / 4; i++) {
    fwrite(&zero, 1, 4, f);// Result space, stack space
  }

  fseek(f, 0x400, SEEK_SET);
  for(int i = 0; i < NUM_TESTS; i++) {
      for(int j = 0; j < NUM_TESTS; j++) {
        uint32_t val = div_uint(utests[i], utests[j]);
        fwrite(&val, 1, 4, f);
      }
  }
  fseek(f, 0x800, SEEK_SET);
  for(int i = 0; i < NUM_TESTS; i++) {
      for(int j = 0; j < NUM_TESTS; j++) {
        int32_t val = div_int(itests[i], itests[j]);
        fwrite(&val, 1, 4, f);
      }
  }
  fseek(f, 0xC00, SEEK_SET);
  for(int i = 0; i < NUM_TESTS; i++) {
      for(int j = 0; j < NUM_TESTS; j++) {
        int32_t val = div_fixed((int32_t)fixedtests[i], (int32_t)fixedtests[j]);
        fwrite(&val, 1, 4, f);
      }
  }
  fseek(f, 0x1000, SEEK_SET);
  for(int i = 0; i < NUM_TESTS; i++) {
      for(int j = 0; j < NUM_TESTS; j++) {
        uint32_t val = mod_uint(utests[i], utests[j]);
        fwrite(&val, 1, 4, f);
      }
  }
  fseek(f, 0x1400, SEEK_SET);
  for(int i = 0; i < NUM_TESTS; i++) {
      for(int j = 0; j < NUM_TESTS; j++) {
        int32_t val = mod_int(itests[i], itests[j]);
        fwrite(&val, 1, 4, f);
      }
  }
  fseek(f, 0x1800, SEEK_SET);
  for(int i = 0; i < NUM_TESTS; i++) {
      for(int j = 0; j < NUM_TESTS; j++) {
        int32_t val = mod_fixed(fixedtests[i], fixedtests[j]);
        fwrite(&val, 1, 4, f);
      }
  }
  fclose(f);

  return 0;
}
