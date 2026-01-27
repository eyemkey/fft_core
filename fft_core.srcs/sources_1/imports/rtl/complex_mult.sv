`timescale 1ns / 1ps

module complex_mult
#(parameter int WIDTH=16)
(
    input logic signed [WIDTH-1:0] in_a_re, //butterfly_unit difference 
    input logic signed [WIDTH-1:0] in_a_im, 
    input logic signed [WIDTH-1:0] in_b_re, //twiddle factor W_N^nk 
    input logic signed [WIDTH-1:0] in_b_im,
    
    
    output logic signed [WIDTH-1:0] out_re, 
    output logic signed [WIDTH-1:0] out_im
);

    localparam logic signed [2*WIDTH+1:0] SIZED_1 = (2*WIDTH+2)'(1); // for shifting (otherwise default 32b)
    localparam logic signed [WIDTH-1:0] MAX_S = { 1'b0, {(WIDTH-1){1'b1}} }; //possible max
    localparam logic signed [WIDTH-1:0] MIN_S = { 1'b1, {(WIDTH-1){1'b0}} }; //possible min
    localparam int MUL_WIDTH = 2*WIDTH-1;



    logic signed [MUL_WIDTH:0] mul_ac_full, mul_bd_full; 
    logic signed [MUL_WIDTH:0] mul_ad_full, mul_bc_full;
    logic signed [MUL_WIDTH+1:0] ac_s_ext, bd_s_ext, ad_s_ext, bc_s_ext; //sign extended ac, bd, ad, bc
    
    logic signed [MUL_WIDTH+2:0] out_re_full, out_im_full; //1 bit for carry, 1 bit for rounding

    logic signed [MUL_WIDTH+2:0] RND; //Rounding value, +0.5 for pos, -0.5 for neg
    
    
    always_comb begin
        //(a+jb) * (c+jd) = (ac-bd) + j(ad + bc)
        mul_ac_full = in_a_re * in_b_re; 
        mul_bd_full = in_a_im * in_b_im;
        mul_ad_full = in_a_re * in_b_im; 
        mul_bc_full = in_a_im * in_b_re;    
        
        //Sign extend ac, bd, ad, bc to allow carry
        ac_s_ext = {mul_ac_full[MUL_WIDTH], mul_ac_full};
        bd_s_ext = {mul_bd_full[MUL_WIDTH], mul_bd_full}; 
        ad_s_ext = {mul_ad_full[MUL_WIDTH], mul_ad_full};
        bc_s_ext = {mul_bc_full[MUL_WIDTH], mul_bc_full};
        
        //Calculate Real and Im part of output full length
        out_re_full = ac_s_ext - bd_s_ext;
        out_im_full = ad_s_ext + bc_s_ext; 
        
        //Rounding the result to bring back to WIDTH bits
        RND = (out_re_full >= 0) ? (SIZED_1 <<< (WIDTH-2)) : ( -(SIZED_1 <<< (WIDTH-2)) ); 
        out_re_full = out_re_full + RND; 
        
        RND = (out_im_full >= 0) ? (SIZED_1 <<< (WIDTH-2)) : ( -(SIZED_1 <<< (WIDTH-2)) ); 
        out_im_full = out_im_full + RND;
                
        //Droping the bits that don't matter anymore
        out_re_full = out_re_full >>> (WIDTH-1); 
        out_im_full = out_im_full >>> (WIDTH-1); 
        
        //Clamping the values to be -1 <= v < 1 (Saturation)
        if(out_re_full > MAX_S)        out_re = MAX_S; 
        else if(out_re_full < MIN_S)   out_re = MIN_S;
        else                           out_re = out_re_full[WIDTH-1:0];
        
        if(out_im_full > MAX_S)        out_im = MAX_S;
        else if(out_im_full < MIN_S)   out_im = MIN_S;
        else                           out_im = out_im_full[WIDTH-1:0];   
    end
endmodule
