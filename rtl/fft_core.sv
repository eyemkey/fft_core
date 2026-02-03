`timescale 1ns / 1ps


module fft_core 
#(
    parameter int N = 1024,
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
    
    localparam int STAGES = $clog2(N); 
    
    logic signed [WIDTH-1:0] st_re [0:STAGES]; 
    logic signed [WIDTH-1:0] st_im [0:STAGES];
    logic st_valid [0:STAGES];
    
    assign st_re[0] = in_re; 
    assign st_im[0] = in_im; 
    assign st_valid[0] = in_valid;
    
    function automatic string stage_memfile (int idx);
    case (idx)
        0:  stage_memfile = "stage0.mem";
        1:  stage_memfile = "stage1.mem";
        2:  stage_memfile = "stage2.mem";
        3:  stage_memfile = "stage3.mem";
        4:  stage_memfile = "stage4.mem";
        5:  stage_memfile = "stage5.mem";
        6:  stage_memfile = "stage6.mem";
        7:  stage_memfile = "stage7.mem";
        8:  stage_memfile = "stage8.mem";
        9:  stage_memfile = "stage9.mem";
        10: stage_memfile = "stage10.mem";
        11: stage_memfile = "stage11.mem";
        12: stage_memfile = "stage12.mem";
        13: stage_memfile = "stage13.mem";
        14: stage_memfile = "stage14.mem";
        default: stage_memfile = "stage0.mem";
    endcase
endfunction
    
    
    genvar s;
    generate
        for(s = 0; s < STAGES; s++) begin : GEN_STAGES
            localparam int DELAY = (N >> (s+1));
            localparam string MEMFILE = stage_memfile(s);
            
            stage #(
                .DELAY(DELAY), 
                .WIDTH(WIDTH), 
                .MEMFILE(MEMFILE)
            ) u_stage (
                .clk(clk), 
                .rst_n(rst_n), 
                
                .in_re(st_re[s]), 
                .in_im(st_im[s]), 
                .in_valid(st_valid[s]),
                
                .out_re(st_re[s+1]),
                .out_im(st_im[s+1]),
                .out_valid(st_valid[s+1])
            );
        end    
    endgenerate 


    reorder_buffer #(
        .N(N), 
        .WIDTH(WIDTH)
    ) u_reorder (
        .clk(clk), 
        .rst_n(rst_n),
        
        .in_re(st_re[STAGES]), 
        .in_im(st_im[STAGES]), 
        .in_valid(st_valid[STAGES]), 
        
        .out_re(out_re), 
        .out_im(out_im), 
        .out_valid(out_valid)
    );

endmodule
