`timescale 1ns / 1ps

module stage
#(
    parameter int DELAY,
    parameter string MEMFILE,
    parameter int WIDTH = 16 
)
(
    input logic clk, 
    input logic rst_n, 
    
    input logic signed [WIDTH-1:0] in_re,
    input logic signed [WIDTH-1:0] in_im, 
    input logic in_valid,
    
    
    output logic signed [WIDTH-1:0] out_re,
    output logic signed [WIDTH-1:0] out_im,
    output logic out_valid
);

    localparam int LOG2DELAY= $clog2(DELAY);
    localparam int COUNTER_WIDTH  = (LOG2DELAY > 0) ? LOG2DELAY : 1;
    localparam logic [COUNTER_WIDTH:0] COUNTER_MAX = 2*DELAY-1;
        
    logic [COUNTER_WIDTH:0] counter; //MSB for phase check, rest for indexing
    logic [COUNTER_WIDTH-1:0] buffer_index;
    logic phase; // 0-store fifo; 1 - combine 
    
    logic signed [WIDTH-1:0] fifo_buffer_re [0:DELAY-1];
    logic signed [WIDTH-1:0] fifo_buffer_im [0:DELAY-1];
    logic signed [WIDTH-1:0] tw_re, tw_im;
    
    //Butterfly Unit inputs/outputs
    logic signed [WIDTH-1:0] bu_in_a_re, bu_in_a_im; 
    logic signed [WIDTH-1:0] bu_in_b_re, bu_in_b_im;
    logic signed [WIDTH-1:0] bu_out_sum_re, bu_out_sum_im; 
    logic signed [WIDTH-1:0] bu_out_diff_re, bu_out_diff_im;
    
    //Complex Mult Unit inputs/outputs
    logic signed [WIDTH-1:0] cu_in_a_re, cu_in_a_im; 
    logic signed [WIDTH-1:0] cu_in_b_re, cu_in_b_im; 
    logic signed [WIDTH-1:0] cu_out_re, cu_out_im;
    
    
    
    assign buffer_index = (DELAY > 1) ? counter[COUNTER_WIDTH-1:0] : '0;
    assign phase = counter[COUNTER_WIDTH]; 
    
    always_comb begin
        bu_in_a_re = fifo_buffer_re [buffer_index]; 
        bu_in_a_im = fifo_buffer_im [buffer_index];
        
        bu_in_b_re = in_re; 
        bu_in_b_im = in_im;
        
        cu_in_a_re = bu_out_diff_re; 
        cu_in_a_im = bu_out_diff_im; 
        
        cu_in_b_re = tw_re; 
        cu_in_b_im = tw_im; 
        
    end
    
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            integer i; 
            for(i = 0; i < DELAY; i = i + 1) begin
                fifo_buffer_re[i] <= 0;
                fifo_buffer_im[i] <= 0;
            end
            counter <= 0;
            out_re <= 0; 
            out_im <= 0; 
            out_valid <= 1'b0;
        end
        else if (in_valid) begin
            out_re <= in_re; 
            out_im <= in_im; 
            out_valid <= 1'b1; 
            
            if(!phase) begin //Input & no combination, store fifo
                fifo_buffer_re [buffer_index] <= in_re; 
                fifo_buffer_im [buffer_index] <= in_im;            
            end 
            else begin
                out_re <= bu_out_sum_re; 
                out_im <= bu_out_sum_im;
                
                fifo_buffer_re [buffer_index] <= cu_out_re; 
                fifo_buffer_im [buffer_index] <= cu_out_im;
            end
            
            if(counter == COUNTER_MAX) begin
                counter <= 0;             
            end else counter <= counter + 1; 
        end 
        else begin
            out_valid <= 1'b0;
        end
    end    
    
    butterfly_unit #(.WIDTH(WIDTH)) bu (
        .in_a_re(bu_in_a_re), 
        .in_a_im(bu_in_a_im), 
        .in_b_re(bu_in_b_re), 
        .in_b_im(bu_in_b_im), 
        
        .out_sum_re(bu_out_sum_re), 
        .out_sum_im(bu_out_sum_im), 
        .out_diff_re(bu_out_diff_re), 
        .out_diff_im(bu_out_diff_im)
    ); 
    
    complex_mult #(.WIDTH(WIDTH)) cu (
        .in_a_re(cu_in_a_re),
        .in_a_im(cu_in_a_im), 
        .in_b_re(cu_in_b_re), 
        .in_b_im(cu_in_b_im), 
        
        .out_re(cu_out_re), 
        .out_im(cu_out_im)
    ); 
    
    twiddle_rom #(
        .WIDTH(WIDTH), 
        .DELAY(DELAY), 
        .ADDR_BITS(COUNTER_WIDTH),
        .MEMFILE(MEMFILE)
    ) tw_rom (
        .addr(buffer_index), 
        .tw_re(tw_re), 
        .tw_im(tw_im)
    ); 
    
endmodule
