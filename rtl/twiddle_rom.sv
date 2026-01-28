module twiddle_rom #(
    parameter int DELAY,
    parameter string MEMFILE,
    parameter int WIDTH = 16,
    parameter int ADDR_BITS = (DELAY > 1) ? $clog2(DELAY) : 1
)(
    input  logic [ADDR_BITS-1:0] addr,
    output logic signed [WIDTH-1:0] tw_re,
    output logic signed [WIDTH-1:0] tw_im
);
    logic [WIDTH-1:0] rom [0:2*DELAY-1];

    initial $readmemb(MEMFILE, rom);

    always_comb begin
        tw_re = $signed(rom[addr]);
        tw_im = $signed(rom[addr + DELAY]);
    end
endmodule
