module uart (
    input clk,
    input rst,
    input tx_en,
    input [7:0] tx_data,
    input rx,
    output reg tx,
    output reg [7:0] rx_data,
    output reg tx_done,
    output reg rx_done
);

parameter DATA_WIDTH = 8;
parameter PARITY_ENABLE = 1; // 0 for no parity, 1 for parity
parameter PARITY_TYPE = 0;   // 0 for even, 1 for odd parity
parameter CLK_FREQ = 50000000; // 50 MHz clock frequency
parameter BAUD_RATE = 9600;    // 9600 baud rate

// State definitions
parameter IDLE    = 4'd0,
          START   = 4'd1,
          DATA    = 4'd2,
          PARITY  = 4'd3,
          STOP    = 4'd4,
          CLEANUP = 4'd5;

reg [3:0] state;
reg [DATA_WIDTH-1:0] data_reg;
reg baud_tick;
reg [31:0] baud_cnt;
reg [2:0] bit_cnt;
reg parity;

// Baud rate generator
always @(posedge clk) begin
    if (rst) begin
        baud_cnt <= 0;
        baud_tick <= 0;
    end else begin
        if (baud_cnt >= (CLK_FREQ / BAUD_RATE)) begin
            baud_cnt <= 0;
            baud_tick <= 1;
        end else begin
            baud_cnt <= baud_cnt + 1;
            baud_tick <= 0;
        end
    end
end

// FSM for transmission
always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        tx <= 1; // high for idle
        tx_done <= 0;
        bit_cnt <= 0;
    end else begin
        case(state)
            IDLE: begin
                if (tx_en) begin
                    data_reg <= tx_data;
                    state <= START;
                    tx <= 0; // start bit
                    tx_done <= 0;
                end else begin
                    tx <= 1;
                end
            end
            START: begin
                if (baud_tick) begin
                    state <= DATA;
                end
            end
            DATA: begin
                if (baud_tick) begin
                    tx <= data_reg[0];
                    data_reg <= {1'b0, data_reg[7:1]}; // shift right
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == DATA_WIDTH-1) begin
                        if (PARITY_ENABLE) begin
                            state <= PARITY;
                        end else begin
                            state <= STOP;
                        end
                    end
                end
            end
            PARITY: begin
                if (baud_tick) begin
                    tx <= (PARITY_TYPE == 0) ? ^data_reg : ~^data_reg; // even or odd parity
                    state <= STOP;
                end
            end
            STOP: begin
                if (baud_tick) begin
                    tx <= 1; // stop bit
                    state <= CLEANUP;
                end
            end
            CLEANUP: begin
                if (baud_tick) begin
                    state <= IDLE;
                    tx_done <= 1;
                    bit_cnt <= 0;
                end
            end
            default: begin
                state <= IDLE;
            end
        endcase
    end
end

// FSM for reception
always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        rx_data <= 0;
        rx_done <= 0;
        bit_cnt <= 0;
    end else begin
        case(state)
            IDLE: begin
                if (rx == 0) begin // Start bit detected
                    state <= START;
                end
            end
            START: begin
                if (baud_tick) begin
                    state <= DATA;
                end
            end
            DATA: begin
                if (baud_tick) begin
                    rx_data <= {rx, rx_data[7:1]}; // shift right
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == DATA_WIDTH-1) begin
                        if (PARITY_ENABLE) begin
                            state <= PARITY;
                        end else begin
                            state <= STOP;
                        end
                    end
                end
            end
            PARITY: begin
                if (baud_tick) begin
                    parity <= ^rx_data;
                    if ((PARITY_TYPE == 0 && parity != rx) || (PARITY_TYPE == 1 && parity == rx)) begin
                        state <= IDLE; // Parity error, go back to IDLE
                    end else begin
                        state <= STOP;
                    end
                end
            end
            STOP: begin
                if (baud_tick) begin
                    if (rx == 1) begin // valid stop bit
                        state <= CLEANUP;
                    end else begin
                        state <= IDLE; // invalid stop bit, go back to IDLE
                    end
                end
            end
            CLEANUP: begin
                if (baud_tick) begin
                    state <= IDLE;
                    rx_done <= 1;
                    bit_cnt <= 0;
                end
            end
            default: begin
                state <= IDLE;
            end
        endcase
    end
end

endmodule