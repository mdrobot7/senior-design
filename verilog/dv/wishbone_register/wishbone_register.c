#include <defs.h>
#include <stub.h>

// Valid addresses between USER_SPACE_ADDR and USER_SPACE_ADDR + USER_SPACE_SIZE
#define REG0    (*((volatile uint32_t *) 0x30123400))   // Normal
#define REG1    (*((volatile uint32_t *) 0x30123500))   // Write mask
#define REG2    (*((volatile uint32_t *) 0x30123600))   // Read mask
#define REG3    (*((volatile uint32_t *) 0x30123700))   // W1C
#define REG4    (*((volatile uint32_t *) 0x30123800))   // W1S
#define REG5    (*((volatile uint32_t *) 0x30123900))   // W1T
#define REG6(x) (((volatile uint32_t *) 0x30123A00)[x]) // Multi-word: has 4 32-bit entries
#define REG7    (*((volatile uint32_t *) 0x30123B00))   // Read from peripheral
#define REG8    (*((volatile uint32_t *) 0x30123C00))   // Enable-protection

void main() {
  reg_mprj_xfer = 1;
  while (reg_mprj_xfer == 1);

  reg_wb_enable = 1;

  if (REG0 != 0x01010101)
    test_fail();
  if (REG1 != 0x01010101)
    test_fail();
  if (REG2 != 0x00000101)
    test_fail();
  if (REG3 != 0x01010101)
    test_fail();
  if (REG4 != 0x01010101)
    test_fail();
  if (REG5 != 0x01010101)
    test_fail();
  if (REG6(0) != 0x01010101
      || REG6(1) != 0x10101010
      || REG6(2) != 0x02020202
      || REG6(3) != 0x03030303)
    test_fail();
  if (REG7 != 0x01010101)
    test_fail();
  if (REG8 != 0x01010101)
    test_fail();

  REG0    = 0x12345678;
  REG1    = 0x12345678;
  REG2    = 0x12345678;
  REG3    = 0x10100101;
  REG4    = 0x10100101;
  REG5    = 0x10100101;
  REG6(0) = 0x12345678;
  REG6(1) = 0x12345678;
  REG6(2) = 0x12345678;
  REG6(3) = 0x12345678;
  REG7    = 0x12345678;
  REG8    = 0x12344571; // Leave enabled

  if (REG0 != 0x12345678)
    test_fail();
  if (REG1 != 0x12340101) // Only write the top 2 bytes
    test_fail();
  if (REG2 != 0x00005678) // Only read the bottom 2 bytes
    test_fail();
  if (REG3 != 0x01010000)
    test_fail();
  if (REG4 != 0x11110101)
    test_fail();
  if (REG5 != 0x11110000)
    test_fail();
  if (REG6(0) != 0x12345678
      || REG6(1) != 0x12345678
      || REG6(2) != 0x12345678
      || REG6(3) != 0x12345678)
    test_fail();
  if (REG7 != 0x01010101)
    test_fail();
  if (REG8 != 0x01010101)
    test_fail();

  REG8 = 0x55555550;
  if (REG8 != 0x01010100)
    test_fail();
  REG8 = 0x55555550;
  if (REG8 != 0x55555550)
    test_fail();
  test_pass();
}
