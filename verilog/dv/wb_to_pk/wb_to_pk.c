#include <defs.h>
#include <stub.h>

// Valid addresses between USER_SPACE_ADDR and USER_SPACE_ADDR + USER_SPACE_SIZE
#define STATUS (*((volatile uint32_t *) 0x30123000))   // wb addr reg 
#define ADDR    (*((volatile uint32_t *) 0x30123004))   // wb addr reg 
#define WDATA    (*((volatile uint32_t *) 0x30123008))   // wb write data reg
#define WCOUNT    (*((volatile uint32_t *) 0x3012300C))   // wb write count reg
#define RDATA (*((volatile uint32_t *) 0x30123010))   // wb write count reg

  void wait_bridge() {
    while(STATUS != 0); 
  }

void main() {
  //need this for caravel
  reg_mprj_xfer = 1;
  while (reg_mprj_xfer == 1);
  reg_wb_enable = 1;
  
  //pk stream write 2 words
  ADDR    = 0x0000001C;
  WCOUNT    = 0x00000002;
  WDATA    = 0x45520080;

  wait_bridge();

  if (ADDR != 0x0000001C)
    test_fail(); 
  if (WCOUNT != 0x00000002)
    test_fail(); 
  if (WDATA != 0x45520080)
    test_fail(); 

  //pk stream write 4 words
  ADDR    = 0x0000000C;
  WCOUNT    = 0x00000004;
  WDATA    = 0xFAFAFAFA;

  wait_bridge();

  if (ADDR != 0x0000000C)
    test_fail(); 
  if (WCOUNT != 0x00000004)
    test_fail(); 
  if (WDATA != 0xFAFAFAFA)
    test_fail(); 

  //pk stream write 1 word
  ADDR    = 0x00000008;
  WCOUNT    = 0x00000001;
  WDATA    = 0xF18F20FF;

  wait_bridge();

  if (ADDR != 0x00000008)
    test_fail(); 
  if (WCOUNT != 0x00000001)
    test_fail(); 
  if (WDATA != 0xF18F20FF)
    test_fail(); 

  // pk stream write 255 words
  ADDR = 0x00000080;
  WCOUNT = 0x000000E0;
  WDATA = 0x10804070;
  
  wait_bridge();

  if (ADDR != 0x00000080)
    test_fail(); 
  if (WCOUNT != 0x000000E0)
    test_fail(); 
  if (WDATA != 0x10804070)
    test_fail(); 

  //wishbone read (pk read)
  volatile uint32_t readValue;

  uint32_t current_addr = 0x0000000C;

  for (int i = 0; i < 4; i++) {
  
  ADDR = current_addr;
  wait_bridge();
  readValue = RDATA;

  if (ADDR != current_addr)
    test_fail(); 
  if (RDATA != 0xFAFAFAFA)
    test_fail(); 
  if (readValue != 0xFAFAFAFA)
    test_fail(); 

  current_addr += 4;
  }

  //pk read (ensure no overcounting to other memory addresses)
  current_addr = 0x0000001C;

  for (int i = 0; i < 2; i++) {
  
  ADDR = current_addr;
  wait_bridge();
  readValue = RDATA;

  if (ADDR != current_addr)
    test_fail(); 
  if (RDATA != 0x45520080)
    test_fail(); 
  if (readValue != 0x45520080)
    test_fail(); 

  current_addr += 4;
  }

  //wishbone read (pk read) of 255 addresses
  current_addr = 0x00000080;

  for (int i = 0; i < 224; i++) {
  
  ADDR = current_addr;
  wait_bridge();
  readValue = RDATA;

  if (ADDR != current_addr)
    test_fail(); 
  if (RDATA != 0x10804070)
    test_fail(); 
  if (readValue != 0x10804070)
    test_fail(); 

  current_addr += 4;
  }

  test_pass();
}
