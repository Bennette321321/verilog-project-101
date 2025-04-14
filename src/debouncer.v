module debouncer(
    input wire clk,        // System clock
    input wire reset_n,    // Active low reset
    input wire btn_in,     // Raw button input
    output reg btn_out     // Debounced button output
);

    // Parameters for debouncing
    parameter DEBOUNCE_DELAY = 1000000;  // 10ms at 100MHz
    
    reg [19:0] counter;
    reg btn_state;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 0;
            btn_state <= 0;
            btn_out <= 0;
        end
        else begin
            // If button state is different from current state
            if (btn_in != btn_state) begin
                // Reset counter
                counter <= 0;
                btn_state <= btn_in;
            end
            // If button state is stable
            else if (counter < DEBOUNCE_DELAY) begin
                counter <= counter + 1;
            end
            // Once debounce delay is reached, update output
            else begin
                btn_out <= btn_state;
            end
        end
    end

endmodule