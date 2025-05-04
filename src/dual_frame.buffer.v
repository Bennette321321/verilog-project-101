module dual_frame_buffer(
    input wire clk,                 // System clock
    input wire we,                  // Write enable
    input wire buffer_select,       // Select which buffer to write to (0=A, 1=B)
    input wire display_mode,        // 0=single buffer, 1=blend mode
    input wire [16:0] read_addr,    // Read address (320x240 = 76,800 addresses needed)
    input wire [16:0] write_addr,   // Write address
    input wire [15:0] write_data,   // Write data (16-bit RGB565 format)
    input wire [7:0] blend_factor,  // Blend factor for transition (0-255)
    output wire [15:0] read_data_a, // Read data from buffer A
    output wire [15:0] read_data_b, // Read data from buffer B
    output wire [15:0] read_data    // Final output read data (selected or blended)
);

    // Two memory arrays for 320x240 image, 16-bit color depth (RGB565)
    // This uses BRAM resources on the FPGA
    reg [15:0] buffer_a [0:76799];  // 320 * 240 = 76,800 pixels
    reg [15:0] buffer_b [0:76799];  // 320 * 240 = 76,800 pixels
    
    reg [15:0] data_a, data_b;
    
    // Write operation
    always @(posedge clk) begin
        if (we) begin
            if (buffer_select == 0) begin
                buffer_a[write_addr] <= write_data;
            end
            else begin
                buffer_b[write_addr] <= write_data;
            end
        end
    end
    
    // Read operation
    always @(posedge clk) begin
        data_a <= buffer_a[read_addr];
        data_b <= buffer_b[read_addr];
    end
    
    assign read_data_a = data_a;
    assign read_data_b = data_b;
    
    // Image blender instantiation
    image_blender blender(
        .clk(clk),
        .reset_n(1'b1),
        .image_a(data_a),
        .image_b(data_b),
        .blend_factor(blend_factor),
        .blended_output(blended_output)
    );
    
    // Output selection based on display mode
    wire [15:0] blended_output;
    assign read_data = display_mode ? blended_output : (buffer_select ? data_b : data_a);

endmodule