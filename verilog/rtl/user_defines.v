// SPDX-FileCopyrightText: 2022 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`ifndef __USER_DEFINES_H
// User GPIO initial configuration parameters
`define __USER_DEFINES_H

// deliberately erroneous placeholder value; user required to config GPIO's to other
`define GPIO_MODE_INVALID                  13'hXXXX

// Authoritive source of these MODE defs is: caravel/verilog/rtl/user_defines.v
// Useful GPIO mode values.  These match the names used in defs.h.
//
`define GPIO_MODE_MGMT_STD_INPUT_NOPULL    13'h0403
`define GPIO_MODE_MGMT_STD_INPUT_PULLDOWN  13'h0c01
`define GPIO_MODE_MGMT_STD_INPUT_PULLUP    13'h0801
`define GPIO_MODE_MGMT_STD_OUTPUT          13'h1809
`define GPIO_MODE_MGMT_STD_BIDIRECTIONAL   13'h1801
`define GPIO_MODE_MGMT_STD_ANALOG          13'h000b

`define GPIO_MODE_USER_STD_INPUT_NOPULL    13'h0402
`define GPIO_MODE_USER_STD_INPUT_PULLDOWN  13'h0c00
`define GPIO_MODE_USER_STD_INPUT_PULLUP    13'h0800
`define GPIO_MODE_USER_STD_OUTPUT          13'h1808
`define GPIO_MODE_USER_STD_BIDIRECTIONAL   13'h1800
`define GPIO_MODE_USER_STD_OUT_MONITORED   13'h1802
`define GPIO_MODE_USER_STD_ANALOG          13'h000a

// The power-on configuration for GPIO 0 to 4 is fixed and cannot be
// modified (allowing the SPI and debug to always be accessible unless
// overridden by a flash program).

// The values below can be any of the standard types defined above,
// or they can be any 13-bit value if the user wants a non-standard
// startup state for the GPIO.  By default, every GPIO from 5 to 37
// is set to power up as an input controlled by the management SoC.
// Users may want to redefine these so that the user project powers
// up in a state that can be used immediately without depending on
// the management SoC to run a startup program to configure the GPIOs.

`define USER_CONFIG_GPIO_5_INIT  `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_6_INIT  `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_7_INIT  `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_8_INIT  `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_9_INIT  `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_10_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_11_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_12_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_13_INIT `GPIO_MODE_INVALID

// Configurations of GPIO 14 to 24 are used on caravel but not caravan.
`define USER_CONFIG_GPIO_14_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_15_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_16_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_17_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_18_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_19_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_20_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_21_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_22_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_23_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_24_INIT `GPIO_MODE_INVALID

`define USER_CONFIG_GPIO_25_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_26_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_27_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_28_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_29_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_30_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_31_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_32_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_33_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_34_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_35_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_36_INIT `GPIO_MODE_INVALID
`define USER_CONFIG_GPIO_37_INIT `GPIO_MODE_INVALID

`endif // __USER_DEFINES_H

`define WIDTH (320)
`define HEIGHT (200)

`define SC_WIDTH ($clog2((`WIDTH) > (`HEIGHT) ? (`WIDTH) : (`HEIGHT)))

`define WORD_WIDTH (32)
`define WORD `WORD_WIDTH - 1:0

`define COLOR_WIDTH (8)
`define COLOR `COLOR_WIDTH - 1:0

`define TEX_DIM_WIDTH (16)
`define TEX_DIM `TEX_DIM_WIDTH - 1:0

`define DECIMAL_POS (10)

`define WORD_SMAX (1 << (`WORD_WIDTH - 2))

`define RAST_WAVG_OUT_WIDTH (`SC_WIDTH * 2 + `WORD_WIDTH * 3)
`define RAST_DT_OUT_WIDTH (`SC_WIDTH * 2 + `WORD_WIDTH * 3)
`define RAST_TS_OUT_WIDTH (`COLOR_WIDTH + `SC_WIDTH * 2 + `WORD_WIDTH * 3)

`define BUS_ADDR_SIZE (32)
`define BUS_ADDR_PORT (`BUS_ADDR_SIZE - 1):0

`define BUS_DATA_SIZE (32)
`define BUS_DATA_PORT (`BUS_DATA_SIZE - 1):0

// master in
`define BUS_MIPORT_SIZE (`BUS_DATA_SIZE + 1 + 1)
`define BUS_MIPORT (`BUS_MIPORT_SIZE - 1):0

