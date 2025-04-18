module fpga_image_display(
    input wire clk,                  // 100MHz system clock
    input wire reset_n,              // Active low reset
    
    // Buttons for control
    input wire btn_next,             // Button to switch to next image
    
    // SD Card SPI Interface
    output wire sd_cs,               // SD card chip select
    output wire sd_mosi,             // SD card MOSI
    input wire sd_miso,              // SD card MISO
    output wire sd_sclk,             // SD card SCLK
    
    // VGA Interface
    output wire vga_hsync,           // VGA horizontal sync
    output wire vga_vsync,           // VGA vertical sync
    output wire [3:0] vga_r,         // VGA red channel
    output wire [3:0] vga_g,         // VGA green channel
    output wire [3:0] vga_b          // VGA blue channel
);

    // Clock generation
    wire clk_25mhz;                  // 25MHz clock for VGA
    
    // State machine states
    localparam STATE_INIT_SD = 0;
    localparam STATE_READ_IMAGE = 1;
    localparam STATE_DISPLAY = 2;
    localparam STATE_SWITCH_IMAGE = 3;
    
    reg [1:0] state;
    reg [1:0] next_state;
    
    // Image-related signals
    reg [7:0] image_index;           // Current image index
    reg image_load_done;             // Flag for image loading completion
    
    // VGA control signals
    wire vga_pixel_tick;             // Pixel clock tick
    wire [9:0] pixel_x, pixel_y;     // Current pixel coordinates
    wire video_on;                   // Video active region
    
    // Memory interface signals
    wire [15:0] pixel_data;          // Pixel data from memory (RGB565 format)
    reg [16:0] pixel_addr;           // Address for framebuffer
    
    // Button debouncing
    wire btn_next_debounced;
    
    // SD card control and status signals
    reg sd_start_read;              // Start reading from SD card
    wire sd_busy;                   // SD card busy signal
    wire sd_read_done;              // Read operation complete
    reg [31:0] sd_read_addr;        // Address to read from SD card
    wire [7:0] sd_read_data;        // Data read from SD card
    wire sd_valid;                  // Data valid signal
    
    // Data formatter signals
    wire [15:0] formatted_data;      // Formatted RGB565 data
    wire formatted_valid;            // Formatted data valid
    reg [17:0] write_byte_counter;   // Count bytes being written to framebuffer
    
    // Clock generation module
    clock_generator clock_gen (
        .clk_in(clk),               // 100MHz input
        .reset_n(reset_n),
        .clk_25mhz(clk_25mhz)       // 25MHz output for VGA
    );
    
    // Button debouncer
    debouncer btn_next_deb (
        .clk(clk),
        .reset_n(reset_n),
        .btn_in(btn_next),
        .btn_out(btn_next_debounced)
    );
    
    // VGA controller module
    vga_controller vga_ctrl (
        .clk_25mhz(clk_25mhz),
        .reset_n(reset_n),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .video_on(video_on),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .pixel_tick(vga_pixel_tick)
    );
    
    // Image formatter - convert 8-bit SD data to 16-bit RGB565
    image_formatter img_fmt (
        .clk(clk),
        .reset_n(reset_n),
        .sd_data(sd_read_data),
        .sd_valid(sd_valid),
        .byte_counter(write_byte_counter[0]),  // Odd/even byte
        .pixel_data(formatted_data),
        .pixel_valid(formatted_valid)
    );
    
    // Frame buffer (dual-port RAM) for RGB565 format
    frame_buffer frame_buf (
        .clk(clk),
        .we(formatted_valid),             // Write enable during formatted data valid
        .read_addr(pixel_addr),           // Read address for VGA display
        .write_addr(write_byte_counter[17:1]), // Write address (divide by 2 for 16-bit data)
        .write_data(formatted_data),      // 16-bit RGB565 data
        .read_data(pixel_data)            // 16-bit data to VGA display
    );
    
    // SD card controller
    sd_controller sd_ctrl (
        .clk(clk),
        .reset_n(reset_n),
        .start_read(sd_start_read),
        .read_addr(sd_read_addr),
        .spi_cs(sd_cs),
        .spi_mosi(sd_mosi),
        .spi_miso(sd_miso),
        .spi_sclk(sd_sclk),
        .data_out(sd_read_data),
        .data_valid(sd_valid),
        .busy(sd_busy),
        .read_done(sd_read_done)
    );
    
    // State machine for controlling operation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= STATE_INIT_SD;
            image_index <= 0;
            sd_start_read <= 0;
            image_load_done <= 0;
            write_byte_counter <= 0;
        end else begin
            state <= next_state;
            
            // Track SD read data bytes
            if (sd_valid && state == STATE_READ_IMAGE) begin
                write_byte_counter <= write_byte_counter + 1;
                
                // Mark image as loaded after reading full image
                // 320x240 pixels × 2 bytes/pixel = 153,600 bytes
                if (write_byte_counter == 153599) begin
                    image_load_done <= 1;
                end
            end
            
            // Handle button press for image switching
            if (state == STATE_DISPLAY && btn_next_debounced) begin
                image_index <= image_index + 1;
                image_load_done <= 0;
                write_byte_counter <= 0;
            end
            
            // Control SD card read operation
            if (state == STATE_READ_IMAGE && !sd_busy && !image_load_done) begin
                sd_start_read <= 1;
            end else begin
                sd_start_read <= 0;
            end
            
            // Reset byte counter when starting a new read
            if (state == STATE_SWITCH_IMAGE) begin
                write_byte_counter <= 0;
            end
        end
    end
    
    // State transition logic
    always @(*) begin
        next_state = state;
        
        case (state)
            STATE_INIT_SD: begin
                if (!sd_busy) next_state = STATE_READ_IMAGE;
            end
            
            STATE_READ_IMAGE: begin
                if (image_load_done) next_state = STATE_DISPLAY;
            end
            
            STATE_DISPLAY: begin
                if (btn_next_debounced) next_state = STATE_SWITCH_IMAGE;
            end
            
            STATE_SWITCH_IMAGE: begin
                next_state = STATE_READ_IMAGE;
            end
        endcase
    end
    
    // Calculate SD card read address based on image index
    always @(*) begin
        // Each 320x240 RGB565 image occupies 320*240*2 = 153,600 bytes
        // Add offset for image header/metadata if needed
        sd_read_addr = image_index * 153600;
    end
    
    // Calculate pixel address for reading from frame buffer
    always @(*) begin
        pixel_addr = pixel_y * 320 + pixel_x;
    end
    
    // RGB data output - convert from 16-bit RGB565 format to 4-bit per channel
    // RGB565: [R4:R0,G5:G0,B4:B0]
    assign vga_r = video_on ? {pixel_data[15:12]} : 4'b0000;
    assign vga_g = video_on ? {pixel_data[10:7]} : 4'b0000;  // Take upper 4 bits of green
    assign vga_b = video_on ? {pixel_data[4:1]} : 4'b0000;   // Take upper 4 bits of blue

endmodule