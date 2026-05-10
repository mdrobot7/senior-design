#include "demos/demos.h"
#include "init/init.h"
#include "ugpu.h"

#include <defs.h>
#include <stdint.h>
#include <stub.h>

void main() {
  init();
  demos_init();

  // rtl_demo();
  // duwe_cube();
  // bunny();
  // bunny_shadows();
  // cheburashka();
  // cheburashka_shadows();
  // cow();
  // cow_shadows();
  craft();
  // craft_shadows();
  // dingus();
  // dingus_shadows();
  // duwe();
  // duwe_shadows();
  // earth();
  // earth_shadows();
  // suzanne();
  // suzanne_shadows();
  // teapot();
  // teapot_shadows();
  // truck();
  // truck_shadows();

  reg_gpio_out = 1; // LED on
  while (1) {}
}
