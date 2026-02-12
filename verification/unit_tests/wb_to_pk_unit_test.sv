`include "svunit_defines.svh"
`include "wb_to_pk.v"
`include "user_defines.v"
`include "test/clk_rst.v"

module wb_to_pk_unit_test;
  import svunit_pkg::svunit_testcase;


    // Wb slave
    reg wb_clk_i,            // clock
    reg wb_rst_i,            // Reset
    reg wbs_stb_i,           // Cycle strobe (asserts when ready to trasnsfer data)
    reg wbs_cyc_i,           // cycle in progress (transfer)
    reg [31:0] wbs_dat_i,    // data in 
    reg [31:0] wbs_adr_i,    // address
    reg wbs_we_i,             // write en 

    wire wbs_ack_o,           // acknowledge (asserted indicates termination of cycle)
    wire [31:0] wbs_dat_o,    // data out


    // PKbus master
    reg [`BUS_MIPORT] mport_i, 
    reg pk_ack_i, 
    reg [`BUS_DATA_PORT] pk_data_i,
    wire pk_rw_o, // WE
    wire [1:0] pk_size_o,
    wire [`BUS_ADDR_PORT] pk_addr_o,
    wire [`BUS_MOPORT] mport_o, 
    wire pk_req_o,
    wire [`BUS_DATA_PORT] pk_data_o


  string name = "wb_to_pk_ut";
  svunit_testcase svunit_ut;


  //===================================
  // This is the UUT that we're 
  // running the Unit Tests on
  //===================================
  wb_to_pk my_wb_to_pk(
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_we_i(wbs_we_i),
    .wbs_ack_o(wbs_ack_o),
    .wbs_dat_o(wbs_dat_o),
    .mport_i(mport_i),
    .pk_ack_i(pk_ack_i),
    .pk_data_i(pk_data_i),
    .pk_rw_o(pk_rw_o),
    .pk_size_o(pk_size_o),
    .pk_addr_o(pk_addr_o),
    .mport_o(mport_o),
    .pk_req_o(pk_req_o),
    .pk_data_o(pk_data_o)
  );


  function void build();
    svunit_ut = new(name);
  endfunction

  task setup();
    svunit_ut.setup();
    /* Place Setup Code Here */

  endtask

  task teardown();
    svunit_ut.teardown();
    /* Place Teardown Code Here */

  endtask


/*
Unit Tests 
*/
  `SVUNIT_TESTS_BEGIN
    
    `SVTEST(test_one)



    `SVTEST_END


  `SVUNIT_TESTS_END

endmodule
