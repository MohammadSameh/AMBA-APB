/* 
 Author : Mohamed Sameh Mohamed Kamel
 Testbench for APB5 Master Interface V2.1
*/

`timescale 1ns/1ps

module APB_Master_tb;

    // -------------------------------
    // Parameters
    // -------------------------------
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;
    localparam USER_REQ_WIDTH  = 8;
    localparam USER_DATA_WIDTH = DATA_WIDTH/2;
    localparam USER_RESP_WIDTH = 16;
    localparam STRB_WIDTH = DATA_WIDTH/8;

    localparam NUM_SLAVES = 4;

    // Base addresses (must match Master)
    localparam [ADDR_WIDTH-1:0] SLAVE_BASE_ADDR [0:NUM_SLAVES-1] = 
    '{
        32'h0000_1000,
        32'h0000_2000,
        32'h0000_3000,
        32'h0000_4000
    };

    // -------------------------------
    // DUT Inputs
    // -------------------------------
    reg PCLK;
    reg PRESETn;

    reg  PREADY;
    reg  PSLVERR;
    reg  PPARERR;
    reg  [DATA_WIDTH-1:0] PRDATA;
    reg  [USER_DATA_WIDTH-1:0] PRUSER;
    reg  [USER_RESP_WIDTH-1:0] PBUSER;

    reg  [1:0] transfer;
    reg  [DATA_WIDTH-1:0] write_data;
    reg  [ADDR_WIDTH-1:0] address;

    // -------------------------------
    // DUT Outputs
    // -------------------------------
    wire [ADDR_WIDTH-1:0] PADDR;
    wire [DATA_WIDTH-1:0] PWDATA;
    wire [STRB_WIDTH-1:0] PSTRB;
    wire [2:0]            PPROT;
    wire [NUM_SLAVES-1:0] PSEL;
    wire PENABLE;
    wire PWRITE;
    wire PWAKEUP;
    wire [USER_REQ_WIDTH-1:0] PAUSER;
    wire [USER_DATA_WIDTH-1:0] PWUSER;
    wire PPARITY;

    wire [DATA_WIDTH-1:0] read_data;
    wire [USER_DATA_WIDTH-1:0] read_user;
    wire [USER_RESP_WIDTH-1:0] read_resp;

    // -------------------------------
    // Instantiate DUT
    // -------------------------------
    APB_Master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .USER_REQ_WIDTH(USER_REQ_WIDTH),
        .USER_DATA_WIDTH(USER_DATA_WIDTH),
        .USER_RESP_WIDTH(USER_RESP_WIDTH),
        .STRB_WIDTH(STRB_WIDTH),
        .NUM_SLAVES(NUM_SLAVES),
        .SLAVE_BASE_ADDR(SLAVE_BASE_ADDR)
    ) DUT (
        .PCLK(PCLK),
        .PRESETn(PRESETn),

        .PREADY(PREADY),
        .PSLVERR(PSLVERR),
        .PPARERR(PPARERR),
        .PRDATA(PRDATA),
        .PRUSER(PRUSER),
        .PBUSER(PBUSER),

        .transfer(transfer),
        .write_data(write_data),
        .address(address),

        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PSTRB(PSTRB),
        .PPROT(PPROT),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PWAKEUP(PWAKEUP),
        .PAUSER(PAUSER),
        .PWUSER(PWUSER),
        .PPARITY(PPARITY),

        .read_data(read_data),
        .read_user(read_user),
        .read_resp(read_resp)
    );

    // -------------------------------
    // Clock Generation
    // -------------------------------
    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;  // 100 MHz
    end

    // -------------------------------
    // Reset
    // -------------------------------
    initial begin
        PRESETn = 0;
        #20;
        PRESETn = 1;
    end

    // ==========================================
    // Testbench Behavioural Slave (Mock Slave)
    // ==========================================
    initial begin
        PREADY  = 0;
        PSLVERR = 0;
        PPARERR = 0;
        PRDATA  = 32'h0;
        PRUSER  = 0;
        PBUSER  = 0;
    end

    task slave_respond(input [31:0] data);
    begin
        @(posedge PCLK);
        PREADY = 1;
        PRDATA = data;
        PRUSER = 8'hA5;
        PBUSER = 16'h55AA;
        @(posedge PCLK);
        PREADY = 0;
    end
    endtask

    // ==========================================
    // Test Sequence
    // ==========================================
    initial begin
        transfer = 2'b00;
        write_data = 0;
        address = 0;

        @(posedge PRESETn);  // wait for reset release

        #10;
        $display("==== WRITE to SLAVE 1 ====");
        address     = 32'h0000_2004; // matches SLAVE_BASE_ADDR[1]
        write_data  = 32'hDEADBEEF;
        transfer    = 2'b01;         // WRITE

        #40;  // allow master to reach ACCESS

        slave_respond(32'h0000_0000);  // write ignore data

        transfer = 2'b00;
        #20;

        $display("==== READ from SLAVE 2 ====");
        address     = 32'h0000_3008;
        transfer    = 2'b10;         // READ

        #30;

        slave_respond(32'hCAFEBABE);

        transfer = 2'b00;

        #50;

        $display("READ_DATA = %h", read_data);
        $display("READ_USER = %h", read_user);
        $display("READ_RESP = %h", read_resp);

        $display("==== TEST FINISHED ====");
        #20;
        $stop;
    end

endmodule
