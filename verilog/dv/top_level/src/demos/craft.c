#include "demos.h"
#include "ugpu.h"

#include "models/craft.h"

#define VERTEX_BUFFER_PK_ADDR (QSPI2_MEM_ADDR_DEFAULT + 0x080000)
#define INDEX_BUFFER_PK_ADDR  (QSPI2_MEM_ADDR_DEFAULT + 0x180000)
#define TEX_BUFFER_PK_ADDR    (QSPI2_MEM_ADDR_DEFAULT + 0x280000)

static void craft_setup() {
    ugpu_wb_pk_memcpy(TEX_BUFFER_PK_ADDR, (uint32_t *) crafting_table_t, CRAFTING_TABLE_SIZE_X * CRAFTING_TABLE_SIZE_Y / 4);

    RAST->TEXADDR.reg   = TEX_BUFFER_PK_ADDR;
    RAST->TEXWIDTH.reg  = CRAFTING_TABLE_SIZE_X;
    RAST->TEXHEIGHT.reg = CRAFTING_TABLE_SIZE_Y;
    RAST->DEPTHADDR.reg = DEPTH_PK_ADDR;
    RAST->USERCOUNT.reg = 3;

    ugpu_wb_pk_memcpy(VERTEX_BUFFER_PK_ADDR, (uint32_t *) crafting_table_vertices, (CRAFTING_TABLE_VERTICES * sizeof(vertex_t)) / 4);
    ugpu_wb_pk_memcpy(INDEX_BUFFER_PK_ADDR, (uint32_t *) crafting_table_triangles, (CRAFTING_TABLE_TRIANGLES * sizeof(triangle_t)) / 4);
}

static void craft_loop() {
    // Flip upside down -> spin around -> move up/down and back -> view -> persp -> screen
    // One period of the up/down sinusoid takes half a rotation
    mat4_t mvp;
    mat4_t rot;
    mat4_t trans;
    mat4_t persp;
    mat4_t screen;

    mat4_perspective(persp, UGPU_FIXED_DIV(UGPU_FIXED(320), UGPU_FIXED(240)), UGPU_FIXED_MUL(UGPU_FIXED(90), UGPU_PI_180), UGPU_FIXED(1) / 16, UGPU_FIXED(10));
    mat4_screen(screen, 320, 240);

    mat4_t screen_persp;
    mat4_identity(screen_persp);
    mat4_mul(screen_persp, screen);
    mat4_mul(screen_persp, persp);

    int swap = 0;
    ugpu_fp_t y_pos = UGPU_FIXED(-2);
    ugpu_fp_t y_step = UGPU_FLOAT_TO_FIXED(0.1);
    ugpu_fp_t angle = 0;

    mat4_trans(trans, 0, y_pos, UGPU_FIXED(-4));
    mat4_rotate(rot, 0, angle, 0);

    mat4_muld(mvp, screen_persp, trans);
    mat4_mul(mvp, rot);

    CC->GR[41].reg = UGPU_FLOAT_TO_FIXED(0.577);
    CC->GR[42].reg = UGPU_FLOAT_TO_FIXED(0.577);
    CC->GR[43].reg = UGPU_FLOAT_TO_FIXED(0.577);

    while (1) {
        demo_clear_buffers_start(swap ? FB1_PK_ADDR : FB0_PK_ADDR);

        demo_clear_buffers_end();

        demo_draw_buffer_normal_start(
            VERTEX_BUFFER_PK_ADDR,
            INDEX_BUFFER_PK_ADDR,
            swap ? FB1_PK_ADDR : FB0_PK_ADDR,
            CRAFTING_TABLE_TRIANGLES,
            mvp,
            rot
        );

        y_pos += UGPU_FLOAT_TO_FIXED(0.2);
        if (y_pos >= UGPU_2_PI) {
          y_pos = 0;
        }

        angle += UGPU_FLOAT_TO_FIXED(0.1);
        if (angle >= UGPU_2_PI) {
          angle = 0;
        }

        mat4_trans(trans, 0, sin_fp(y_pos) - UGPU_FLOAT_TO_FIXED(0.75), UGPU_FIXED(-4));
        mat4_rotate(rot, 0, angle, 0);

        mat4_muld(mvp, screen_persp, trans);
        mat4_mul(mvp, rot);

        demo_draw_buffer_sync();

        if (swap) VGA->FBADDR.reg = FB1_PK_ADDR;
        else VGA->FBADDR.reg = FB0_PK_ADDR;

        while (!VGA->CTRL.bit.INVBLANK);

        swap = !swap;
    }
}

void craft() {
    craft_setup();
    ugpu_shader_copy(CC_IMEM, vertex_shader, vertex_shader_len);
    ugpu_shader_copy(&CC_IMEM[64], fragment_shader, fragment_shader_len);
    CC->VSHADEPC.reg = 0;
    CC->FSHADEPC.reg = 256;

    craft_loop();
}

void craft_shadows() {
    craft_setup();
    ugpu_shader_copy(CC_IMEM, vertex_shader, vertex_shader_len);
    ugpu_shader_copy(&CC_IMEM[64], fragment_shader_phong, fragment_shader_phong_len);
    CC->VSHADEPC.reg = 0;
    CC->FSHADEPC.reg = 256;

    craft_loop();
}
