#include <defs.h>
#include <stub.h>

// Valid addresses between USER_SPACE_ADDR and USER_SPACE_ADDR + USER_SPACE_SIZE
#define ADDR    (*((volatile uint32_t *) 0x30123400))   // wb addr reg 
#define WDATA    (*((volatile uint32_t *) 0x30123800))   // wb write data reg
#define WCOUNT    (*((volatile uint32_t *) 0x30123C00))   // wb write count reg


void main() {
  //need this for caravel
  reg_mprj_xfer = 1;
  while (reg_mprj_xfer == 1);
  reg_wb_enable = 1;
  

  ADDR    = 0x12345678;
  WCOUNT    = 0x00000004;
  WDATA    = 0xFAFAFAFA;


  ADDR = 0x10804070;
  WCOUNT = 0x000000FF;
  WDATA = 0xFFFFFFFF;
  
  ADDR = 0xFFFFFFFF;

  volatile uint32_t readValue;

  readValue = WDATA;


  for (volatile int i = 0; i < 10 ; i++){

  }

  // if (REG0 != 0x01010101)
  //   test_fail();
  // if (REG1 != 0x01010101)
  //   test_fail();
  // if (REG2 != 0x00000101)
  //   test_fail();
  // if (REG3 != 0x01010101)
  //   test_fail();
  // if (REG4 != 0x01010101)
  //   test_fail();
  // if (REG5 != 0x01010101)
  //   test_fail();
  // if (REG6(0) != 0x01010101
  //     || REG6(1) != 0x10101010
  //     || REG6(2) != 0x02020202
  //     || REG6(3) != 0x03030303)
  //   test_fail();
  // if (REG7 != 0x01010101)
  //   test_fail();
  // if (REG8 != 0x01010101)
  //   test_fail();

  // REG0    = 0x12345678;
  // REG1    = 0x12345678;
  // REG2    = 0x12345678;
  // REG3    = 0x10100101;
  // REG4    = 0x10100101;
  // REG5    = 0x10100101;
  // REG6(0) = 0x12345678;
  // REG6(1) = 0x12345678;
  // REG6(2) = 0x12345678;
  // REG6(3) = 0x12345678;
  // REG7    = 0x12345678;
  // REG8    = 0x12344571; // Leave enabled

  // if (REG0 != 0x12345678)
  //   test_fail();
  // if (REG1 != 0x12340101) // Only write the top 2 bytes
  //   test_fail();
  // if (REG2 != 0x00005678) // Only read the bottom 2 bytes
  //   test_fail();
  // if (REG3 != 0x01010000)
  //   test_fail();
  // if (REG4 != 0x11110101)
  //   test_fail();
  // if (REG5 != 0x11110000)
  //   test_fail();
  // if (REG6(0) != 0x12345678
  //     || REG6(1) != 0x12345678
  //     || REG6(2) != 0x12345678
  //     || REG6(3) != 0x12345678)
  //   test_fail();
  // if (REG7 != 0x01010101)
  //   test_fail();
  // if (REG8 != 0x01010101)
  //   test_fail();

  // REG8 = 0x55555550;
  // if (REG8 != 0x01010100)
  //   test_fail();
  // REG8 = 0x55555550;
  // if (REG8 != 0x55555550)
  //   test_fail();
  test_pass();
}
