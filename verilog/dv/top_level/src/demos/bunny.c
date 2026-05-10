#include "demos.h"
#include "ugpu.h"
#include <stdint.h>

#include "models/bunny.h"

#define VERTEX_BUFFER_PK_ADDR (QSPI2_MEM_ADDR_DEFAULT + 0x080000)
#define INDEX_BUFFER_PK_ADDR  (QSPI2_MEM_ADDR_DEFAULT + 0x1C0000)
#define TEX_BUFFER_PK_ADDR    (QSPI2_MEM_ADDR_DEFAULT + 0x280000)

static void bunny_setup() {
    // Textures are broken on this model
    static const uint32_t tex = 0xFFFFFFFF;
    ugpu_wb_pk_memcpy(TEX_BUFFER_PK_ADDR, &tex, 1);

    RAST->TEXADDR.reg   = TEX_BUFFER_PK_ADDR;
    RAST->TEXWIDTH.reg  = 1;
    RAST->TEXHEIGHT.reg = 1;
    RAST->DEPTHADDR.reg = DEPTH_PK_ADDR;
    RAST->USERCOUNT.reg = 3;

    ugpu_wb_pk_memcpy(VERTEX_BUFFER_PK_ADDR, (uint32_t *) bunny_vertices, (BUNNY_VERTICES * sizeof(vertex_t)) / 4);
    ugpu_wb_pk_memcpy(INDEX_BUFFER_PK_ADDR, (uint32_t *) bunny_triangles, (BUNNY_TRIANGLES * sizeof(triangle_t)) / 4);
}

static void bunny_loop() {
    mat4_t mvp;

    mat4_t rot;

    mat4_t trans;
    mat4_trans(trans, 0, UGPU_FLOAT_TO_FIXED(10), UGPU_FLOAT_TO_FIXED(-20));

    mat4_t flip;
    mat4_rotated(flip, 0, 0, UGPU_FIXED(180));

    mat4_t persp;
    mat4_perspective(persp, UGPU_FIXED_DIV(UGPU_FIXED(320), UGPU_FIXED(240)), UGPU_FIXED_MUL(UGPU_FIXED(90), UGPU_PI_180), UGPU_FIXED(1) / 16, UGPU_FIXED(10));

    mat4_t screen;
    mat4_screen(screen, 320, 240);

    mat4_t post_rot;
    mat4_identity(post_rot);
    mat4_mul(post_rot, screen);
    mat4_mul(post_rot, persp);
    mat4_mul(post_rot, trans);

    int model_angle = 5;

    int swap = 0;

    mat4_rotated(rot, 0, 0, 0);

    mat4_muld(mvp, post_rot, rot);
    mat4_mul(mvp, flip);

    // Light source normal vector
    CC->GR[41].reg = UGPU_FLOAT_TO_FIXED(0.707);
    CC->GR[42].reg = UGPU_FLOAT_TO_FIXED(0);
    CC->GR[43].reg = UGPU_FLOAT_TO_FIXED(0.707);

    while (1) {
        demo_clear_buffers_start(swap ? FB1_PK_ADDR : FB0_PK_ADDR);

        demo_clear_buffers_end();

        demo_draw_buffer_normal_start(
            VERTEX_BUFFER_PK_ADDR,
            INDEX_BUFFER_PK_ADDR,
            swap ? FB1_PK_ADDR : FB0_PK_ADDR,
            BUNNY_TRIANGLES,
            mvp,
            rot
        );

        if (model_angle < 350) model_angle += 10;
        else model_angle = 0;

        mat4_rotated(rot, 0, UGPU_FIXED(model_angle), 0);
        mat4_muld(mvp, post_rot, rot);
        mat4_mul(mvp, flip);

        demo_draw_buffer_sync();

        if (swap) VGA->FBADDR.reg = FB1_PK_ADDR;
        else VGA->FBADDR.reg = FB0_PK_ADDR;

        while (!VGA->CTRL.bit.INVBLANK);

        swap = !swap;
    }
}


void bunny() {
    bunny_setup();
    ugpu_shader_copy(CC_IMEM, vertex_shader, vertex_shader_len);
    ugpu_shader_copy(&CC_IMEM[64], fragment_shader, fragment_shader_len);
    CC->VSHADEPC.reg = 0;
    CC->FSHADEPC.reg = 256;

    bunny_loop();
}

void bunny_shadows() {
    bunny_setup();
    ugpu_shader_copy(CC_IMEM, vertex_shader, vertex_shader_len);
    ugpu_shader_copy(&CC_IMEM[64], fragment_shader_phong, fragment_shader_phong_len);
    CC->VSHADEPC.reg = 0;
    CC->FSHADEPC.reg = 256;

    bunny_loop();
}
