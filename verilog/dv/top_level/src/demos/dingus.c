#include "demos.h"
#include "ugpu.h"

#include "models/dingus.h"

#define VERTEX_BUFFER_PK_ADDR (QSPI2_MEM_ADDR_DEFAULT + 0x080000)
#define INDEX_BUFFER_PK_ADDR  (QSPI2_MEM_ADDR_DEFAULT + 0x180000)
#define TEX_BUFFER_PK_ADDR    (QSPI2_MEM_ADDR_DEFAULT + 0x280000)

static void dingus_setup() {
    ugpu_wb_pk_memcpy(TEX_BUFFER_PK_ADDR, (uint32_t *) max_t, MAX_SIZE_X * MAX_SIZE_Y / 4);

    RAST->TEXADDR.reg   = TEX_BUFFER_PK_ADDR;
    RAST->TEXWIDTH.reg  = MAX_SIZE_X;
    RAST->TEXHEIGHT.reg = MAX_SIZE_Y;
    RAST->DEPTHADDR.reg = DEPTH_PK_ADDR;
    RAST->USERCOUNT.reg = 3;

    ugpu_wb_pk_memcpy(VERTEX_BUFFER_PK_ADDR, (uint32_t *) max_vertices, (MAX_VERTICES * sizeof(vertex_t)) / 4);
    ugpu_wb_pk_memcpy(INDEX_BUFFER_PK_ADDR, (uint32_t *) max_triangles, (MAX_TRIANGLES * sizeof(triangle_t)) / 4);
}

static void dingus_loop() {
    mat4_t mvp;

    mat4_t rot;

    mat4_t trans;
    mat4_trans(trans, 0, UGPU_FIXED(-10), UGPU_FIXED(-30));

    mat4_t persp;
    mat4_perspective(persp, UGPU_FIXED_DIV(UGPU_FIXED(320), UGPU_FIXED(240)), UGPU_FIXED_MUL(UGPU_FIXED(90), UGPU_PI_180), UGPU_FIXED(1) / 1024, UGPU_FIXED(10));

    mat4_t screen;
    mat4_screen(screen, 320, 240);

    mat4_t post_rot;
    mat4_identity(post_rot);
    mat4_mul(post_rot, screen);
    mat4_mul(post_rot, persp);
    mat4_mul(post_rot, trans);

    int x = 5;
    int y = 5;
    int z = 5;
    int a = 90;

    int swap = 0;

    mat4_rotated(rot, 0, 0, 0);

    mat4_muld(mvp, post_rot, rot);

    CC->GR[41].reg = cos_fp(UGPU_FIXED_MUL(UGPU_FIXED(a), UGPU_PI_180));
    CC->GR[42].reg = UGPU_FLOAT_TO_FIXED(-0.707);
    CC->GR[43].reg = sin_fp(UGPU_FIXED_MUL(UGPU_FIXED(a), UGPU_PI_180));

    while (1) {
        demo_clear_buffers_start(swap ? FB1_PK_ADDR : FB0_PK_ADDR);

        demo_clear_buffers_end();

        demo_draw_buffer_normal_start(
            VERTEX_BUFFER_PK_ADDR,
            INDEX_BUFFER_PK_ADDR,
            swap ? FB1_PK_ADDR : FB0_PK_ADDR,
            MAX_TRIANGLES,
            mvp,
            rot
        );

        const int INC = 30;

        if (x < 360 - INC) x += INC;
        else {
            x = 0;
            if (y < 360 - INC) y += INC;
            else {
                y = 0;
                if (z < 360 - INC) z += INC;
                else {
                    z = 0;
                }
            }
        }

        const int ROT = 10;

        mat4_rotated(rot, 0, UGPU_FIXED(x), 0);
        mat4_muld(mvp, post_rot, rot);

        demo_draw_buffer_sync();

        CC->GR[41].reg = UGPU_FIXED_MUL(
            56756,
            cos_fp(UGPU_FIXED_MUL(UGPU_FIXED(a), UGPU_PI_180))
        );
        CC->GR[42].reg = UGPU_FLOAT_TO_FIXED(-0.5);
        CC->GR[43].reg = UGPU_FIXED_MUL(
            56756,
            sin_fp(UGPU_FIXED_MUL(UGPU_FIXED(a), UGPU_PI_180))
        );

        if (swap) VGA->FBADDR.reg = FB1_PK_ADDR;
        else VGA->FBADDR.reg = FB0_PK_ADDR;

        while (!VGA->CTRL.bit.INVBLANK);

        swap = !swap;
    }
}

void dingus() {
    dingus_setup();
    ugpu_shader_copy(CC_IMEM, vertex_shader, vertex_shader_len);
    ugpu_shader_copy(&CC_IMEM[64], fragment_shader, fragment_shader_len);
    CC->VSHADEPC.reg = 0;
    CC->FSHADEPC.reg = 256;

    dingus_loop();
}
void dingus_shadows() {
    dingus_setup();
    ugpu_shader_copy(CC_IMEM, vertex_shader, vertex_shader_len);
    ugpu_shader_copy(&CC_IMEM[64], fragment_shader_phong, fragment_shader_phong_len);
    CC->VSHADEPC.reg = 0;
    CC->FSHADEPC.reg = 256;

    dingus_loop();
}
