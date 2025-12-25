/* 
 Author : Mohamed Sameh Mohamed Kamel
 Testbench for APB5 Top V2.1
*/

`timescale 1ns/1ps

module APB_Top_tb;

    // ======================
    // Parameters
    // ======================
    localparam ADDR_WIDTH      = 32;
    localparam DATA_WIDTH      = 32;
    localparam USER_DATA_WIDTH = DATA_WIDTH/2;
    localparam USER_RESP_WIDTH = 16;

    // ======================
    // DUT I/O
    // ======================
    reg                     PCLK;
    reg                     PRESETn;

    reg  [1:0]              transfer;
    reg  [31:0]             write_data;
    reg  [31:0]             address;

    wire [31:0]             read_data;
    wire [USER_DATA_WIDTH-1:0] read_user;
    wire [USER_RESP_WIDTH-1:0] read_resp;

    // ======================
    // Instantiate DUT
    // ======================
    APB_Top DUT (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .transfer(transfer),
        .write_data(write_data),
        .address(address),
        .read_data(read_data),
        .read_user(read_user),
        .read_resp(read_resp)
    );

    // ======================
    // Clock Generation
    // ======================
    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;      // 100 MHz
    end

    // ======================
    // Reset
    // ======================
    task apply_reset;
    begin
        PRESETn = 0;
        transfer   = 0;
        address    = 0;
        write_data = 0;

        repeat (5) @(posedge PCLK);
        PRESETn = 1;

        $display("\n===================================");
        $display("   RESET DONE — Simulation Start");
        $display("===================================\n");
    end
    endtask

    // ======================
    // APB Write Task
    // ======================
    task apb_write(input [31:0] addr, input [31:0] data);
    begin
        $display("[WRITE] Addr=%h  Data=%h", addr, data);

        @(posedge PCLK);
        address    = addr;
        write_data = data;
        transfer   = 2'b01;    // WRITE

        @(posedge PCLK);       // Setup stays for 1 cycle
        transfer = 2'b01;

        // Wait until the selected slave asserts PREADY
        while (DUT.MASTER.current_state != 2'b10) @(posedge PCLK);
        while (DUT.PREADY !== 1'b1) @(posedge PCLK);

        @(posedge PCLK);
        transfer = 0;
    end
    endtask

    // ======================
    // APB Read Task
    // ======================
    task apb_read(input [31:0] addr, output [31:0] data_out);
    begin
        $display("[READ] Addr=%h", addr);

        @(posedge PCLK);
        address  = addr;
        transfer = 2'b10;

        @(posedge PCLK);
        transfer = 2'b10;

        // Wait for READY
        while (DUT.MASTER.current_state != 2'b10) @(posedge PCLK);
        while (DUT.PREADY !== 1'b1) @(posedge PCLK);

        @(posedge PCLK);
        data_out = read_data;
        transfer = 0;

        $display("[READ RESULT] Addr=%h  Data=%h", addr, data_out);
    end
    endtask

    // ======================
    // MAIN TEST
    // ======================
    reg [31:0] rdata;

    initial begin
        apply_reset();

        // =============== Test 1 — Write to slave 2 ===============
        apb_write(32'h0000_3000, 32'hDEAD_BEEF);

        // =============== Test 2 — Read from slave 2 ===============
        apb_read(32'h0000_3000, rdata);

        // =============== Test 3 — Write to slave 1 ===============
        apb_write(32'h0000_2000, 32'hCAFEBABE);

        // =============== Test 4 — Read from slave 1 ===============
        apb_read(32'h0000_2000, rdata);

        #100;
        $display("\n===================================");
        $display("        SIMULATION FINISHED");
        $display("===================================\n");

        $stop;
    end

endmodule
