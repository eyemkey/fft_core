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
    always #10 clk = ~clk; //50MHz

    logic [WIDTH-1:0] mem_raw [0:2*N-1];
    logic signed [WIDTH-1:0] x_re [0:N-1];
    logic signed [WIDTH-1:0] x_im [0:N-1];
    
    logic signed [WIDTH-1:0] y_re [0:N-1];
    logic signed [WIDTH-1:0] y_im [0:N-1];
    
    int cycle; 

    always_ff @(posedge clk) begin
        if(!rst_n) cycle <= 0; 
        else cycle <= cycle + 1;
    end
    
    initial begin
        rst_n = 1'b0; 
        in_re = 0; 
        in_im = 0; 
        in_valid = 1'b0; 
        
        $readmemb("input.mem", mem_raw); 
        
        for(int i = 0; i < N; i++) begin
            x_re[i] = $signed(mem_raw[i]); 
            x_im[i] = $signed(mem_raw[i+N]); 
            $display("INPUT x[%0d] = %0d + j%0d", i, x_re[i], x_im[i]);        
        end
        
        repeat(5) @(posedge clk); 
        rst_n <= 1'b1; 
        repeat(2) @(posedge clk); 
        
        for(int n = 0; n < N; n++) begin
            @(posedge clk); 
            in_valid <= 1'b1; 
            in_re <= x_re[n]; 
            in_im <= x_im[n];
            $display("[cycle %0d] FEED n=%0d in=%0d + j%0d", cycle, n, x_re[n], x_im[n]);        
        end
        
        @(posedge clk); 
        in_valid <= 1'b0; 
        in_re <= 0; 
        in_im <= 0; 
    end

initial begin
    int out_count = 0;
    int timeout_cycles = 200;  // prevents sim hang
    int waited = 0;

    // wait for reset deassert
    while (!rst_n) @(posedge clk);

    // capture until N outputs
    while (out_count < N && waited < timeout_cycles) begin
      @(posedge clk);
      waited++;

      // sample after signal updates in this timestep
      #1step;
      if (out_valid) begin
        y_re[out_count] = out_re;
        y_im[out_count] = out_im;
        $display("[cycle %0d] OUT k=%0d  %0d + j%0d", cycle, out_count, out_re, out_im);
        out_count++;
      end
    end

    if (out_count < N) begin
      $display("ERROR: timed out. only captured %0d outputs.", out_count);
      $finish;
    end

    $display("\nCaptured FFT output (signed ints):");
    for (int k = 0; k < N; k++) begin
      $display("X[%0d] = %0d + j%0d", k, y_re[k], y_im[k]);
    end

    $finish;
  end

endmodule
