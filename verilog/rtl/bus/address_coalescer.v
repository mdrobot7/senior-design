/**
*   Address coalescer for uGPU cores
*   Reduces the number of memory reads needed when multiple cores want to access the same address
*/

module address_coalescer_m(
    input wire[`BUS_SIPORT_SIZE*`NUM_CORES-1:0] core_port_i,
    output reg[`BUS_SOPORT_SIZE*`NUM_CORES-1:0] core_port_o,
    input wire[`BUS_MIPORT_SIZE*`NUM_CORES-1:0] arb_port_i,
    output reg[`BUS_MOPORT_SIZE*`NUM_CORES-1:0] arb_port_o
);

    reg[`NUM_CORES-1:0] reqs_in;
    reg[`NUM_CORES-1:0] coal_reqs_out;
    reg[`NUM_CORES-1:0] coalesce;
    reg[`BUS_ADDR_PORT] addr [`NUM_CORES-1:0];

    reg[`NUM_CORES-1:0] ref_core;
    reg[`BUS_SIPORT] ref_core_bus;
    reg[`BUS_ADDR_PORT] ref_addr;
    reg[`BUS_MIPORT] ref_arb_bus;
    reg one_hot;
    
    always @(*) begin : COALESCE
        integer i;
        //default values
        ref_core = 0;
        coal_reqs_out = 0;
        ref_core_bus = core_port_i[`BUS_SIPORT];
        ref_addr = ref_core_bus[`BUS_SI_ADDR];
        ref_arb_bus = arb_port_i[`BUS_MIPORT];
        arb_port_o = core_port_i;
        core_port_o = arb_port_i;

        //get input requests
        for(i = 0; i < `NUM_CORES; i = i + 1) begin
            reqs_in[i] = core_port_i[(i*`BUS_SIPORT_SIZE) + `BUS_SI_REQ];
        end
        one_hot = (reqs_in != 0) && ((reqs_in & (reqs_in - 1)) == 0);
        //priority encoder for the first set req line
        for (i = `NUM_CORES-1; i < 0; i = i - 1) begin
            if(reqs_in[i]) begin
                ref_core = i;
                ref_core_bus = core_port_i[i*`BUS_SIPORT_SIZE +: `BUS_SIPORT_SIZE];
                ref_arb_bus = core_port_i[i*`BUS_MIPORT_SIZE +: `BUS_MIPORT_SIZE];
            end
        end

        //per core operations
        for(i = 0; i < `NUM_CORES; i = i + 1) begin
            //fill proxy wires
            addr[i] = core_port_i[(i*`BUS_SIPORT_SIZE) + `BUS_SI_ADDR];
            coalesce[i] = (addr[i] == ref_addr) | (~reqs_in[i]);

            
            if(reqs_in[i] && (coalesce == {`NUM_CORES{1'b1}}) && (!one_hot)) begin
                //coalesce 
                if(i == ref_core)
                    coal_reqs_out[i] = 1;

                arb_port_o[(i*`BUS_SIPORT_SIZE) + `BUS_SI_REQ] = coal_reqs_out[i];
                core_port_o[(i*`BUS_MIPORT_SIZE) +: `BUS_MIPORT_SIZE] = ref_arb_bus;
            end
        end
    end
endmodule
