`timescale 1ns / 1ps

module fft_core_tb;

    localparam int N = 16;
    localparam int WIDTH = 16;

    logic clk;
    logic rst_n;

    logic signed [WIDTH-1:0] in_re;
    logic signed [WIDTH-1:0] in_im;
    logic in_valid;

    logic signed [WIDTH-1:0] out_re;
    logic signed [WIDTH-1:0] out_im;
    logic out_valid;

    fft_core #(
        .N(N),
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_re(in_re),
        .in_im(in_im),
        .in_valid(in_valid),
        .out_re(out_re),
        .out_im(out_im),
        .out_valid(out_valid)
    );

    // clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Read raw bits as unsigned, then cast to signed
    logic [WIDTH-1:0] buff_input [0:2*N-1];
    logic signed [WIDTH-1:0] buff_input_re [0:N-1];
    logic signed [WIDTH-1:0] buff_input_im [0:N-1];

    logic signed [WIDTH-1:0] buff_out_re [0:N-1];
    logic signed [WIDTH-1:0] buff_out_im [0:N-1];

    initial begin
        rst_n    <= 1'b0;
        in_re    <= '0;
        in_im    <= '0;
        in_valid <= 1'b0;

        $readmemb("tb/input.mem", buff_input);

        for (int i = 0; i < N; i++) begin
            buff_input_re[i] = $signed(buff_input[i]);
            buff_input_im[i] = $signed(buff_input[i+N]);
        end

        repeat (5) @(posedge clk);
        rst_n <= 1'b1;
        repeat (2) @(posedge clk);

        for (int n = 0; n < N; n++) begin
            @(posedge clk);
            in_valid <= 1'b1;
            in_re    <= buff_input_re[n];
            in_im    <= buff_input_im[n];
        end

        @(posedge clk);
        in_valid <= 1'b0;
        in_re    <= '0;
        in_im    <= '0;
    end

    initial begin
        int out_count = 0;

        while (!rst_n) @(posedge clk);

        while (out_count < N) begin
            @(posedge clk);
            #1step; // sample after signals settle in this time step
            if (out_valid) begin
                $display(out_re);
                buff_out_re[out_count] = out_re;
                buff_out_im[out_count] = out_im;
                out_count++;
            end
        end

        $display("\nCaptured FFT output (signed ints):");
        for (int k = 0; k < N; k++) begin
            $display("X[%0d] = %0d + j%0d", k,
                     $signed(buff_out_re[k]), $signed(buff_out_im[k]));
        end
        $finish;
    end

endmodule
