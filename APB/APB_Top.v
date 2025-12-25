/*  
Author : Mohamed Sameh Mohamed Kamel
Module : APB5 Top V2.1
*/

module APB_Top #(
    parameter ADDR_WIDTH        = 32,
    parameter DATA_WIDTH        = 32,
    parameter USER_REQ_WIDTH    = 8,
    parameter USER_DATA_WIDTH   = DATA_WIDTH/2,
    parameter USER_RESP_WIDTH   = 16,
    parameter STRB_WIDTH        = DATA_WIDTH/8,

    parameter NUM_SLAVES = 2,

    // Base addresses for 2 slaves
    parameter SLAVE0_BASE = 32'h0000_1000,
    parameter SLAVE1_BASE = 32'h0000_2000
)(
    input                    PCLK,
    input                    PRESETn,

    // Master control stimulus (from testbench or CPU)
    input      [1:0]         transfer,
    input      [DATA_WIDTH-1:0] write_data,
    input      [ADDR_WIDTH-1:0] address,

    // Outputs back to testbench or CPU
    output     [DATA_WIDTH-1:0] read_data,
    output     [USER_DATA_WIDTH-1:0] read_user,
    output     [USER_RESP_WIDTH-1:0] read_resp
);

    // ============================
    // Wires Between Master & Slaves
    // ============================
    wire [ADDR_WIDTH-1:0]       PADDR;
    wire [DATA_WIDTH-1:0]       PWDATA;
    wire [STRB_WIDTH-1:0]       PSTRB;
    wire [2:0]                  PPROT;
    wire [NUM_SLAVES-1:0]       PSEL;
    wire                        PENABLE;
    wire                        PWRITE;
    wire                        PWAKEUP;
    wire [USER_REQ_WIDTH-1:0]   PAUSER;
    wire [USER_DATA_WIDTH-1:0]  PWUSER;
    wire                        PPARITY;

    // Slave ? Master
    wire [NUM_SLAVES-1:0]       PREADY_s;
    wire [NUM_SLAVES-1:0]       PSLVERR_s;
    wire [NUM_SLAVES-1:0]       PPARERR_s;

    wire [DATA_WIDTH-1:0]       PRDATA_s [0:NUM_SLAVES-1];
    wire [USER_DATA_WIDTH-1:0]  PRUSER_s [0:NUM_SLAVES-1];
    wire [USER_RESP_WIDTH-1:0]  PBUSER_s [0:NUM_SLAVES-1];

    // Combined OR/reduction for selected slave
    wire                        PREADY  = |(PREADY_s  & PSEL);
    wire                        PSLVERR = |(PSLVERR_s & PSEL);
    wire                        PPARERR = |(PPARERR_s & PSEL);

    reg  [DATA_WIDTH-1:0]       PRDATA;
    reg  [USER_DATA_WIDTH-1:0]  PRUSER;
    reg  [USER_RESP_WIDTH-1:0]  PBUSER;

    // Multiplex selected slave output
    integer i;
    always @(*) begin
        PRDATA = 0; PRUSER = 0; PBUSER = 0;
        for(i=0; i<NUM_SLAVES; i=i+1) begin
            if (PSEL[i]) begin
                PRDATA = PRDATA_s[i];
                PRUSER = PRUSER_s[i];
                PBUSER = PBUSER_s[i];
            end
        end
    end

    // ============================
    // Master Instantiation
    // ============================
    APB_Master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .USER_REQ_WIDTH(USER_REQ_WIDTH),
        .USER_DATA_WIDTH(USER_DATA_WIDTH),
        .USER_RESP_WIDTH(USER_RESP_WIDTH),
        .STRB_WIDTH(STRB_WIDTH),
        .NUM_SLAVES(NUM_SLAVES),
        .SLAVE0_BASE(SLAVE0_BASE),
        .SLAVE1_BASE(SLAVE1_BASE)
    ) MASTER (
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

    // ============================
    // Generate 2 Slaves
    // ============================
    APB_Slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .USER_REQ_WIDTH(USER_REQ_WIDTH),
        .USER_DATA_WIDTH(USER_DATA_WIDTH),
        .USER_RESP_WIDTH(USER_RESP_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) SLAVE0 (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL[0]),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PSTRB(PSTRB),
        .PPROT(PPROT),
        .PWAKEUP(PWAKEUP),
        .PAUSER(PAUSER),
        .PWUSER(PWUSER),
        .PPARITY(PPARITY),
        .PRDATA(PRDATA_s[0]),
        .PRUSER(PRUSER_s[0]),
        .PBUSER(PBUSER_s[0]),
        .PREADY(PREADY_s[0]),
        .PSLVERR(PSLVERR_s[0]),
        .PPARERR(PPARERR_s[0])
    );

    APB_Slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .USER_REQ_WIDTH(USER_REQ_WIDTH),
        .USER_DATA_WIDTH(USER_DATA_WIDTH),
        .USER_RESP_WIDTH(USER_RESP_WIDTH),
        .STRB_WIDTH(STRB_WIDTH)
    ) SLAVE1 (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL[1]),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PSTRB(PSTRB),
        .PPROT(PPROT),
        .PWAKEUP(PWAKEUP),
        .PAUSER(PAUSER),
        .PWUSER(PWUSER),
        .PPARITY(PPARITY),
        .PRDATA(PRDATA_s[1]),
        .PRUSER(PRUSER_s[1]),
        .PBUSER(PBUSER_s[1]),
        .PREADY(PREADY_s[1]),
        .PSLVERR(PSLVERR_s[1]),
        .PPARERR(PPARERR_s[1])
    );

endmodule
