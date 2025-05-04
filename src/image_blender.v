module image_blender(
    input wire clk,                // System clock
    input wire reset_n,            // Active low reset
    input wire [15:0] image_a,     // First image pixel (RGB565 format)
    input wire [15:0] image_b,     // Second image pixel (RGB565 format)
    input wire [7:0] blend_factor, // Blend factor (0-255, 0 = full image_a, 255 = full image_b)
    output reg [15:0] blended_output // Blended output pixel (RGB565 format)
);

    // Extract RGB components from RGB565 format
    // RGB565: [R4:R0, G5:G0, B4:B0]
    wire [4:0] r_a, r_b;
    wire [5:0] g_a, g_b;
    wire [4:0] b_a, b_b;
    
    assign r_a = image_a[15:11];
    assign g_a = image_a[10:5];
    assign b_a = image_a[4:0];
    
    assign r_b = image_b[15:11];
    assign g_b = image_b[10:5];
    assign b_b = image_b[4:0];
    
    // Temporary values for intermediate calculations
    reg [12:0] r_temp, g_temp, b_temp;
    reg [4:0] r_blended;
    reg [5:0] g_blended;
    reg [4:0] b_blended;
    
    // Perform alpha blending calculation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            r_temp <= 0;
            g_temp <= 0;
            b_temp <= 0;
            r_blended <= 0;
            g_blended <= 0;
            b_blended <= 0;
            blended_output <= 0;
        end
        else begin
            // Linear interpolation: output = (1-alpha)*A + alpha*B
            // Where alpha = blend_factor/255
            
            // Calculate red component
            r_temp <= (r_a * (255 - blend_factor) + r_b * blend_factor) / 255;
            r_blended <= r_temp[4:0];
            
            // Calculate green component
            g_temp <= (g_a * (255 - blend_factor) + g_b * blend_factor) / 255;
            g_blended <= g_temp[5:0];
            
            // Calculate blue component
            b_temp <= (b_a * (255 - blend_factor) + b_b * blend_factor) / 255;
            b_blended <= b_temp[4:0];
            
            // Combine components back to RGB565 format
            blended_output <= {r_blended, g_blended, b_blended};
        end
    end

endmodule