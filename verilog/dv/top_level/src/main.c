#include "demos/demos.h"
#include "init/init.h"
#include "ugpu.h"

#include <defs.h>
#include <stdint.h>
#include <stub.h>

void main() {
  init();
  demos_init();
  duwe_cube();

  delay_ms(50);

  reg_gpio_out = 1; // LED on
}
