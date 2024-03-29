module slave_write (
  input wire HCLK,
  input wire HRESETn,
  input wire HSELx,
  input wire [31:0] HADDR,
	input wire [2:0] HBURST,
	input wire [1:0] HTRANS,
  input wire HREADY,
  input wire fifo_full,
	input wire [31:0] SWDATA,
  output reg [127:0] key,
	output reg [127:0] nonce,
	output reg [31:0] destination,
	output reg [127:0] plain_text,
  output reg write_out,
  output reg write_error,
	output reg write_ready
);

// User Defined Types
typedef enum bit [1:0] {S1,S2,S3,S4} stateType;

// Internal Signals
stateType state;
stateType nextState;
reg [31:0] 	prev_HADDR;
reg [127:0] prev_key;
reg [127:0] prev_nonce;
reg [31:0] 	prev_dest;
reg [127:0] prev_text;

always_ff @ (posedge HCLK, negedge HRESETn) begin
  if (HRESETn == 1'b0) begin // If selected and not being reset
    state <= S1;
    //prev_HADDR <= 32'b0;
    prev_key 	 <= 128'b0;
    prev_nonce <= 128'b0;
    prev_dest  <= 32'b0;
    prev_text  <= 128'b0;
  end else begin // Else if being reset and/or not currently selected
  	//prev_HADDR <= HADDR;
    prev_key   <= key;
    prev_nonce <= nonce;
    prev_dest  <= destination;
    prev_text  <= plain_text;
    state <= nextState;
  end

end

always_ff @ (negedge HCLK) begin
	prev_HADDR <= HADDR;
end

always @(negedge HCLK) begin

	// Set defaults to avoid latches
	nextState = state;
  key = prev_key;
  nonce = prev_nonce;
  destination = prev_dest;
  plain_text = prev_text;
  write_error = 1'b0;
  write_ready = 1'b1;
  write_out = 1'b0;
  
	// Select state depending on HTRANS
  if (HTRANS == 2'b0) begin
  	nextState = S1;
  end else if (HTRANS == 2'b1) begin
  	nextState = S2;
  end else if (HTRANS == 2'b10) begin
    nextState = S3;
 	end else begin
 		nextState = S4;
 	end

  casez (state)

    S1:
    begin
      // HBURST: SINGLE, HTRANS: IDLE
      // Do not read data in IDLE state
      // nextState = S1;
    end

    S2:
    begin

      // HBURST: SINGLE, HTRANS: BUSY
      // Nonsensical state, raise error
      write_error = 1'b1;
    end

    S3:
    begin
      // HBURST: SINGLE, HTRANS: NONSEQ
      // Single burst write
      write_error = 1'b0;
      /* key = prev_key;
      nonce = prev_nonce;
      destination = prev_dest;
      plain_text = prev_text; */

      // if (HREADY == 1'b1) begin
        // If ready write to address
        // Choose to not use address 0x00 so data would not be accidentally overwritten.
        if (prev_HADDR[7:0] == 8'h04) begin
          // Key Address (1/4)
          key[31:0] = SWDATA;
        end else if (prev_HADDR[7:0] == 8'h08) begin
          // Key Address (2/4)
          key[63:0] = {SWDATA,prev_key[31:0]};
        end else if (prev_HADDR[7:0] == 8'h0C) begin
          // Key Address (3/4)
          key[95:0] = {SWDATA,prev_key[63:0]};
        end else if (prev_HADDR[7:0] == 8'h10) begin
          // Key Address (4/4)
          key[127:0] = {SWDATA,prev_key[95:0]};
        end else if (prev_HADDR[7:0] == 8'h14) begin
          // Nonce Address (1/4)
          nonce[31:0] = SWDATA;
        end else if (prev_HADDR[7:0] == 8'h18) begin
          // Nonce Address (2/4)
          nonce[63:0] = {SWDATA,prev_nonce[31:0]};
        end else if (prev_HADDR[7:0] == 8'h1C) begin
          // Nonce Address (3/4)
          nonce[95:0] = {SWDATA,prev_nonce[63:0]};
        end else if (prev_HADDR[7:0] == 8'h20) begin
          // Nonce Address (4/4)
          nonce[127:0] = {SWDATA,prev_nonce[95:0]};
        end else if (prev_HADDR[7:0] == 8'h24) begin
          // Destination Address (1/1)
          destination = SWDATA;
        end else if (prev_HADDR[7:0] == 8'h34) begin
          // Plain Text Address (1/4)
          if (fifo_full == 1'b0) begin // if FIFO is full don't wait to write
            plain_text[31:0] = SWDATA;
          end else begin
            write_ready = 1'b0;
          end
        end else if (prev_HADDR[7:0] == 8'h38) begin
          // Plain Text Address (2/4)
          if (fifo_full == 1'b0) begin // if FIFO is full don't wait to write
            plain_text[63:0] = {SWDATA,prev_text[31:0]};
          end else begin
            write_ready = 1'b0;
          end
        end else if (prev_HADDR[7:0] == 8'h3C) begin
          // Plain Text Address (3/4)
          if (fifo_full == 1'b0) begin // if FIFO is full don't wait to write
            plain_text[95:0] = {SWDATA,prev_text[63:0]};
          end else begin
            write_ready = 1'b0;
          end
        end else if (prev_HADDR[7:0] == 8'h40) begin
          // Plain Text Address (4/4)
          if (fifo_full == 1'b0) begin // if FIFO is full don't wait to write
            plain_text[127:0] = {SWDATA,prev_text[95:0]};
            write_out = 1'b1;
          end else begin
            write_ready = 1'b0;
          end
        end else begin
          // Invalid Address
          $display("INVALID ADDRESS: %h", prev_HADDR[7:0]);
          write_error = 1'b1;
        end
      //end

    end

    S4:
    begin
      // HBURST: SINGLE, HTRANS: SEQ
      // Nonsensical state, raise error
      write_error = 1'b1;
    end

		// All other possible states ignored.
		
    default: nextState = S1;

  endcase

end

endmodule // slave_write
