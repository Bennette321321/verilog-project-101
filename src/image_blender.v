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
    
    // Convert to larger bit width for calculations
    reg [12:0] r_a_ext, r_b_ext;
    reg [13:0] g_a_ext, g_b_ext;
    reg [12:0] b_a_ext, b_b_ext;
    
    // Results for blended components
    reg [12:0] r_blended_ext;
    reg [13:0] g_blended_ext;
    reg [12:0] b_blended_ext;
    
    reg [4:0] r_blended;
    reg [5:0] g_blended;
    reg [4:0] b_blended;
    
    // Pipeline stage 1: Extend bit widths and multiply
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            r_a_ext <= 0;
            r_b_ext <= 0;
            g_a_ext <= 0;
            g_b_ext <= 0;
            b_a_ext <= 0;
            b_b_ext <= 0;
        end
        else begin
            // Extend to larger bit width and multiply by blend factors
            r_a_ext <= r_a * (255 - blend_factor);
            r_b_ext <= r_b * blend_factor;
            
            g_a_ext <= g_a * (255 - blend_factor);
            g_b_ext <= g_b * blend_factor;
            
            b_a_ext <= b_a * (255 - blend_factor);
            b_b_ext <= b_b * blend_factor;
        end
    end
    
    // Pipeline stage 2: Add components and divide by 255
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            r_blended_ext <= 0;
            g_blended_ext <= 0;
            b_blended_ext <= 0;
        end
        else begin
            r_blended_ext <= (r_a_ext + r_b_ext) / 255;
            g_blended_ext <= (g_a_ext + g_b_ext) / 255;
            b_blended_ext <= (b_a_ext + b_b_ext) / 255;
        end
    end
    
    // Pipeline stage 3: Convert back to RGB565 format components
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            r_blended <= 0;
            g_blended <= 0;
            b_blended <= 0;
        end
        else begin
            // Clamp to bit width
            r_blended <= (r_blended_ext > 31) ? 5'd31 : r_blended_ext[4:0];
            g_blended <= (g_blended_ext > 63) ? 6'd63 : g_blended_ext[5:0];
            b_blended <= (b_blended_ext > 31) ? 5'd31 : b_blended_ext[4:0];
        end
    end
    
    // Final stage: Combine components into RGB565 format
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            blended_output <= 0;
        end
        else begin
            blended_output <= {r_blended, g_blended, b_blended};
        end
    end

endmodule