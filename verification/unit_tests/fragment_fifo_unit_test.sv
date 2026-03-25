`include "svunit_defines.svh"
`include "user_defines.v"
`include "test/clk_rst.v"
`include "stream/stream_fifo.v"
`include "fragment_fifo/fragment_fifo.v"
`include "test/stream_master.v"

module fragment_fifo_m_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "fragment_fifo_m_ut";
  svunit_testcase svunit_ut;

  localparam int SIZE  = `FRAGMENT_WIDTH;
  localparam int DEPTH = 20;
  localparam int MI_Size = `STREAM_MIPORT_SIZE(SIZE);
  localparam int MO_Size = `STREAM_MOPORT_SIZE(SIZE);

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));

  reg  [`STREAM_SIPORT(SIZE)] sstream_i;
  wire [`STREAM_SOPORT(SIZE)] sstream_o;

  reg clear_i;

  reg  [MI_Size*`NUM_CORES-1:0] mstream_i;
  wire [MO_Size*`NUM_CORES-1:0] mstream_o;

  wire empty_o;
  wire full_o;
  wire done_mailing_o;


  fragment_fifo_m #(.SIZE(SIZE), .DEPTH(DEPTH)) my_fragment_fifo_m(
    .clk_i(clk),
    .nrst_i(nrst),
    .clear_i(clear_i),
    .sstream_i(sstream_i),
    .sstream_o(sstream_o),
    .mstream_i(mstream_i),
    .mstream_o(mstream_o),
    .empty_o(empty_o),
    .full_o(full_o),
    .done_mailing_o(done_mailing_o)
  );

  stream_master_m #(SIZE) fake_raster (
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

  `SVTEST(mc_flags)
    integer n;
    clear_i = 1'b0;
    `FAIL_UNLESS(empty_o == 1'b1)
    `FAIL_UNLESS(full_o == 1'b0)
    // Load FIFO with data
    for (n = 0; n < DEPTH; n = n + 1) begin
      fake_raster.WRITE_LAST(n);
      clk_rst.WAIT_CYCLES(1);
      `FAIL_UNLESS(empty_o == 1'b0)
      if(n!=DEPTH-1) begin
        `FAIL_UNLESS(full_o == 1'b0)
      end
    end
    `FAIL_UNLESS(full_o == 1'b1)
    `SVTEST_END

  `SVTEST(round_robin_all_cores)
      integer n, i, j;
      reg [`NUM_CORES-1:0] seen_valid;
      clear_i = 1'b0;
      // Load FIFO with data
      for (n = 0; n < DEPTH; n = n + 1) begin
        fake_raster.WRITE_LAST(n); 
        clk_rst.WAIT_CYCLES(1);
      end
      for (i = 0; i < `NUM_CORES; i = i + 1) begin 
        // Sets core i core to ready
        mstream_i[MI_Size*i + `STREAM_MI_READY(SIZE)] = 1'b1;
        // Waits until frag fifo selects that ready core and "sends" to core
        while(1) begin
          if (mstream_o[MO_Size*i + `STREAM_MO_VALID(SIZE)]) begin
              seen_valid[i] = 1'b1;
              $display("i=%0d data=%h", i, mstream_o[(MO_Size*i) +: SIZE]);
              break;
          end
          else begin
            clk_rst.WAIT_CYCLES(1);
          end
        end
        clk_rst.WAIT_CYCLES(1);
        // Deassert ready bit
        mstream_i[MI_Size*i + `STREAM_MI_READY(SIZE)] = 1'b0;  
      end
      clk_rst.WAIT_CYCLES(1);
      for (i = 0; i < `NUM_CORES; i = i + 1) begin 
        `FAIL_UNLESS(seen_valid[i] == 1'b1);
      end
    `SVTEST_END

    `SVTEST(clear_fifo)
    integer n;
    clear_i = 1'b0;
    `FAIL_UNLESS(empty_o == 1'b1)
    `FAIL_UNLESS(full_o == 1'b0)
    // Load FIFO with data
    for (n = 0; n < DEPTH; n = n + 1) begin
      fake_raster.WRITE_LAST(n);
      clk_rst.WAIT_CYCLES(1);
      `FAIL_UNLESS(empty_o == 1'b0)
      if(n!=DEPTH-1) begin
        `FAIL_UNLESS(full_o == 1'b0)
      end
    end
    `FAIL_UNLESS(full_o == 1'b1)
    clear_i <= 1'b1;
    clk_rst.WAIT_CYCLES(1);
    //For sanity set a core to ready and make sure it never receives the data as we're clearing
    mstream_i[`STREAM_MI_READY(SIZE)] = 1'b1;
    while(!empty_o) begin
      `FAIL_UNLESS(mstream_o[`STREAM_MO_VALID(SIZE)] == 1'b0)
      clk_rst.WAIT_CYCLES(1);
    end
    clear_i = 1'b0;
    `FAIL_UNLESS(empty_o == 1'b1)
    `SVTEST_END

  `SVUNIT_TESTS_END

endmodule