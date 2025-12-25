/*  
Author : Mohamed Sameh Mohamed Kamel
Module : APB5 Master Interface V2.1
*/

module APB_Master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter USER_REQ_WIDTH  = 8,
    parameter USER_DATA_WIDTH = DATA_WIDTH/2,
    parameter USER_RESP_WIDTH = 16,
    parameter STRB_WIDTH = DATA_WIDTH/8,

    parameter NUM_SLAVES = 2,

    // Base addresses for the 2 slaves
    parameter SLAVE0_BASE = 32'h0000_1000,
    parameter SLAVE1_BASE = 32'h0000_2000
) (
    // Clock and Reset
    input                               PCLK,
    input                               PRESETn,

    // APB Slave Inputs
    input                               PREADY,
    input                               PSLVERR,
    input                               PPARERR,
    input  [DATA_WIDTH-1:0]             PRDATA,
    input  [USER_DATA_WIDTH-1:0]        PRUSER,
    input  [USER_RESP_WIDTH-1:0]        PBUSER,

    // Control Inputs
    input  [1:0]                        transfer,
    input  [DATA_WIDTH-1:0]             write_data,
    input  [ADDR_WIDTH-1:0]             address,

    // APB Master Outputs
    output reg [ADDR_WIDTH-1:0]         PADDR,
    output reg [DATA_WIDTH-1:0]         PWDATA,
    output reg [STRB_WIDTH-1:0]         PSTRB,
    output reg [2:0]                    PPROT,
    output reg [NUM_SLAVES-1:0]         PSEL,
    output reg                          PENABLE,
    output reg                          PWRITE,
    output reg                          PWAKEUP,
    output reg [USER_REQ_WIDTH-1:0]     PAUSER,
    output reg [USER_DATA_WIDTH-1:0]    PWUSER,
    output reg                          PPARITY,

    output reg [DATA_WIDTH-1:0]         read_data,
    output reg [USER_DATA_WIDTH-1:0]    read_user,
    output reg [USER_RESP_WIDTH-1:0]    read_resp
);

    // ---------------------------------------
    // States
    // ---------------------------------------
    localparam IDLE   = 2'b00;
    localparam SETUP  = 2'b01;
    localparam ACCESS = 2'b10;

    localparam NO_TRANSFER = 2'b00;
    localparam WRITE_XFER  = 2'b01;
    localparam READ_XFER   = 2'b10;

    reg [1:0] current_state, next_state;
    reg       error_flag;

    // ---------------------------------------
    // Slave Decoder (2 slaves only)
    // ---------------------------------------
    reg [NUM_SLAVES-1:0] decode_sel;
    always @(*) begin
        decode_sel = 0;
        if (address[ADDR_WIDTH-1:12] == SLAVE0_BASE[ADDR_WIDTH-1:12])
            decode_sel[0] = 1'b1;
        else if (address[ADDR_WIDTH-1:12] == SLAVE1_BASE[ADDR_WIDTH-1:12])
            decode_sel[1] = 1'b1;
    end

    // ---------------------------------------
    // State Register
    // ---------------------------------------
    always @(posedge PCLK or negedge PRESETn)
        if (!PRESETn) current_state <= IDLE;
        else          current_state <= next_state;

    // ---------------------------------------
    // Next-State Logic
    // ---------------------------------------
    always @(*) begin
        next_state = current_state;
        case (current_state)
            IDLE:
                if (transfer != NO_TRANSFER)
                    next_state = SETUP;

            SETUP:
                next_state = ACCESS;

            ACCESS:
                if (PREADY)
                    next_state = (transfer != NO_TRANSFER) ? SETUP : IDLE;
        endcase
    end

    // ---------------------------------------
    // Output Logic
    // ---------------------------------------
    always @(*) begin
        PSEL    = 0;
        PENABLE = 0;
        PWRITE  = 0;
        PADDR   = 0;
        PWDATA  = 0;
        PSTRB   = 0;
        PPROT   = 3'b000;
        PWAKEUP = 0;
        PAUSER  = 0;
        PWUSER  = 0;

        case (current_state)
            IDLE: begin end

            SETUP: begin
                PSEL  = decode_sel;
                PADDR = address;
                if (transfer == WRITE_XFER) begin
                    PWRITE = 1;
                    PWDATA = write_data;
                    PSTRB  = {STRB_WIDTH{1'b1}};
                    PWUSER = write_data[USER_DATA_WIDTH-1:0];
                end
                PAUSER  = address[USER_REQ_WIDTH-1:0];
                PWAKEUP = 1'b1;
            end

            ACCESS: begin
                PENABLE = 1;
                PSEL    = decode_sel;
                PADDR   = address;
                if (transfer == WRITE_XFER) begin
                    PWRITE = 1;
                    PWDATA = write_data;
                    PSTRB  = {STRB_WIDTH{1'b1}};
                    PWUSER = write_data[USER_DATA_WIDTH-1:0];
                end
                PAUSER = address[USER_REQ_WIDTH-1:0];
            end
        endcase

        // Parity generation
        PPARITY = ^{PADDR, PWRITE, PSTRB, PPROT, PWDATA, PAUSER, PWUSER};
    end

    // ---------------------------------------
    // Read Capture
    // ---------------------------------------
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            read_data <= 0;
            read_user <= 0;
            read_resp <= 0;
        end else if (current_state == ACCESS && PREADY && transfer == READ_XFER && !PSLVERR && !PPARERR) begin
            read_data <= PRDATA;
            read_user <= PRUSER;
            read_resp <= PBUSER;
        end
    end

    // ---------------------------------------
    // Error Flag
    // ---------------------------------------
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            error_flag <= 0;
        else if (current_state == ACCESS && PREADY && (PSLVERR || PPARERR))
            error_flag <= 1;
        else if (current_state == IDLE)
            error_flag <= 0;
    end

endmodule
