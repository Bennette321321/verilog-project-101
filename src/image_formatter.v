module image_formatter(
    input wire clk,
    input wire reset_n,
    input wire [7:0] sd_data,    // Input data from SD card
    input wire sd_valid,         // SD data valid signal
    output reg [7:0] pixel_data, // Output pixel data for framebuffer
    output reg pixel_valid       // Pixel data valid signal
);

    // For RGB332 format:
    // - 3 bits for red (bits 7:5)
    // - 3 bits for green (bits 4:2)
    // - 2 bits for blue (bits 1:0)
    
    // Simple pass-through for now, assuming SD card data is already in the right format
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            pixel_data <= 8'h00;
            pixel_valid <= 0;
        end
        else begin
            pixel_valid <= sd_valid;
            
            if (sd_valid) begin
                pixel_data <= sd_data;
            end
        end
    end

endmodule