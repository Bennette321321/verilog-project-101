module frame_buffer(
    input wire clk,                 // System clock
    input wire we,                  // Write enable
    input wire [16:0] read_addr,    // Read address (320x240 = 76,800 addresses needed)
    input wire [16:0] write_addr,   // Write address
    input wire [15:0] write_data,   // Write data (16-bit RGB565 format)
    output reg [15:0] read_data     // Read data (16-bit RGB565 format)
);

    // Memory array for 320x240 image, 16-bit color depth (RGB565)
    // This uses BRAM resources on the FPGA
    reg [15:0] buffer [0:76799];  // 320 * 240 = 76,800 pixels
    
    // Write operation
    always @(posedge clk) begin
        if (we) begin
            buffer[write_addr] <= write_data;
        end
    end
    
    // Read operation
    always @(posedge clk) begin
        read_data <= buffer[read_addr];
    end

endmodule