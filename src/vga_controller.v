module vga_controller(
    input wire clk_25mhz,      // 25MHz pixel clock
    input wire reset_n,        // Active low reset
    output wire hsync,         // Horizontal sync
    output wire vsync,         // Vertical sync
    output wire video_on,      // Video active region
    output wire [9:0] pixel_x, // Current pixel X coordinate
    output wire [9:0] pixel_y, // Current pixel Y coordinate
    output wire pixel_tick     // Pixel clock tick
);
    
    // VGA 640x480 parameters for 25MHz pixel clock
    // Display region is 320x240 centered in a 640x480 area
    
    // Horizontal timing (in pixels)
    parameter H_DISPLAY       = 640;
    parameter H_BACK_PORCH    = 48;
    parameter H_FRONT_PORCH   = 16;
    parameter H_SYNC_PULSE    = 96;
    parameter H_MAX           = H_DISPLAY + H_BACK_PORCH + H_FRONT_PORCH + H_SYNC_PULSE - 1;
    
    // Vertical timing (in lines)
    parameter V_DISPLAY       = 480;
    parameter V_BACK_PORCH    = 33;
    parameter V_FRONT_PORCH   = 10;
    parameter V_SYNC_PULSE    = 2;
    parameter V_MAX           = V_DISPLAY + V_BACK_PORCH + V_FRONT_PORCH + V_SYNC_PULSE - 1;
    
    // Active display region calculations for 320x240 centered in 640x480
    parameter H_DISPLAY_START = (H_DISPLAY - 320) / 2 + H_SYNC_PULSE + H_BACK_PORCH;
    parameter H_DISPLAY_END   = H_DISPLAY_START + 320 - 1;
    parameter V_DISPLAY_START = (V_DISPLAY - 240) / 2 + V_SYNC_PULSE + V_BACK_PORCH;
    parameter V_DISPLAY_END   = V_DISPLAY_START + 240 - 1;
    
    // Sync pulse starts
    parameter H_SYNC_START    = H_DISPLAY + H_FRONT_PORCH;
    parameter H_SYNC_END      = H_SYNC_START + H_SYNC_PULSE - 1;
    parameter V_SYNC_START    = V_DISPLAY + V_FRONT_PORCH;
    parameter V_SYNC_END      = V_SYNC_START + V_SYNC_PULSE - 1;
    
    // Counters for pixel position
    reg [9:0] h_count, v_count;
    
    // Horizontal and vertical sync generation
    wire h_sync, v_sync;
    
    // Pixel position valid flags
    wire h_valid, v_valid;
    
    // Counter for horizontal position
    always @(posedge clk_25mhz or negedge reset_n) begin
        if (!reset_n) begin
            h_count <= 0;
        end
        else begin
            if (h_count == H_MAX) begin
                h_count <= 0;
            end
            else begin
                h_count <= h_count + 1;
            end
        end
    end
    
    // Counter for vertical position
    always @(posedge clk_25mhz or negedge reset_n) begin
        if (!reset_n) begin
            v_count <= 0;
        end
        else begin
            if (h_count == H_MAX) begin
                if (v_count == V_MAX) begin
                    v_count <= 0;
                end
                else begin
                    v_count <= v_count + 1;
                end
            end
        end
    end
    
    // Generate horizontal sync signal
    assign h_sync = ~((h_count >= H_SYNC_START) && (h_count <= H_SYNC_END));
    
    // Generate vertical sync signal
    assign v_sync = ~((v_count >= V_SYNC_START) && (v_count <= V_SYNC_END));
    
    // Check if current pixel is within display area (320x240 centered)
    assign h_valid = (h_count >= H_DISPLAY_START) && (h_count <= H_DISPLAY_END);
    assign v_valid = (v_count >= V_DISPLAY_START) && (v_count <= V_DISPLAY_END);
    assign video_on = h_valid && v_valid;
    
    // Generate pixel coordinates (0-319, 0-239)
    assign pixel_x = h_valid ? (h_count - H_DISPLAY_START) : 0;
    assign pixel_y = v_valid ? (v_count - V_DISPLAY_START) : 0;
    
    // Output signals
    assign hsync = h_sync;
    assign vsync = v_sync;
    assign pixel_tick = 1'b1;  // Always on with 25MHz clock

endmodule