###############################################################################
# Created by write_sdc
# Thu Mar 12 02:23:40 2026
###############################################################################
current_design fragment_fifo_m
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk -period 25.0000 [get_ports {clk_i}]
set_clock_transition 0.1500 [get_clocks {clk}]
set_clock_uncertainty 0.2500 clk
set_propagated_clock [get_clocks {clk}]
set_clock_latency -source -min 4.6500 [get_clocks {clk}]
set_clock_latency -source -max 5.5700 [get_clocks {clk}]
###############################################################################
# Environment
###############################################################################
set_load -pin_load 0.1900 [get_ports {done_mailing}]
set_load -pin_load 0.1900 [get_ports {empty}]
set_load -pin_load 0.1900 [get_ports {full}]
set_load -pin_load 0.1900 [get_ports {sstream_o}]
set_load -pin_load 0.1900 [get_ports {mstream_o[17]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[16]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[15]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[14]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[13]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[12]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[11]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[10]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[9]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[8]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[7]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[6]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[5]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[4]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[3]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[2]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[1]}]
set_load -pin_load 0.1900 [get_ports {mstream_o[0]}]
set_input_transition 0.6100 [get_ports {clk_i}]
set_timing_derate -early 0.9500
set_timing_derate -late 1.0500
###############################################################################
# Design Rules
###############################################################################
set_max_transition 1.0000 [current_design]
set_max_fanout 16.0000 [current_design]
