module spi_master #(
    parameter CLK_DIV = 4
)(
    input  logic       clk,
    input  logic       rst,

    input  logic       start,
    input  logic [7:0] tx_data,

    output logic [7:0] rx_data,
    output logic       busy,
    output logic       done,

    output logic       spi_cs,
    output logic       spi_sclk,
    output logic       spi_mosi,

    input  logic       spi_miso
);

    typedef enum logic [1:0] {
        IDLE,
        TRANSFER,
        FINISH
    } state_t;

    state_t state;

    logic [7:0] tx_shift;
    logic [7:0] rx_shift;

    integer clk_count;
    integer bit_count;

    always_ff @(posedge clk) begin

        if (rst) begin

            state     <= IDLE;

            tx_shift  <= 8'h00;
            rx_shift  <= 8'h00;

            rx_data   <= 8'h00;

            busy      <= 1'b0;
            done      <= 1'b0;

            spi_cs    <= 1'b1;
            spi_sclk  <= 1'b0;
            spi_mosi  <= 1'b0;

            clk_count <= 0;
            bit_count <= 0;

        end

        else begin

            done <= 1'b0;

            case (state)

                IDLE: begin

                    spi_cs   <= 1'b1;
                    spi_sclk <= 1'b0;
                    busy     <= 1'b0;

                    if (start) begin

                        state     <= TRANSFER;

                        busy      <= 1'b1;
                        spi_cs    <= 1'b0;

                        tx_shift  <= tx_data;
                        rx_shift  <= 8'h00;

                        bit_count <= 0;
                        clk_count <= 0;

                        spi_mosi  <= tx_data[7];

                    end

                end


                TRANSFER: begin

                    if (clk_count == CLK_DIV-1) begin

                        clk_count <= 0;

                        if (spi_sclk == 1'b0) begin

                            // Rising edge
                            spi_sclk <= 1'b1;

                            rx_shift <= {rx_shift[6:0], spi_miso};

                        end

                        else begin

                            // Falling edge
                            spi_sclk <= 1'b0;

                            if (bit_count == 7) begin

                                state <= FINISH;

                            end

                            else begin

                                bit_count <= bit_count + 1;

                                tx_shift <= {tx_shift[6:0], 1'b0};

                                spi_mosi <= tx_shift[6];

                            end

                        end

                    end

                    else begin

                        clk_count <= clk_count + 1;

                    end

                end


                FINISH: begin

                    spi_cs   <= 1'b1;
                    spi_sclk <= 1'b0;
                    spi_mosi <= 1'b0;

                    busy     <= 1'b0;

                    rx_data  <= rx_shift;

                    done     <= 1'b1;

                    state    <= IDLE;

                end

                default: begin

                    state <= IDLE;

                end

            endcase

        end

    end

endmodule
