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

    logic [63:0] data, data_next;

    logic [3:0] receive_counter, receive_counter_next;

    logic [1:0] stop_counter, stop_counter_next;

    receive_state r_state, r_next_state;

    always_ff @(posedge CLK, posedge RST) begin: next_receive_ff
        if (RST == 1'b1) begin
            r_state <= IDLE;
            
            data <= 'b0;
            receive_counter <= 'b0;

            stop_counter <= 'b0;
        end else begin
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

        case (r_state)
            IDLE: begin
                if (RX == 1'b0) begin
                    r_next_state = RECEIVE;
                    receive_counter_next = 'b0;
                end
            end
            RECEIVE: begin
                if (receive_counter < 'd7) begin // after 8 bits received
                    data_next = {RX, data[62:0]}; // TODO check endianness here!
                    r_next_state = RECEIVE;
                    receive_counter_next = receive_counter + 1;
                end else begin
                    r_next_state = CHECK;
                end
            end
            CHECK: begin
                // what do we do here?
                r_next_state = STOP;
            end
            STOP: begin
                if (stop_counter < 'd2) begin
                    r_next_state = STOP;
                    stop_counter_next = stop_counter + 1;
                end else begin
                    r_next_state = IDLE;
                end
            end
        endcase
    end

endmodule
