`include "svunit_defines.svh"
`include "user_defines.v"
`include "test/clk_rst.v"
`include "vertex_serializer.v"
`include "test/stream_master.v"
// `include "stream/stream_fifo.v"

module vertex_serializer_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "vertex_serializer_m_ut";
  svunit_testcase svunit_ut;

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

  reg  [`STREAM_SIPORT(`FRAGMENT_WIDTH)] sstream_i;
  wire [`STREAM_SOPORT(`FRAGMENT_WIDTH)] sstream_o;

  reg  [`STREAM_MIPORT(`MAILBOX_STREAM_SIZE)] mstream_i;
  wire [`STREAM_MOPORT(`MAILBOX_STREAM_SIZE)] mstream_o;

  vertex_serializer_m my_vertex_serializer_m(
    .clk_i(clk),
    .nrst_i(nrst),
    .sstream_i(sstream_i),
    .sstream_o(sstream_o),
    .mstream_i(mstream_i),
    .mstream_o(mstream_o)
  );

    stream_master_m #(`FRAGMENT_WIDTH) fake_raster (
    .clk_i(clk),
    .mstream_i(sstream_o),
    .mstream_o(sstream_i)
  );

  function void build();
    svunit_ut = new(name);
  endfunction

  task setup();
    svunit_ut.setup();
    clk_rst.RESET();
    clk_rst.WAIT_CYCLES(1);
  endtask

  task teardown();
    svunit_ut.teardown();
  endtask

  `SVUNIT_TESTS_BEGIN

  `SVTEST(serialize)
    integer i;
    logic [7:0][31:0] data;

    for(i = 0; i < 8; i++)begin
      data[i] = i;
    end
    mstream_i[`STREAM_MI_READY(`MAILBOX_STREAM_SIZE)] = 1;
    clk_rst.WAIT_CYCLES(1);
    fake_raster.WRITE_LAST(data);
    clk_rst.WAIT_CYCLES(1);
    for(i = 0; i < 8; i++)begin
      $display("READY: %b", sstream_o[`STREAM_SO_READY(`FRAGMENT_WIDTH)]);
      $display("Serializer: %h", mstream_o[`STREAM_MO_DATA(`MAILBOX_STREAM_SIZE)]);
      $display("VALID: %b", mstream_o[`STREAM_MO_VALID(`MAILBOX_STREAM_SIZE)]);

      $display("Expected Data: %h",data[i]);
      $display("LAST: %b", mstream_o[`STREAM_MO_LAST(`MAILBOX_STREAM_SIZE)]);

      `FAIL_UNLESS(mstream_o[`STREAM_MO_DATA(`MAILBOX_STREAM_SIZE)] == data[i])
      `FAIL_UNLESS(mstream_o[`STREAM_MO_VALID(`MAILBOX_STREAM_SIZE)] == 1'b1)
      if(i == 7)
        `FAIL_UNLESS(mstream_o[`STREAM_MO_LAST(`MAILBOX_STREAM_SIZE)] == 1'b1)
      clk_rst.WAIT_CYCLES(1);
      
    end
  `SVTEST_END

  `SVUNIT_TESTS_END

endmodule
