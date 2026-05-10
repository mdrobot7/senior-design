###############################################################################
# Created by write_sdc
# Sun Jan  4 17:48:44 2026
###############################################################################
current_design alu_m
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name clk -period 25.0000 
set_clock_uncertainty 0.2500 clk
set_clock_latency -source -min 4.6500 [get_clocks {clk}]
set_clock_latency -source -max 5.5700 [get_clocks {clk}]
###############################################################################
# Environment
###############################################################################
set_load -pin_load 0.1900 [get_ports {result_o[31]}]
set_load -pin_load 0.1900 [get_ports {result_o[30]}]
set_load -pin_load 0.1900 [get_ports {result_o[29]}]
set_load -pin_load 0.1900 [get_ports {result_o[28]}]
set_load -pin_load 0.1900 [get_ports {result_o[27]}]
set_load -pin_load 0.1900 [get_ports {result_o[26]}]
set_load -pin_load 0.1900 [get_ports {result_o[25]}]
set_load -pin_load 0.1900 [get_ports {result_o[24]}]
set_load -pin_load 0.1900 [get_ports {result_o[23]}]
set_load -pin_load 0.1900 [get_ports {result_o[22]}]
set_load -pin_load 0.1900 [get_ports {result_o[21]}]
set_load -pin_load 0.1900 [get_ports {result_o[20]}]
set_load -pin_load 0.1900 [get_ports {result_o[19]}]
set_load -pin_load 0.1900 [get_ports {result_o[18]}]
set_load -pin_load 0.1900 [get_ports {result_o[17]}]
set_load -pin_load 0.1900 [get_ports {result_o[16]}]
set_load -pin_load 0.1900 [get_ports {result_o[15]}]
set_load -pin_load 0.1900 [get_ports {result_o[14]}]
set_load -pin_load 0.1900 [get_ports {result_o[13]}]
set_load -pin_load 0.1900 [get_ports {result_o[12]}]
set_load -pin_load 0.1900 [get_ports {result_o[11]}]
set_load -pin_load 0.1900 [get_ports {result_o[10]}]
set_load -pin_load 0.1900 [get_ports {result_o[9]}]
set_load -pin_load 0.1900 [get_ports {result_o[8]}]
set_load -pin_load 0.1900 [get_ports {result_o[7]}]
set_load -pin_load 0.1900 [get_ports {result_o[6]}]
set_load -pin_load 0.1900 [get_ports {result_o[5]}]
set_load -pin_load 0.1900 [get_ports {result_o[4]}]
set_load -pin_load 0.1900 [get_ports {result_o[3]}]
set_load -pin_load 0.1900 [get_ports {result_o[2]}]
set_load -pin_load 0.1900 [get_ports {result_o[1]}]
set_load -pin_load 0.1900 [get_ports {result_o[0]}]
set_timing_derate -early 0.9500
set_timing_derate -late 1.0500
###############################################################################
# Design Rules
###############################################################################
set_max_transition 1.0000 [current_design]
set_max_fanout 16.0000 [current_design]
