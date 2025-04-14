module frame_buffer(
    input wire clk,                 // System clock
    input wire we,                  // Write enable
    input wire [16:0] read_addr,    // Read address (320x240 = 76,800 addresses needed)
    input wire [16:0] write_addr,   // Write address
    input wire [7:0] write_data,    // Write data
    output reg [7:0] read_data      // Read data
);

    // Memory array for 320x240 image, 8-bit color depth
    // This uses BRAM resources on the FPGA
    reg [7:0] buffer [0:76799];  // 320 * 240 = 76,800 pixels
    
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