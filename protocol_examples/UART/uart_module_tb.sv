 // agreed upon baud rate = 9600
 // agreed upon 8 bits of data
 // agreed upon 1 parity bit 
 // agreed upon 2 stop bits


`timescale 1ns/1ps

module uart_module_tb;

    localparam CLK_PERIOD      = 10;
    localparam real BAUD       = 9600;
    localparam real BIT_PERIOD = 1_000_000_000.0 / BAUD; // ~104167 ns per bit

    initial begin
        $dumpfile("uart_module_tb.vcd");
        $dumpvars(0, uart_module_tb);
    end

    logic CLK, RST, TX, RX;

    uart_module u_uart_module (
        .CLK(CLK),
        .RST(RST),
        .TX(RX),
        .RX(TX)
    );

    task send_uart_byte(input [7:0] data);
        integer i;
        logic parity;
        begin
            parity = ^data; // even parity

            TX = 0; // start bit
            #BIT_PERIOD;

            for (i = 0; i < 8; i++) begin
                TX = data[i];
                #BIT_PERIOD;
            end

            TX = parity;
            #BIT_PERIOD;

            TX = 1; // stop bit 1
            #BIT_PERIOD;
            TX = 1; // stop bit 2
            #BIT_PERIOD;
        end
    endtask

    always #(CLK_PERIOD/2) CLK = ~CLK;

    initial begin
        CLK = 0;
        RST = 1;
        TX  = 1; // idle high

        #10;
        RST = 0; // reset DUT
        #10;

        send_uart_byte(8'hA5);
        send_uart_byte(8'h47);
        send_uart_byte(8'h80);
        send_uart_byte(8'hF0);
        send_uart_byte(8'h01);
        send_uart_byte(8'h2F);
        send_uart_byte(8'hA2);
        send_uart_byte(8'hC1);
        send_uart_byte(8'h64);

        #(BIT_PERIOD * 2);



        $finish;
    end

endmodule
