`include "config.svh"

module lab_top
# (
    parameter  clk_mhz       = 50,
               w_key         = 4,
               w_sw          = 8,
               w_led         = 8,
               w_digit       = 8,
               w_gpio        = 100,

               screen_width  = 640,
               screen_height = 480,

               w_red         = 4,
               w_green       = 4,
               w_blue        = 4,

               w_x           = $clog2 ( screen_width  ),
               w_y           = $clog2 ( screen_height ),
               width = 16
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // Graphics

    input        [w_x     - 1:0] x,
    input        [w_y     - 1:0] y,

    output logic [w_red   - 1:0] red,
    output logic [w_green - 1:0] green,
    output logic [w_blue  - 1:0] blue,

    // Microphone, sound output and UART

    input        [         23:0] mic,
    output       [         15:0] sound,

    input                        uart_rx,
    output                       uart_tx,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio
);

 //------------------------------------------------------------------------

    // assign led        = '0;
    // assign abcdefgh   = '0;
    // assign digit      = '0;
       assign red        = '0;
       assign green      = '0;
       assign blue       = '0;
       assign sound      = '0;
       assign uart_tx    = '1;

 //------------------------------------------------------------------------

    wire [w_digit - 1:0] dots = '0;
    localparam w_number = w_digit * 4;

 //------------------------------------------------------------------------
    // My code begins here
    logic [5:0] sample_index;           //FFT with 64 samples, this hold the count of collected samples 0-64
    logic buffer_ready;                 //if all 64 samples are collected we are ready to send it to FFT
    logic send_data;
    logic [4:0] input_index;            //i want to send every 10-th microphone input

    logic fft_di_en;
    logic [width - 1:0]fft_di_re;
    logic [width - 1:0]fft_di_im;
    logic fft_do_en;
    logic [width - 1:0]fft_do_re;
    logic [width - 1:0]fft_do_im;

    logic [width - 1:0] sample_buffer [0:63];  //buffer where we will hold our collected data to send it one-by-one

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sample_index  <= 0;
            buffer_ready  <= 0;
        end else begin
            if (!buffer_ready) begin
                if(input_index !== 11) begin
                    input_index <= input_index + 1;
                end
                else begin
                    sample_buffer[sample_index] <= mic[23:23 - width + 1];    //truncate from 24 bits to 16 bits, cuz FFT width is 16
                    sample_index <= sample_index + 1;
                    if (sample_index == 63)
                        buffer_ready <= 1;
                    input_index <= 0;
                end
            end else if (send_data) begin
                buffer_ready <= 0;
                sample_index <= 0;
            end
        end
    end

    assign send_data = key[0] & buffer_ready;


logic [5:0] fft_index;
logic sending;

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        fft_index     <= 0;
        fft_di_en     <= 0;
        sending       <= 0;
    end else begin

        if (send_data && !sending) begin
            sending      <= 1;
            fft_index    <= 0;
            fft_di_en    <= 1;
            fft_di_re    <= sample_buffer[0];
        end else if (sending) begin
            fft_index    <= fft_index + 1;
            fft_di_re    <= sample_buffer[fft_index];
            fft_di_en    <= 1;

            if (fft_index == 63) begin
                sending   <= 0;
                fft_di_en <= 0;
            end

        end else begin
            fft_di_en <= 0;
        end

    end
end

//this function is needed, because FFT output is in bit_reversed order(the indices)
function [5:0] bit_reverse;
    input [5:0] index;
    logic [4:0] i;
    begin
        bit_reverse = 0;
        for (i = 0; i < 6; i = i + 1) begin
            bit_reverse = (bit_reverse << 1) | (index[i]);
        end
    end
endfunction

logic [5:0] fft_out_index;
logic [width - 1:0] fft_out_re [0:63];
logic [width - 1:0] fft_out_im [0:63];
logic [2*width-1:0] fft_bins [0:63];    //32 bits, cuz multiplication and sum may reach 32 bits
logic output_complete;
logic bins_complete;
logic [5:0] bins_index;

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        fft_out_index     <= 0;
    end else begin
        if (fft_do_en) begin
            if (fft_out_index == 63) begin
                fft_out_index <= 0;
                output_complete <= 0;
            end else begin
                fft_out_re[fft_out_index] = fft_do_re;
                fft_out_im[fft_out_index] = fft_do_im;
                fft_out_index <= fft_out_index + 1;
            end
        end else begin
            output_complete <= 1;
        end
    end
end

always_ff @(posedge clk) begin
    if(output_complete) begin
        if (bins_index == 63) begin
            bins_index <= 0;
            bins_complete <= 1;
        end
        else if (output_complete) begin
            fft_bins[bit_reverse(bins_index)] <= fft_out_re[bins_index] * fft_out_re[bins_index] + fft_out_im[bins_index] * fft_out_im[bins_index];
            bins_index <= bins_index + 1;
        end
    end
end

always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        led <= 0;
    end else if (bins_complete) begin
        led[0] <= fft_bins[0] > 10000 ? 1 : 0;
        led[1] <= fft_bins[25] > 10000 ? 1 : 0;
        led[2] <= fft_bins[26] > 10000 ? 1 : 0;
        led[3] <= fft_bins[27] > 10000 ? 1 : 0;
        led[4] <= fft_bins[28] > 10000 ? 1 : 0;
        led[5] <= fft_bins[29] > 10000 ? 1 : 0;
        led[6] <= fft_bins[30] > 10000 ? 1 : 0;
        led[7] <= fft_bins[31] > 10000 ? 1 : 0;
    end
end

    FFT FFT (
        .clock (clk),
        .reset (rst),
        .di_en (fft_di_en),
        .di_re (fft_di_re),
        .di_im (fft_di_im),
        .do_en (fft_do_en),
        .do_re (fft_do_re),
        .do_im (fft_do_im)
    );

endmodule