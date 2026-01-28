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
    
    
    function automatic logic signed  [WIDTH-1:0] sat_to_width (input logic signed [WIDTH:0] v); 
        logic signed [WIDTH-1:0] maxv, minv; 
        begin
            maxv = {1'b0, {(WIDTH-1){1'b1}}};
            minv = {1'b1, {(WIDTH-1){1'b0}}};
            
            if(v[WIDTH] != v[WIDTH-1]) begin
                sat_to_width = v[WIDTH] ? minv : maxv; 
            end else begin
                sat_to_width = v[WIDTH-1:0];
            end         
        
        end    
    endfunction
    
    
    always_comb begin
        sum_re_full = in_a_re + in_b_re; 
        sum_im_full = in_a_im + in_b_im; 
        
        diff_re_full = in_a_re - in_b_re; 
        diff_im_full = in_a_im - in_b_im; 
        
        //rouding     
        out_sum_re = sat_to_width(sum_re_full); // Dropping the LSB while keeping signs
        out_sum_im = sat_to_width(sum_im_full); // To keep memory usage consistent through stages
        out_diff_re = sat_to_width(diff_re_full); 
        out_diff_im = sat_to_width(diff_im_full);
    end
        
endmodule
