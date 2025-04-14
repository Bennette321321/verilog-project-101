module sd_controller(
    input wire clk,              // System clock
    input wire reset_n,          // Active low reset
    input wire start_read,       // Signal to start reading
    input wire [31:0] read_addr, // Address to read from (sector-based)
    
    // SPI interface
    output reg spi_cs,           // SD card chip select (active low)
    output reg spi_mosi,         // SD card master out slave in
    input wire spi_miso,         // SD card master in slave out
    output reg spi_sclk,         // SD card SPI clock
    
    // Data interface
    output reg [7:0] data_out,   // Data output
    output reg data_valid,       // Data valid signal
    output reg busy,             // Busy signal
    output reg read_done         // Read operation complete
);

    // SD card commands
    localparam CMD0  = 8'h40;    // GO_IDLE_STATE: Reset card
    localparam CMD8  = 8'h48;    // SEND_IF_COND: Check voltage range
    localparam CMD17 = 8'h51;    // READ_SINGLE_BLOCK: Read one block
    localparam CMD55 = 8'h77;    // APP_CMD: Prefix for ACMD
    localparam ACMD41 = 8'h69;   // SD_SEND_OP_COND: Initialize card

    // SPI clock divider (generate SPI clock from system clock)
    // SD card typically operates at max 25MHz in SPI mode
    localparam SPI_CLK_DIV = 2;  // For 100MHz system clock -> 25MHz SPI clock
    
    // State machine states
    localparam IDLE = 0;
    localparam INIT = 1;
    localparam SEND_CMD = 2;
    localparam WAIT_RESP = 3;
    localparam READ_DATA = 4;
    localparam READ_BLOCK = 5;
    localparam WAIT_BUSY = 6;
    
    // Registers for SPI communication
    reg [7:0] spi_tx_data;        // Data to transmit
    reg [7:0] spi_rx_data;        // Received data
    reg [2:0] spi_bit_counter;    // Bit counter for SPI
    reg spi_clk_en;               // SPI clock enable
    reg [3:0] spi_clk_divider;    // Clock divider counter
    
    // Registers for SD card commands
    reg [5:0] cmd_index;          // Current command index
    reg [31:0] cmd_arg;           // Command argument
    reg [7:0] cmd_crc;            // Command CRC
    reg [3:0] cmd_byte_counter;   // Byte counter for command
    
    // State registers
    reg [2:0] state;
    reg [2:0] init_state;
    reg [9:0] byte_counter;       // Counter for data bytes
    reg [9:0] block_counter;      // Counter for block bytes
    
    // Initialization success flag
    reg init_done;
    
    // Block data storage
    reg [7:0] block_data [0:511]; // SD card block (512 bytes)
    
    // Generate SPI clock
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            spi_clk_divider <= 0;
            spi_sclk <= 0;
        end
        else begin
            if (spi_clk_en) begin
                if (spi_clk_divider == SPI_CLK_DIV - 1) begin
                    spi_clk_divider <= 0;
                    spi_sclk <= ~spi_sclk;
                end
                else begin
                    spi_clk_divider <= spi_clk_divider + 1;
                end
            end
            else begin
                spi_sclk <= 0;
                spi_clk_divider <= 0;
            end
        end
    end
    
    // SPI data transmission
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            spi_mosi <= 1;
            spi_bit_counter <= 7;
            spi_rx_data <= 8'h00;
            data_valid <= 0;
        end
        else begin
            // Default state
            data_valid <= 0;
            
            // On falling edge of SPI clock
            if (spi_clk_en && spi_clk_divider == 0 && spi_sclk == 1) begin
                // Shift out MSB first
                spi_mosi <= spi_tx_data[7];
                spi_tx_data <= {spi_tx_data[6:0], 1'b1};  // Shift left and pad with 1
            end
            
            // On rising edge of SPI clock
            if (spi_clk_en && spi_clk_divider == 0 && spi_sclk == 0) begin
                // Shift in MSB first
                spi_rx_data <= {spi_rx_data[6:0], spi_miso};
                
                // If we've received 8 bits
                if (spi_bit_counter == 0) begin
                    spi_bit_counter <= 7;
                    data_valid <= 1;  // Signal that we have valid data
                end
                else begin
                    spi_bit_counter <= spi_bit_counter - 1;
                end
            end
        end
    end
    
    // Main SD card state machine
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
            init_state <= 0;
            init_done <= 0;
            busy <= 0;
            spi_cs <= 1;  // Inactive
            spi_clk_en <= 0;
            cmd_index <= 0;
            cmd_arg <= 0;
            byte_counter <= 0;
            block_counter <= 0;
            read_done <= 0;
        end
        else begin
            // Default state for control signals
            read_done <= 0;
            
            case (state)
                IDLE: begin
                    spi_cs <= 1;  // Inactive
                    spi_clk_en <= 0;
                    
                    // If not initialized and not busy, start initialization
                    if (!init_done && !busy) begin
                        state <= INIT;
                        init_state <= 0;
                        busy <= 1;
                    end
                    // If initialized and read requested, prepare to read
                    else if (init_done && start_read && !busy) begin
                        state <= SEND_CMD;
                        cmd_index <= CMD17;
                        cmd_arg <= read_addr;
                        cmd_byte_counter <= 0;
                        byte_counter <= 0;
                        busy <= 1;
                    end
                end
                
                INIT: begin
                    // SD card initialization sequence
                    case (init_state)
                        0: begin
                            // Send at least 74 clock cycles with CS high
                            spi_cs <= 1;
                            spi_clk_en <= 1;
                            spi_tx_data <= 8'hFF;
                            if (byte_counter < 10) begin  // 10 bytes = 80 clock cycles
                                if (data_valid)
                                    byte_counter <= byte_counter + 1;
                            end
                            else begin
                                byte_counter <= 0;
                                init_state <= 1;
                            end
                        end
                        
                        1: begin
                            // Send CMD0 to put SD card in SPI mode
                            spi_cs <= 0;  // Active
                            cmd_index <= CMD0;
                            cmd_arg <= 32'h00000000;
                            cmd_crc <= 8'h95;  // Fixed CRC for CMD0
                            state <= SEND_CMD;
                            init_state <= 2;
                        end
                        
                        2: begin
                            // Wait for response from CMD0
                            if (data_valid && spi_rx_data == 8'h01) begin  // R1 response
                                init_state <= 3;
                                state <= IDLE;
                            end
                            else if (byte_counter > 20) begin  // Timeout
                                init_state <= 0;  // Retry
                                state <= IDLE;
                            end
                        end
                        
                        3: begin
                            // Send CMD8 to check voltage compatibility
                            cmd_index <= CMD8;
                            cmd_arg <= 32'h000001AA;  // VHS = 1 (2.7-3.6V), check pattern = 0xAA
                            cmd_crc <= 8'h87;  // Fixed CRC for CMD8
                            state <= SEND_CMD;
                            init_state <= 4;
                        end
                        
                        4: begin
                            // Wait for response from CMD8
                            if (data_valid) begin
                                if (spi_rx_data == 8'h01) begin  // R1 response
                                    byte_counter <= 0;
                                    init_state <= 5;
                                    state <= WAIT_RESP;
                                end
                                else begin
                                    init_state <= 0;  // Card doesn't support CMD8, retry
                                    state <= IDLE;
                                end
                            end
                        end
                        
                        5: begin
                            // Read 4 bytes of R7 response
                            if (data_valid) begin
                                byte_counter <= byte_counter + 1;
                                if (byte_counter == 3) begin  // Last byte of R7
                                    init_state <= 6;
                                    state <= IDLE;
                                    byte_counter <= 0;
                                end
                            end
                        end
                        
                        6: begin
                            // Send CMD55 (prefix for ACMD commands)
                            cmd_index <= CMD55;
                            cmd_arg <= 32'h00000000;
                            cmd_crc <= 8'h65;  // CRC for CMD55
                            state <= SEND_CMD;
                            init_state <= 7;
                        end
                        
                        7: begin
                            // Wait for response from CMD55
                            if (data_valid && spi_rx_data == 8'h01) begin  // R1 response
                                init_state <= 8;
                                state <= IDLE;
                            end
                        end
                        
                        8: begin
                            // Send ACMD41 to initialize card
                            cmd_index <= ACMD41;
                            cmd_arg <= 32'h40000000;  // HCS = 1 (high capacity support)
                            cmd_crc <= 8'h77;  // CRC for ACMD41
                            state <= SEND_CMD;
                            init_state <= 9;
                        end
                        
                        9: begin
                            // Wait for response from ACMD41
                            if (data_valid) begin
                                if (spi_rx_data == 8'h00) begin  // Card is initialized
                                    init_done <= 1;
                                    busy <= 0;
                                    state <= IDLE;
                                end
                                else if (spi_rx_data == 8'h01) begin  // Not initialized yet
                                    init_state <= 6;  // Repeat CMD55+ACMD41 sequence
                                    state <= IDLE;
                                    byte_counter <= byte_counter + 1;
                                    
                                    // Timeout after 100 attempts
                                    if (byte_counter > 100) begin
                                        init_state <= 0;  // Retry from beginning
                                        state <= IDLE;
                                        byte_counter <= 0;
                                    end
                                end
                                else begin  // Error
                                    init_state <= 0;  // Retry
                                    state <= IDLE;
                                    byte_counter <= 0;
                                end
                            end
                        end
                    endcase
                end
                
                SEND_CMD: begin
                    // Enable SPI clock
                    spi_clk_en <= 1;
                    spi_cs <= 0;  // Active
                    
                    // Send command bytes
                    case (cmd_byte_counter)
                        0: begin
                            spi_tx_data <= cmd_index;  // Command index
                            if (data_valid) cmd_byte_counter <= 1;
                        end
                        1: begin
                            spi_tx_data <= cmd_arg[31:24];  // Argument byte 3
                            if (data_valid) cmd_byte_counter <= 2;
                        end
                        2: begin
                            spi_tx_data <= cmd_arg[23:16];  // Argument byte 2
                            if (data_valid) cmd_byte_counter <= 3;
                        end
                        3: begin
                            spi_tx_data <= cmd_arg[15:8];   // Argument byte 1
                            if (data_valid) cmd_byte_counter <= 4;
                        end
                        4: begin
                            spi_tx_data <= cmd_arg[7:0];    // Argument byte 0
                            if (data_valid) cmd_byte_counter <= 5;
                        end
                        5: begin
                            spi_tx_data <= cmd_crc;  // CRC
                            if (data_valid) begin
                                cmd_byte_counter <= 0;
                                state <= WAIT_RESP;
                                byte_counter <= 0;
                            end
                        end
                    endcase
                end
                
                WAIT_RESP: begin
                    // Wait for response (R1) from SD card
                    spi_tx_data <= 8'hFF;  // Send dummy bytes while waiting
                    
                    if (data_valid) begin
                            // Valid response starts with bit 7 = 0
                            if (spi_rx_data[7] == 0) begin
                                // For CMD17 (read block), move to read data state
                                if (cmd_index == CMD17) begin
                                    state <= READ_DATA;
                                    byte_counter <= 0;
                                end
                                // For initialization commands, return to INIT state
                                else if (state != INIT) begin
                                    state <= IDLE;
                                end
                            end
                            else begin
                                // If we've sent too many dummy bytes without response, timeout
                            byte_counter <= byte_counter + 1;
                            if (byte_counter > 100) begin  // Timeout
                                state <= IDLE;
                                busy <= 0;
                            end
                        end
                    end
                end
                
                READ_DATA: begin
                    // Wait for data token (0xFE) from SD card
                    spi_tx_data <= 8'hFF;  // Send dummy bytes while waiting
                    
                    if (data_valid) begin
                        if (spi_rx_data == 8'hFE) begin  // Start of data block
                            state <= READ_BLOCK;
                            block_counter <= 0;
                        end
                        else begin
                            byte_counter <= byte_counter + 1;
                            if (byte_counter > 100) begin  // Timeout
                                state <= IDLE;
                                busy <= 0;
                            end
                        end
                    end
                end
                
                READ_BLOCK: begin
                    // Read 512-byte data block
                    spi_tx_data <= 8'hFF;
                    
                    if (data_valid) begin
                        // Store received data
                        block_data[block_counter] <= spi_rx_data;
                        data_out <= spi_rx_data;
                        
                        block_counter <= block_counter + 1;
                        
                        // After reading 512 bytes
                        if (block_counter == 511) begin
                            state <= WAIT_BUSY;
                            byte_counter <= 0;
                        end
                    end
                end
                
                WAIT_BUSY: begin
                    // Read 2 CRC bytes and wait for card to finish being busy
                    spi_tx_data <= 8'hFF;
                    
                    if (data_valid) begin
                        byte_counter <= byte_counter + 1;
                        
                        if (byte_counter >= 2 && spi_rx_data == 8'hFF) begin
                            // Card is not busy anymore
                            state <= IDLE;
                            busy <= 0;
                            read_done <= 1;
                            spi_cs <= 1;  // Deselect card
                        end
                        
                        if (byte_counter > 100) begin  // Timeout
                            state <= IDLE;
                            busy <= 0;
                            spi_cs <= 1;
                        end
                    end
                end
            endcase
        end
    end

endmodule