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
  
  //pk stream write 4 words
  ADDR    = 0x0000000F;
  WCOUNT    = 0x00000004;
  WDATA    = 0xFAFAFAFA;

  wait_bridge();

  if (ADDR != 0x0000000F)
    test_fail(); 
  if (WCOUNT != 0x00000004)
    test_fail(); 
  if (WDATA != 0xFAFAFAFA)
    test_fail(); 

  // pk stream write 255 words
  ADDR = 0x00000080;
  WCOUNT = 0x000000FF;
  WDATA = 0x10804070;
  
  wait_bridge();

  if (ADDR != 0x00000080)
    test_fail(); 
  if (WCOUNT != 0x000000FF)
    test_fail(); 
  if (WDATA != 0x10804070)
    test_fail(); 

  //wishbone read (pk read)
  ADDR = 0x0000000F;
  volatile uint32_t readValue;
  readValue = RDATA;

  wait_bridge();

  if (ADDR != 0x0000000F)
    test_fail(); 
  if (RDATA != 0xFAFAFAFA)
    test_fail(); 

  //wishbone read (pk read)
  ADDR = 0x00000080;
  readValue = RDATA;

  wait_bridge();

  if (ADDR != 0x00000080)
    test_fail(); 
  if (RDATA != 0x10804070)
    test_fail(); 


  // //pk stream write 0 words
  // ADDR    = 0x000001F0;
  // WCOUNT    = 0x00000000;
  // WDATA    = 0x400500FF;

  // wait_bridge();

  // if (ADDR != 0x000001F0)
  //   test_fail(); 
  // if (WCOUNT != 0x00000000)
  //   test_fail(); 
  // if (WDATA != 0x400500FF)
  //   test_fail(); 

  // //wishbone read (pk read)
  // ADDR = 0x000001F0;
  // readValue = RDATA;

  // wait_bridge();

  // if (ADDR != 0x000001F0)
  //   test_fail(); 
  // if (RDATA != 0x00000000)
  //   test_fail(); 


  test_pass();
}
