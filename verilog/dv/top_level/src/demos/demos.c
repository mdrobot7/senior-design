#include "demos.h"

uint32_t * vertex_shader;
uint32_t vertex_shader_len;
uint32_t * fragment_shader;
uint32_t fragment_shader_len;

void demos_init() {
  vertex_shader       = &_svertex_shader;
  vertex_shader_len   = (uint32_t) (&_evertex_shader - &_svertex_shader);
  fragment_shader     = &_sfragment_shader;
  fragment_shader_len = (uint32_t) (&_efragment_shader - &_sfragment_shader);
}