`define BUS_MI_DATA   0+:`BUS_DATA_SIZE
`define BUS_MI_ACK    (`BUS_DATA_SIZE + 0)
`define BUS_MI_SEQSLV (`BUS_DATA_SIZE + 1)

// master out
`define BUS_MOPORT_SIZE (`BUS_ADDR_SIZE + `BUS_DATA_SIZE + 1 + 1 + 2 + 1)
`define BUS_MOPORT (`BUS_MOPORT_SIZE - 1):0

`define BUS_MO_DATA   0+:`BUS_DATA_SIZE
`define BUS_MO_ADDR   `BUS_DATA_SIZE+:`BUS_ADDR_SIZE
`define BUS_MO_REQ    (`BUS_DATA_SIZE + `BUS_ADDR_SIZE + 0)
`define BUS_MO_SEQMST (`BUS_DATA_SIZE + `BUS_ADDR_SIZE + 1)
`define BUS_MO_SIZE   (`BUS_DATA_SIZE + `BUS_ADDR_SIZE + 2)+:2
`define BUS_MO_RW     (`BUS_DATA_SIZE + `BUS_ADDR_SIZE + 4)

// slave in
`define BUS_SIPORT_SIZE (`BUS_ADDR_SIZE + `BUS_DATA_SIZE + 1 + 1 + 2 + 1)
`define BUS_SIPORT (`BUS_SIPORT_SIZE - 1):0

`define BUS_SI_DATA   0+:`BUS_DATA_SIZE
`define BUS_SI_ADDR   `BUS_DATA_SIZE+:`BUS_ADDR_SIZE
`define BUS_SI_REQ    (`BUS_DATA_SIZE + `BUS_ADDR_SIZE + 0)
`define BUS_SI_SEQMST (`BUS_DATA_SIZE + `BUS_ADDR_SIZE + 1)
`define BUS_SI_SIZE   (`BUS_DATA_SIZE + `BUS_ADDR_SIZE + 2)+:2
`define BUS_SI_RW     (`BUS_DATA_SIZE + `BUS_ADDR_SIZE + 4)

// slave out
`define BUS_SOPORT_SIZE (`BUS_DATA_SIZE + 1 + 1)
`define BUS_SOPORT (`BUS_SOPORT_SIZE - 1):0

`define BUS_SO_DATA   0+:`BUS_DATA_SIZE
`define BUS_SO_ACK    (`BUS_DATA_SIZE + 0)
`define BUS_SO_SEQSLV (`BUS_DATA_SIZE + 1)

