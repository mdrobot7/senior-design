`include "svunit_defines.svh"
`include "user_defines.v"
`include "test/clk_rst.v"
`include "stream/stream_fifo.v"
`include "fragment_fifo/serializing_mailman.v"
`include "fragment_fifo/vertex_serializer.v"
`include "fragment_fifo/fragment_fifo.v"
`include "test/stream_master.v"


module serializing_mailman_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "serializing_mailman_ut";
  svunit_testcase svunit_ut;

  localparam int PARALLEL_SIZE = `FRAGMENT_WIDTH;
  localparam int SERIAL_SIZE = `MAILBOX_STREAM_SIZE;
  localparam int DEPTH = 10;
  localparam int MI_Size = `STREAM_MIPORT_SIZE(SERIAL_SIZE);
  localparam int MO_Size = `STREAM_MOPORT_SIZE(SERIAL_SIZE);

  reg  [`STREAM_SIPORT(PARALLEL_SIZE)] sstream_i;
  wire [`STREAM_SOPORT(PARALLEL_SIZE)] sstream_o;

  reg clear_i;

  reg  [MI_Size*`NUM_CORES-1:0] mstream_i;
  wire [MO_Size*`NUM_CORES-1:0] mstream_o;

  wire empty;
  wire full;
  wire done_mailing;

  wire clk, nrst;
  clk_rst_m clk_rst(.clk_o(clk), .nrst_o(nrst));
  
  serializing_mailman #(.PARALLEL_SIZE(PARALLEL_SIZE), .SERIAL_SIZE(SERIAL_SIZE), .DEPTH(DEPTH)) my_serializing_mailman(
    .clk_i(clk),
    .nrst_i(nrst),
    .clear_i(clear_i),
    .sstream_i(sstream_i),
    .sstream_o(sstream_o),
    .mstream_i(mstream_i),
    .mstream_o(mstream_o),
    .empty_o(empty),
    .full_o(full),
    .done_mailing_o(done_mailing)
  );

   stream_master_m #(.SIZE(PARALLEL_SIZE)) fake_raster (
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
    `FAIL_UNLESS(empty == 1'b1)
    `FAIL_UNLESS(full == 1'b0)
    // Load FIFO with data
    for (n = 0; n < DEPTH; n = n + 1) begin
      fake_raster.WRITE_LAST(n);
      clk_rst.WAIT_CYCLES(1);
      `FAIL_UNLESS(empty == 1'b0)
      if(n!=DEPTH-1) begin
        `FAIL_UNLESS(full == 1'b0)
      end
    end
    `FAIL_UNLESS(full == 1'b1)
    mstream_i[MI_Size*0 + `STREAM_MI_READY(SERIAL_SIZE)] = 1'b1;
    clk_rst.WAIT_CYCLES(2);
    `FAIL_UNLESS(full == 1'b0)

  `SVTEST_END

  `SVTEST(data_serialization)
      integer n, i, j;
      reg [`NUM_CORES-1:0] seen_valid_last;
      logic [7:0][31:0] data;

      clear_i = 1'b0;
      for (i = 0; i < `NUM_CORES; i = i + 1) begin 
        mstream_i[MI_Size*i + `STREAM_MI_READY(SERIAL_SIZE)] = 1'b0;
      end
      for (n = 1; n < DEPTH+1; n = n + 1) begin
        for(i = 0; i < 8; i=i+1)begin
          data[i] = i+(n*16);
        end
        fake_raster.WRITE_LAST(data); 
        clk_rst.WAIT_CYCLES(1);
      end
      for (i = 0; i < `NUM_CORES; i = i + 1) begin 
        mstream_i[MI_Size*i + `STREAM_MI_READY(SERIAL_SIZE)] = 1'b1;
        clk_rst.WAIT_CYCLES(1);
        while(1) begin
          if(seen_valid_last[i] == 1'b1)
            break;
          if (mstream_o[MO_Size*i + `STREAM_MO_VALID(SERIAL_SIZE)]) begin
            $display("VALID:i=%0d data=%h", i, mstream_o[(MO_Size*i) +: SERIAL_SIZE]);
            if (mstream_o[MO_Size*i + `STREAM_MO_LAST(SERIAL_SIZE)]) begin
              seen_valid_last[i] = 1'b1;
              mstream_i[MI_Size*i + `STREAM_MI_READY(SERIAL_SIZE)] = 1'b0;
            end
          end
          clk_rst.WAIT_CYCLES(1);
        end
        clk_rst.WAIT_CYCLES(1);
      end
      for (i = 0; i < `NUM_CORES; i = i + 1) begin 
        `FAIL_UNLESS(seen_valid_last[i] == 1'b1);
      end
  `SVTEST_END
  
  //  This test is bad but I think it works if tested correctly
  //   `SVTEST(parallel_serialization)
  //     integer n, i, j;
  //     reg [`NUM_CORES-1:0] seen_valid_last;
  //     logic [7:0][31:0] data;

  //     clear_i = 1'b0;
  //     for (i = 0; i < `NUM_CORES; i = i + 1) begin 
  //       mstream_i[MI_Size*i + `STREAM_MI_READY(SERIAL_SIZE)] = 1'b0;
  //     end
  //     for (n = 1; n < DEPTH+1; n = n + 1) begin
  //       for(i = 0; i < 8; i=i+1)begin
  //         data[i] = i+(n*16);
  //       end
  //       fake_raster.WRITE_LAST(data); 
  //       clk_rst.WAIT_CYCLES(1);
  //     end
  //     for (i = 0; i < `NUM_CORES; i = i + 1) begin 
  //       mstream_i[MI_Size*i + `STREAM_MI_READY(SERIAL_SIZE)] = 1'b1;
  //     end
  //     clk_rst.WAIT_CYCLES(1);
  //     while(1) begin
  //       for (i = 0; i < `NUM_CORES; i = i + 1) begin 
  //       if(seen_valid_last[i] == 1'b1)
  //         break;
  //       if (mstream_o[MO_Size*i + `STREAM_MO_VALID(SERIAL_SIZE)]) begin
  //         $display("VALID:i=%0d data=%h", i, mstream_o[(MO_Size*i) +: SERIAL_SIZE]);
  //         if (mstream_o[MO_Size*i + `STREAM_MO_LAST(SERIAL_SIZE)]) begin
  //           seen_valid_last[i] = 1'b1;
  //           mstream_i[MI_Size*i + `STREAM_MI_READY(SERIAL_SIZE)] = 1'b0;
  //         end
  //       end
  //       clk_rst.WAIT_CYCLES(1);
  //     end
  //     clk_rst.WAIT_CYCLES(1);
  //     if(seen_valid_last =='1)
  //       break;
  //   end
  //   for (i = 0; i < `NUM_CORES; i = i + 1) begin 
  //     `FAIL_UNLESS(seen_valid_last[i] == 1'b1);
  //   end
  // `SVTEST_END

  `SVUNIT_TESTS_END

endmodule
