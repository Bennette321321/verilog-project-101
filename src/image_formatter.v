module image_formatter(
    input wire clk,
    input wire reset_n,
    input wire [7:0] sd_data,        // Input data from SD card
    input wire sd_valid,             // SD data valid signal
    input wire byte_counter,         // Input to determine odd/even byte position
    output reg [15:0] pixel_data,    // Output pixel data for framebuffer (RGB565 format)
    output reg pixel_valid           // Pixel data valid signal
);

    // State machine for converting from raw bytes to pixels
    localparam STATE_IDLE = 0;
    localparam STATE_READ_R = 1;     // Read red component
    localparam STATE_READ_G = 2;     // Read green component
    localparam STATE_READ_B = 3;     // Read blue component
    
    reg [1:0] state;
    reg [7:0] r_byte, g_byte, b_byte;
    reg [15:0] rgb565_data;
    
    // Convert from 24-bit RGB888 to 16-bit RGB565 format
    function [15:0] rgb888_to_rgb565;
        input [7:0] r, g, b;
        begin
            // 5 bits for red, 6 bits for green, 5 bits for blue
            rgb888_to_rgb565 = {r[7:3], g[7:2], b[7:3]};
        end
    endfunction
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= STATE_IDLE;
            pixel_data <= 16'h0000;
            pixel_valid <= 0;
            r_byte <= 0;
            g_byte <= 0;
            b_byte <= 0;
        end
        else begin
            // Default values
            pixel_valid <= 0;
            
            case (state)
                STATE_IDLE: begin
                    if (sd_valid) begin
                        r_byte <= sd_data;
                        state <= STATE_READ_G;
                    end
                end
                
                STATE_READ_G: begin
                    if (sd_valid) begin
                        g_byte <= sd_data;
                        state <= STATE_READ_B;
                    end
                end
                
                STATE_READ_B: begin
                    if (sd_valid) begin
                        b_byte <= sd_data;
                        
                        // Convert RGB888 to RGB565
                        rgb565_data <= rgb888_to_rgb565(r_byte, g_byte, sd_data);
                        pixel_data <= rgb888_to_rgb565(r_byte, g_byte, sd_data);
                        pixel_valid <= 1;
                        
                        // Back to start for next pixel
                        state <= STATE_IDLE;
                    end
                end
            endcase
        end
    end

endmodule