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

  while (1) {
    reg_gpio_out = 1; // LED on
    delay_ms(1000);

    reg_gpio_out = 0; // LED off
    delay_ms(1000);
  }
}
