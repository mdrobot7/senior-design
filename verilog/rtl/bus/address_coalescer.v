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

    reg[`NUM_CORES-1:0] reqs;
    reg[`NUM_CORES-1:0] coalesce;
    reg[`BUS_ADDR_PORT] addr [`NUM_CORES-1:0];

    reg[`BUS_SIPORT] ref_core_bus;
    reg[`BUS_ADDR_PORT] ref_addr;
    
    always @(*) begin : COALESCE
        integer i;
        //default value
        ref_core_bus = core_port_i[`BUS_SIPORT];
        ref_addr = ref_core_bus[`BUS_SI_ADDR];
        
        for(i = 0; i < `NUM_CORES; i = i + 1) begin
            //fill proxy wires
            addr[i] = core_port_i[(i*`BUS_SIPORT_SIZE) + `BUS_SI_ADDR];
            reqs[i] = core_port_i[(i*`BUS_SIPORT_SIZE) + `BUS_SI_REQ];

            coalesce[i] = (addr[i] == ref_addr) | (~reqs[i]);

            
            if(reqs[i] && coalesce == {`NUM_CORES{1'b1}}) begin
                //we give core i the core 0 input
                arb_port_o[(i*`BUS_MOPORT_SIZE)+:`BUS_MOPORT_SIZE] = 0;
                core_port_o[(i*`BUS_SOPORT_SIZE)+:`BUS_SOPORT_SIZE] = arb_port_i[`BUS_MOPORT];
            end
            else begin
                arb_port_o[(i*`BUS_MOPORT_SIZE)+:`BUS_MOPORT_SIZE] = core_port_i[(i*`BUS_SIPORT_SIZE)+:`BUS_SIPORT_SIZE];
                core_port_o[(i*`BUS_SOPORT_SIZE)+:`BUS_SOPORT_SIZE] = arb_port_i[(i*`BUS_MIPORT_SIZE)+:`BUS_MIPORT_SIZE];
            end
        end

        if(coalesce == {`NUM_CORES{1'b1}})
            arb_port_o[`BUS_SIPORT] = core_port_i[`BUS_SIPORT];

        //fill reference_core_bus with the first addr req that is set
        for (i = 1; i < `NUM_CORES; i = i + 1) begin
            if ((~| (reqs & ((1 << i) - 1))) && reqs[i]) begin
                ref_core_bus = core_port_i[i*`BUS_SIPORT_SIZE +: `BUS_SIPORT_SIZE];
            end
        end
    end
endmodule
