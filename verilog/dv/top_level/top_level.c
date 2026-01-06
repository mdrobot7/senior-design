#include <defs.h>
#include <stub.h>
#include <ugpu.h>

// Shader assembly regions in flash
extern uint32_t _svertex_shader;
extern uint32_t _evertex_shader;

void main()
{
  reg_mprj_xfer = 1;
  while (reg_mprj_xfer == 1)
  {
  }

  reg_wb_enable = 1;
}
