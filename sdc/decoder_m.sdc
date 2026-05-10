###############################################################################
# Created by write_sdc
# Sun Jan 11 06:07:15 2026
###############################################################################
current_design decoder_m
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
set_load -pin_load 0.1900 [get_ports {control_sigs_o[22]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[21]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[20]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[19]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[18]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[17]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[16]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[15]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[14]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[13]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[12]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[11]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[10]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[9]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[8]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[7]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[6]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[5]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[4]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[3]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[2]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[1]}]
set_load -pin_load 0.1900 [get_ports {control_sigs_o[0]}]
set_timing_derate -early 0.9500
set_timing_derate -late 1.0500
###############################################################################
# Design Rules
###############################################################################
set_max_transition 1.0000 [current_design]
set_max_fanout 16.0000 [current_design]