`define BUS_READ  (1'b0)
`define BUS_WRITE (1'b1)

`define BUS_SIZE_BYTE   (2'b00)
`define BUS_SIZE_WORD   (2'b01)
`define BUS_SIZE_TWORD  (2'b10)
`define BUS_SIZE_STREAM (2'b11)

// stream
`define STREAM_MOPORT_SIZE(data_size) ((data_size) + 2)
`define STREAM_MOPORT(data_size) `STREAM_MOPORT_SIZE((data_size)) - 1:0

`define STREAM_MIPORT_SIZE(data_size) (1)
`define STREAM_MIPORT(data_size) `STREAM_MIPORT_SIZE((data_size)) - 1:0

`define STREAM_SOPORT_SIZE(data_size) (1)
`define STREAM_SOPORT(data_size) `STREAM_SOPORT_SIZE((data_size)) - 1:0

`define STREAM_SIPORT_SIZE(data_size) ((data_size) + 2)
`define STREAM_SIPORT(data_size) `STREAM_SIPORT_SIZE((data_size)) - 1:0

`define STREAM_MO_DATA(data_size) (data_size) - 1:0
`define STREAM_MO_VALID(data_size) ((data_size) + 0)
`define STREAM_MO_LAST(data_size) ((data_size) + 1)

`define STREAM_MI_READY(data_size) (0)

`define STREAM_SO_READY(data_size) (0)

`define STREAM_SI_DATA(data_size) (data_size) - 1:0
`define STREAM_SI_VALID(data_size) ((data_size) + 0)
`define STREAM_SI_LAST(data_size) ((data_size) + 1)

// addresses
`define ADDR_FB0          (0)
`define ADDR_FB1          (320 * 240)
`define ADDR_DEPTH_BUFFER (153600)

// VGA
`define VGA_RES_320x240 (2)
`define VGA_RES_160x120 (4)
`define VGA_RES_80x60 (8)

`define VGA_BASE_H_ACTIVE (640)
`define VGA_BASE_H_FPORCH (16)
`define VGA_BASE_H_SYNC   (64)
`define VGA_BASE_H_BPORCH (80)
`define VGA_BASE_V_ACTIVE (480)
`define VGA_BASE_V_FPORCH (3)
`define VGA_BASE_V_SYNC   (4)
`define VGA_BASE_V_BPORCH (6)

// ALU
`define ALU_CTL_SIZE 4

`define ALU_ADD_CTL     (`ALU_CTL_SIZE'b0000)
`define ALU_SUB_CTL     (`ALU_CTL_SIZE'b0001)
`define ALU_MULT_CTL    (`ALU_CTL_SIZE'b0010)
`define ALU_AND_CTL     (`ALU_CTL_SIZE'b0011)
`define ALU_OR_CTL      (`ALU_CTL_SIZE'b0100)
`define ALU_XOR_CTL     (`ALU_CTL_SIZE'b0101)
`define ALU_SEQ_CTL     (`ALU_CTL_SIZE'b0110)
`define ALU_SLT_CTL     (`ALU_CTL_SIZE'b0111)
`define ALU_SLL_CTL     (`ALU_CTL_SIZE'b1000)
`define ALU_SRL_CTL     (`ALU_CTL_SIZE'b1001)
`define ALU_SRA_CTL     (`ALU_CTL_SIZE'b1010)
`define ALU_SLTU_CTL    (`ALU_CTL_SIZE'b1011)
`define ALU_NOP_CTL     (`ALU_CTL_SIZE'b1100)

//SIGN EXT
`define IMM_CTL_SIZE 2
`define IMM_13_BIT 0
`define IMM_16_BIT 1
`define IMM_23_BIT 2
`define IMM_13_WIDTH 13
`define IMM_16_WIDTH 16
`define IMM_23_WIDTH 23
`define PAD_19_BITS 19
`define PAD_16_BITS 16
`define PAD_9_BITS 9
`define MSB_13_IMM 12
`define MSB_16_IMM 15
`define MSB_23_IMM 22

//ISA
`define OPCODE_WIDTH            6
`define OPCODE_IDX              31:26
`define PREDICATE_BITS_WIDTH	3
`define PREDICATE_IDX           25:23
`define REG_DEST_WIDTH          4
`define REG_DEST_IDX            22:19
`define REG_SOURCE_WIDTH        6
`define R1_IDX                  18:13
`define R2_IDX                  12:7
`define SHIFT_WIDTH             5
`define SHIFT_IDX               4:0

`define ADD_OPCODE      (`OPCODE_WIDTH'h00)
`define ADDI_OPCODE     (`OPCODE_WIDTH'h01)
`define SUB_OPCODE      (`OPCODE_WIDTH'h02)
`define MUL_OPCODE      (`OPCODE_WIDTH'h03)
`define MULI_OPCODE     (`OPCODE_WIDTH'h04)
`define AND_OPCODE      (`OPCODE_WIDTH'h05)
`define ANDI_OPCODE     (`OPCODE_WIDTH'h06)
`define OR_OPCODE       (`OPCODE_WIDTH'h07)
`define ORI_OPCODE      (`OPCODE_WIDTH'h08)
`define XOR_OPCODE      (`OPCODE_WIDTH'h09)
`define XORI_OPCODE     (`OPCODE_WIDTH'h0A)
`define SLL_OPCODE      (`OPCODE_WIDTH'h0B)
`define SRL_OPCODE      (`OPCODE_WIDTH'h0C)
`define SRA_OPCODE      (`OPCODE_WIDTH'h0D)
`define SLLV_OPCODE     (`OPCODE_WIDTH'h0E)
`define SRLV_OPCODE     (`OPCODE_WIDTH'h0F)
`define SRAV_OPCODE     (`OPCODE_WIDTH'h10)
`define LUI_OPCODE      (`OPCODE_WIDTH'h11)
`define LLI_OPCODE      (`OPCODE_WIDTH'h12)
`define OUT_OPCODE      (`OPCODE_WIDTH'h13)
`define MAC_OPCODE      (`OPCODE_WIDTH'h14)
`define MACCL_OPCODE    (`OPCODE_WIDTH'h15)
`define MACRD_OPCODE    (`OPCODE_WIDTH'h16)
`define SPEQ_OPCODE     (`OPCODE_WIDTH'h17)
`define SPLT_OPCODE     (`OPCODE_WIDTH'h18)
`define SPLTU_OPCODE    (`OPCODE_WIDTH'h19)
`define CLRP_OPCODE     (`OPCODE_WIDTH'h1A)
`define SPR_OPCODE      (`OPCODE_WIDTH'h1B)
`define SRP_OPCODE      (`OPCODE_WIDTH'h1C)
`define SREQ_OPCODE     (`OPCODE_WIDTH'h1D)
`define SRLT_OPCODE     (`OPCODE_WIDTH'h1E)
`define SRTLU_OPCODE    (`OPCODE_WIDTH'h1F)
`define LW_OPCODE       (`OPCODE_WIDTH'h20)
`define LB_OPCODE       (`OPCODE_WIDTH'h21)
`define SW_OPCODE       (`OPCODE_WIDTH'h22)
`define SB_OPCODE       (`OPCODE_WIDTH'h23)
`define JUMP_OPCODE     (`OPCODE_WIDTH'h24)
`define JAL_OPCODE      (`OPCODE_WIDTH'h25)
`define JRET_OPCODE     (`OPCODE_WIDTH'h26)
`define HALT_OPCODE     (`OPCODE_WIDTH'h27)

`define WB_SIG_WIDTH    2
`define WB_EX_RESULT   (`WB_SIG_WIDTH'h0)
`define WB_MEM_RESULT   (`WB_SIG_WIDTH'h1)
`define WB_MAC_RESULT   (`WB_SIG_WIDTH'h2)
//decoder
//decode ctl sigs
`define R1_USE_GLOBAL_VAL_IDX   (0)
`define R2_USE_GLOBAL_VAL_IDX   (`R1_USE_GLOBAL_VAL_IDX + 1)
`define IMM_SIZE_IDX            (`R2_USE_GLOBAL_VAL_IDX + `IMM_CTL_SIZE):(`R2_USE_GLOBAL_VAL_IDX + 1)
`define SIGN_EXT_IDX            (`R2_USE_GLOBAL_VAL_IDX + `IMM_CTL_SIZE + 1)
`define OUT_IDX                 (`SIGN_EXT_IDX + 1)
//ex ctl sigs
`define USE_IMM_IDX         (`OUT_IDX + 1)
`define USE_PC_IDX          (`USE_IMM_IDX + 1)
`define USE_ALU_RESULT_IDX  (`USE_PC_IDX + 1)
`define ALU_CTL_IDX         (`USE_IMM_IDX + `ALU_CTL_SIZE):(`USE_ALU_RESULT_IDX + 1)
`define IS_PREDICABLE_IDX   (`USE_IMM_IDX + `ALU_CTL_SIZE + 1)
`define PREDICATE_WRITE_IDX (`IS_PREDICABLE_IDX + 1)

`define PREDICATE_WRITE_BITS_IDX    (`PREDICATE_WRITE_IDX + `PREDICATE_BITS_WIDTH):(`PREDICATE_WRITE_IDX + 1)
//mem-acc ctl sigs
`define IS_LOAD_IDX         (`PREDICATE_WRITE_IDX + `PREDICATE_BITS_WIDTH + 1)
`define IS_STORE_IDX        (`IS_LOAD_IDX + 1)
`define ACCUM_CLR_IDX       (`IS_STORE_IDX + 1)
`define IS_ACCUMULATE_IDX   (`ACCUM_CLR_IDX + 1)
//wb ctl sigs
`define REGFILE_WRITE_IDX	(`IS_ACCUMULATE_IDX + 1)
`define WB_SIG_IDX          (`REGFILE_WRITE_IDX + `WB_SIG_WIDTH):(`REGFILE_WRITE_IDX + 1)

`define CTL_SIGS_WIDTH      (`REGFILE_WRITE_IDX + `WB_SIG_WIDTH+ 1)

// Shaded vertices (sizes are temporary)
`define SHADED_VERTEX_WIDTH (32)
`define SHADED_VERTEX (`SHADED_VERTEX_WIDTH-1):0

// Wishbone reg
`define WBREG_TYPE_REG (0)
`define WBREG_TYPE_W1C (1) // Write 1 to clear
`define WBREG_TYPE_W1S (2) // Write 1 to set
`define WBREG_TYPE_W1T (3) // Write 1 to toggle

`define CORE_MAILBOX_HEIGHT (8)
