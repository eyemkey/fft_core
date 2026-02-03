`timescale 1ns / 1ps

module reorder_buffer 
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
    
    parameter int LOGN = $clog2(N);
    
    logic signed [WIDTH-1:0] mem_re [0:N-1];
    logic signed [WIDTH-1:0] mem_im [0:N-1];
    
    typedef enum logic [1:0] {FILL, DRAIN} state_t; 
    state_t state; 
    
    logic [LOGN-1:0] wr_cnt, rd_cnt; 
    
    function automatic [LOGN-1:0] bitrev(input [LOGN-1:0] x); 
        integer i; 
        begin
            for(i = 0; i < LOGN; i++) bitrev[i] = x[LOGN-1-i];
        end
    endfunction
    
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            integer i; 
            for(i = 0; i < N; i=i+1) begin
                mem_re[i] <= 0; 
                mem_im[i] <= 0; 
            end
                    
                
            state <= FILL; 
            wr_cnt <= 0; 
            rd_cnt <= 0; 
            out_valid <= 1'b0; 
            out_re <= 0; 
            out_im <= 0; 
        end
        else begin
            case(state)
                FILL: begin
                    out_valid <= 1'b0;
                    if(in_valid) begin
                        mem_re[bitrev(wr_cnt)] <= in_re; 
                        mem_im[bitrev(wr_cnt)] <= in_im; 
                        
                        if(wr_cnt == N-1) begin
                            wr_cnt <= 0; 
                            rd_cnt <= 0; 
                            state <= DRAIN; 
                        end else wr_cnt <= wr_cnt + 1; 
                    end
                end
                
                DRAIN: begin
                    out_re <= mem_re[rd_cnt]; 
                    out_im <= mem_im[rd_cnt]; 
                    out_valid <= 1'b1; 
                    
                    if(rd_cnt == N-1) begin
                        rd_cnt <= 0; 
                        state <= FILL;
                    end else rd_cnt <= rd_cnt + 1;
                end            
            endcase
        end
    end

endmodule
