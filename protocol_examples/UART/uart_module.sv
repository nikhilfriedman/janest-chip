 // agreed upon baud rate = 9600
 // agreed upon 8 bits of data
 // agreed upon 1 parity bit 
 // agreed upon 2 stop bits
 
 module uart_module (
    input logic CLK,
    input logic RST,

    output logic TX,
    input logic RX
);

    typedef enum logic [1:0] {
        IDLE,
        RECEIVE,
        CHECK,
        STOP
    } receive_state;

    localparam int CLK_FREQ_HZ = 100_000_000;      // 100 MHz, i.e. 10ns period
    localparam int BAUD        = 9600;
    localparam int CYCLES_PER_BIT = CLK_FREQ_HZ / BAUD;  // ≈ 10417

    logic [$clog2(CYCLES_PER_BIT)-1:0] baud_counter, baud_counter_next;
    logic bit_tick; // pulses high for one clk cycle, once per bit period

    logic [63:0] data, data_next;

    logic [3:0] receive_counter, receive_counter_next;

    logic [1:0] stop_counter, stop_counter_next;

    receive_state r_state, r_next_state;

    always_ff @(posedge CLK, posedge RST) begin: next_receive_ff
        if (RST == 1'b1) begin
            baud_counter <= 'b0;

            r_state <= IDLE;
            
            data <= 'b0;
            receive_counter <= 'b0;

            stop_counter <= 'b0;
        end else begin
            baud_counter <= baud_counter_next;

            r_state <= r_next_state;
            data <= data_next;
            receive_counter <= receive_counter_next;
            stop_counter <= stop_counter_next;
        end
    end

    always_comb begin: next_receive_state
        r_next_state = r_state;
        data_next = data;
        receive_counter_next = receive_counter;
        stop_counter_next = stop_counter;

        if (baud_counter == CYCLES_PER_BIT - 1) begin
            baud_counter_next = '0;
            bit_tick = 1'b1;
        end else begin
            baud_counter_next = baud_counter + 1;
            bit_tick = 1'b0;
        end

        case (r_state)
            IDLE: begin
                if (RX == 1'b0) begin
                    r_next_state = RECEIVE;
                    receive_counter_next = '0;
                    baud_counter_next = '0; // resync to the edge
                end
            end

            RECEIVE: begin
                if (bit_tick) begin
                    if (receive_counter < 8) begin
                        data_next = {RX, data[7:1]};
                        receive_counter_next = receive_counter + 1;
                    end
                    if (receive_counter == 7) r_next_state = CHECK;
                end
            end

            CHECK: begin
                if (bit_tick) begin
                    r_next_state = STOP;
                end
            end

            STOP: begin
                if (bit_tick) begin
                    if (stop_counter < 1) begin  // 2 stop bits total, counting 0 and 1
                        stop_counter_next = stop_counter + 1;
                    end else begin
                        r_next_state = IDLE;
                        stop_counter_next = '0;
                    end
                end
            end
        endcase
    end

endmodule
