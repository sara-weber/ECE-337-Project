// AHB Lite Master Testbench

`timescale 1ns / 10ps

module tb_flex_counter();

	// Define parameters
	// basic test bench parameters
	localparam	CLK_PERIOD		= 5.0;
	localparam 	AHB_BUS_SIZE 	= 32;

	// Shared Test Variables
	reg tb_HCLK;
	reg tb_HRESETn;
	reg tb_HREADY;
	reg tb_HRESP;
	reg [AHB_BUS_SIZE - 1:0] tb_HRDATA;
	reg [AHB_BUS_SIZE - 1:0] tb_destination;
	reg tb_dest_updated;
  reg [(4 * AHB_BUS_SIZE) - 1:0] tb_encr_text;
  reg tb_text_rcvd;
  reg [AHB_BUS_SIZE - 1:0] tb_HADDR;
  reg tb_HWRITE;
  reg [2:0] tb_HSIZE;
  reg [2:0] tb_HBURST;
  reg [1:0] tb_HTRANS;
  reg [AHB_BUS_SIZE - 1:0] tb_HWDATA;

	// Test bench signals
	int tb_test_num;
	string tb_test_case;

	// Clock generation block (300 MHz)
	always
	begin
		tb_HCLK = 1'b0;
		#(CLK_PERIOD/3.0);
		tb_HCLK = 1'b1;
		#(CLK_PERIOD/3.0);
	end

	ahb_lite_master_interface DUT(
    .HCLK(tb_HCLK),
    .HRESETn(tb_HRESETn),
    .HREADY(tb_HREADY),
    .HRESP(tb_HRESP),
    .HRDATA(tb_HRDATA),
    .destination(tb_destination),
    .dest_updated(tb_dest_updated),
    .encr_text(tb_encr_text),
    .signal_received(tb_text_rcvd),
    .HADDR(tb_HADDR),
    .HWRITE(tb_HWRITE),
    .HBURST(tb_HBURST),
    .HTRANS(tb_HTRANS),
    .HWDATA(tb_HWDATA)
  )

	// Test bench process
	initial
	begin
		// Initialize all of the test inputs
		tb_HRESETn      = 1'b1;		// Initialize to be inactive
		tb_HREADY		    = 1'b1; 	// Initialize to be high (ready)
		tb_HRESP 	      = 1'b0;		// Initialize to be low (no errors)
		tb_HRDATA       = 32'b0;  // No data being read in
    tb_destination  = 32'b0;  // No initial destination
    tb_dest_updated = 1'b0;   // Destination not updated initially
    tb_encr_text    = 128'b0; // Empty text initially
    tb_text_rcvd    = 1'b0;   // No text received initially

		tb_test_num = 0;
		tb_test_case = "Test bench initializaton";
		@(posedge tb_clk)

		// Test Case 1 - Initial Reset
		tb_test_num += 1;
		tb_test_case = "Initial Reset";

		tb_n_rst = 0;	// set reset (active low)
		@(posedge tb_clk)

		if (tb_HADDR == '0 && tb_HWRITE == 1'b1) begin
			$info("%s: Case %d, PASSED!", tb_test_case, tb_test_num);
		end else begin
			$info("%s: Case %d, FAILED!", tb_test_case, tb_test_num);
		end

	end
endmodule