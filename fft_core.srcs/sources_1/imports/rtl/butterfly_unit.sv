`timescale 1ns / 1ps


module butterfly_unit #(
    parameter int WIDTH=16
)
(
    input logic signed [WIDTH-1:0] in_a_re, 
    input logic signed [WIDTH-1:0] in_a_im, 
    input logic signed [WIDTH-1:0] in_b_re, 
    input logic signed [WIDTH-1:0] in_b_im, 
    
    output logic signed [WIDTH-1:0] out_sum_re, 
    output logic signed [WIDTH-1:0] out_sum_im, 
    output logic signed [WIDTH-1:0] out_diff_re, 
    output logic signed [WIDTH-1:0] out_diff_im 
);

    logic signed [WIDTH:0] sum_re_full, sum_im_full; //Extra bit to account for carry
    logic signed [WIDTH:0] diff_re_full, diff_im_full;
    
    always_comb begin
        sum_re_full = in_a_re + in_b_re; 
        sum_im_full = in_a_im + in_b_im; 
        
        diff_re_full = in_a_re - in_b_re; 
        diff_im_full = in_a_im - in_b_im; 
        
        out_sum_re = sum_re_full >>> 1; // Dropping the LSB while keeping signs
        out_sum_im = sum_im_full >>> 1; // To keep memory usage consistent through stages
        out_diff_re = diff_re_full >>> 1; 
        out_diff_im = diff_im_full >>> 1;
    end
        
endmodule
