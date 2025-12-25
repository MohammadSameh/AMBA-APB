/*  
Author : Mohamed Sameh Mohamed Kamel
Module : APB5 Slave Interface V2.1
*/

module APB_Slave #(
    parameter ADDR_WIDTH        = 32,
    parameter DATA_WIDTH        = 32,
    parameter USER_REQ_WIDTH    = 8,                     // PAUSER width
    parameter USER_DATA_WIDTH   = DATA_WIDTH/2,          // PWUSER / PRUSER width
    parameter USER_RESP_WIDTH   = 16,                    // PBUSER width
    parameter STRB_WIDTH        = DATA_WIDTH/8,          // PSTRB width
    parameter MEM_DEPTH         = 1024                   // internal memory depth
)(
    input                               PCLK,
    input                               PRESETn,

    // APB Master Inputs
    input                               PSEL,
    input                               PENABLE,
    input                               PWRITE,
    input  [ADDR_WIDTH-1:0]             PADDR,
    input  [DATA_WIDTH-1:0]             PWDATA,
    input  [STRB_WIDTH-1:0]             PSTRB,
    input  [2:0]                        PPROT,
    input                               PWAKEUP,
    input  [USER_REQ_WIDTH-1:0]         PAUSER,
    input  [USER_DATA_WIDTH-1:0]        PWUSER,
    input                               PPARITY,

    // APB Slave Outputs
    output reg [DATA_WIDTH-1:0]         PRDATA,
    output reg [USER_DATA_WIDTH-1:0]    PRUSER,
    output reg [USER_RESP_WIDTH-1:0]    PBUSER,
    output reg                          PREADY,
    output reg                          PSLVERR,
    output reg                          PPARERR
);

    // =======================================================
    // Internal Memory
    // =======================================================
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    // =======================================================
    // Internal Registers
    // =======================================================
    reg [ADDR_WIDTH-1:0]     addr_reg;
    reg                      write_reg;
    reg                      slave_awake;
    reg [USER_REQ_WIDTH-1:0] user_req_reg;
    reg [USER_DATA_WIDTH-1:0] pwuser_reg;

    // =======================================================
    // Wakeup Logic 
    // =======================================================
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            slave_awake <= 1'b0;
        else if (PWAKEUP)
            slave_awake <= 1'b1;
    end

    // =======================================================
    // Parity Check 
    // =======================================================
    wire parity_calc = ^{PADDR, PWRITE, PSTRB, PPROT, PWDATA, PAUSER, PWUSER};
    always @(*) PPARERR = (parity_calc != PPARITY);

    // =======================================================
    // Setup Phase: Capture Address & User Attributes
    // =======================================================
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            addr_reg     <= 0;
            write_reg    <= 0;
            user_req_reg <= 0;
            pwuser_reg   <= 0;
        end else if (PSEL && !PENABLE) begin
            addr_reg     <= PADDR;
            write_reg    <= PWRITE;
            user_req_reg <= PAUSER;
            pwuser_reg   <= PWUSER;
        end
    end

    // =======================================================
    // Access Phase: Perform Write / Read
    // =======================================================
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            PRDATA <= 0;
        else if (PSEL && PENABLE && slave_awake) begin
            if (write_reg) begin
                if (addr_reg < MEM_DEPTH) begin
                    if (PSTRB[0]) mem[addr_reg][7:0]   <= PWDATA[7:0];
                    if (PSTRB[1]) mem[addr_reg][15:8]  <= PWDATA[15:8];
                    if (PSTRB[2]) mem[addr_reg][23:16] <= PWDATA[23:16];
                    if (PSTRB[3]) mem[addr_reg][31:24] <= PWDATA[31:24];
                end
            end else begin
                if (addr_reg < MEM_DEPTH)
                    PRDATA <= mem[addr_reg];
                else
                    PRDATA <= 32'hDEAD_BEEF;
            end
        end
    end

    // =======================================================
    // PREADY Logic 
    // =======================================================
    always @(*) PREADY = 1'b1;

    // =======================================================
    // Error Logic (Address + Parity + Wakeup + Protection)
    // =======================================================
    wire prot_error = (PPROT[0] == 1) || (PPROT[1] == 1) || (PPROT[2] == 1);
    always @(*) PSLVERR = (addr_reg >= MEM_DEPTH) | PPARERR | !slave_awake | prot_error;

    // =======================================================
    // User Response 
    // =======================================================
    always @(*) begin
        PRUSER = pwuser_reg;      // return write-user as read-user
        PBUSER = user_req_reg;    // return request-user attribute
    end

endmodule
