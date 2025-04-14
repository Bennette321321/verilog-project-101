module clock_generator(
    input wire clk_in,          // 100MHz input clock
    input wire reset_n,         // Active low reset
    output wire clk_25mhz       // 25MHz output clock
);

    // Using Clock Wizard IP is recommended for proper clock generation
    // For this implementation, we'll use a counter-based approach
    // Note: In a real implementation, you should use the Xilinx Clock Wizard IP
    
    reg [1:0] count;
    reg clk_div;
    
    always @(posedge clk_in or negedge reset_n) begin
        if (!reset_n) begin
            count <= 2'b00;
            clk_div <= 0;
        end
        else begin
            if (count == 2'b01) begin
                count <= 2'b00;
                clk_div <= ~clk_div;
            end
            else begin
                count <= count + 1'b1;
            end
        end
    end
    
    assign clk_25mhz = clk_div;

endmodule