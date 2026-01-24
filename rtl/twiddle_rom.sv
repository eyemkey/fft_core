module twiddle_rom #(
    parameter int DELAY,
    parameter string MEMFILE,
    parameter int WIDTH = 16
)(
    input  logic [$clog2(DELAY)-1:0] addr,
    output logic signed [WIDTH-1:0] tw_re,
    output logic signed [WIDTH-1:0] tw_im
);
    // packed: [2*WIDTH-1:WIDTH] = re, [WIDTH-1:0] = im
    logic [2*WIDTH-1:0] rom [0:DELAY-1];

    initial begin
        $readmemh(MEMFILE, rom);
    end

    always_comb begin
        tw_re = $signed(rom[addr][2*WIDTH-1:WIDTH]); // most sig bits
        tw_im = $signed(rom[addr][WIDTH-1:0]); //least sig bits
    end
endmodule