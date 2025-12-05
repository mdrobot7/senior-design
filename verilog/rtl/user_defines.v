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
`define DECIMAL_POS (10)

`define WORD_SMAX (1 << (`WORD_WIDTH - 2))

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
`define ADDR_DEPTH_BUFFER (100000)

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
