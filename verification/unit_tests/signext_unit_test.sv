`include "svunit_defines.svh"
`include "user_defines.v"
`include "core/signext.v"
`include "test/clk_rst.v"

module signext_unit_test;
    import svunit_pkg::svunit_testcase;

    reg [`WORD_WIDTH-10:0]  in;
    reg                           ext;
    reg [`IMM_CTL_SIZE-1:0]       ext_size;

    wire [`WORD_WIDTH-1:0]   imm_ext_o;

    svunit_testcase svunit_ut;
    string test_name = "signext_ut";

    signext my_signext_m(
    .in_i(in),
    .ext_i(ext),
    .imm_size_i(ext_size),
    .imm_ext_o(imm_ext_o)
    );

    function void build();
        svunit_ut = new(test_name);
    endfunction


    task setup();
        svunit_ut.setup();
        //setup code
    endtask

    task teardown();
        svunit_ut.teardown();
    endtask


    /*
    * Unit Tests
    */    
    `SVUNIT_TESTS_BEGIN
        integer i;

        `SVTEST(i_type_test_sign_ext)
            ext_size = `IMM_13_BIT;
            ext = 1;
            for(i = 0; i < 100; i = i + 1) begin
                in = {$random};
                #1;
                `FAIL_UNLESS_EQUAL(imm_ext_o, {{`PAD_19_BITS{in[`MSB_13_IMM]}}, in[`IMM_13_WIDTH-1:0]});
            end
        `SVTEST_END

        `SVTEST(i_type_test_zero_ext)
            ext_size = `IMM_13_BIT;
            ext = 0;
            for(i = 0; i < 100; i = i + 1) begin
                in = {$random};
                #1;
                `FAIL_UNLESS_EQUAL(imm_ext_o, {{`PAD_19_BITS{0}}, in[`IMM_13_WIDTH-1:0]});
            end
        `SVTEST_END

        `SVTEST(d_type_test_sign_ext)
            ext_size = `IMM_16_BIT;
            ext = 1;
            for(i = 0; i < 100; i = i + 1) begin
                in = {$random};
                #1;
                `FAIL_UNLESS_EQUAL(imm_ext_o, {{`PAD_16_BITS{in[`MSB_16_IMM]}}, in[`IMM_16_WIDTH-1:0]});
            end
        `SVTEST_END
        
        `SVTEST(d_type_test_zero_ext)
            ext_size = `IMM_16_BIT;
            ext = 0;
            for(i = 0; i < 100; i = i + 1) begin
                in = {$random};
                #1;
                `FAIL_UNLESS_EQUAL(imm_ext_o, {{`PAD_16_BITS{0}}, in[`IMM_16_WIDTH-1:0]});
            end
        `SVTEST_END

        `SVTEST(j_type_test_sign_ext)
            ext_size = `IMM_23_BIT;
            ext = 1;
            for(i = 0; i < 100; i = i + 1) begin
                in = {$random};
                #1;
                `FAIL_UNLESS_EQUAL(imm_ext_o, {{`PAD_9_BITS{in[`MSB_23_IMM]}}, in[`IMM_23_WIDTH-1:0]});
            end
        `SVTEST_END
        
        `SVTEST(j_type_test_zero_ext)
            ext_size = `IMM_23_BIT;
            ext = 0;
            for(i = 0; i < 100; i = i + 1) begin
                in = {$random};
                #1;
                `FAIL_UNLESS_EQUAL(imm_ext_o, {{`PAD_9_BITS{0}}, in[`IMM_23_WIDTH-1:0]});
            end
        `SVTEST_END

        `SVTEST(sign_ext)

        in = 23'b11111110000000011110000;
        ext = 1;
        ext_size = `IMM_13_BIT;
        #1
        `FAIL_UNLESS_EQUAL(imm_ext_o, 32'b00000000000000000000000011110000)

        in = 23'b11111111111111111111111;
        ext = 0;
        ext_size = `IMM_16_BIT;
        #1
        `FAIL_UNLESS_EQUAL(imm_ext_o, 32'b00000000000000001111111111111111)

        in = 23'b00011111111111111111111;
        ext = 1;
        ext_size = `IMM_23_BIT;
        #1
        `FAIL_UNLESS_EQUAL(imm_ext_o, 32'b00000000000011111111111111111111)

        `SVTEST_END



    `SVUNIT_TESTS_END

endmodule