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
typedef enum bit [4:0] {S1,S2,S3,S4,S5,S6,S7,S8,S9,S10,S11,S12,S13,S14,S15,S16,S17,S18,S19,S20,S21,S22,S23,S24,S25,S26,S27,S28,S29,S30,S31,S32} stateType;

// Internal Signals
stateType state;
stateType next_state;
reg [127:0] next_key;
reg [127:0] next_nonce;
reg [31:0] next_destination;
reg [127:0] next_plain_text;
reg [31:0] prev_HADDR;


always_ff @ (posedge HCLK, posedge HSELx, negedge HRESETn) begin
  if (HRESETn == 1'b0 && HSELx == 1'b1) begin // If selected and not being reset
    key <= next_key;
    nonce <= next_nonce;
    destination <= next_destination;
    plain_text <= next_plain_text;
    $display("[STATE]: %s <= %s :[NEXT_STATE]",state, next_state);
    state <= next_state;
    $display("[NEW_STATE]: %s <= %s :[NEXT_STATE]",state, next_state);
    prev_HADDR <= HADDR;
  end else begin // Else if being reset and/or not currently selected
    key <= 128'b0;
    nonce <= 128'b0;
    destination <= 32'b0;
    plain_text <= 128'b0;
    state <= S1;
    write_out = 1'b0;
    write_error = 1'b0;
    write_ready = 1'b1; // AHB Protocol: During reset all slaves must ensure that HREADYOUT is HIGH.
    prev_HADDR <= 32'b0;
  end
end


always_comb begin

  next_key = key;
  next_nonce = nonce;
  next_destination = destination;
  next_plain_text = plain_text;
  next_state = state;
  write_error = 1'b0;
  write_ready = 1'b1;
  write_out = 1'b0;

  // See slave_write.md (README) for description of all states

  case (state)

    S1:
    begin
      // HBURST: SINGLE, HTRANS: IDLE
      // Do not read data in IDLE state
      convert({HBURST, HTRANS}, next_state); // Set next state
      $display("next state(S1): %s", next_state);
			if (HREADY != 1'b1 && state != next_state) begin
				write_error = 1'b1;
			end
    end

    S2:
    begin
      // HBURST: SINGLE, HTRANS: BUSY
      // Nonsensical state, raise error
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
      $display("next state(S2): %s", next_state);
			if (HREADY != 1'b1 && state != next_state) begin
				write_error = 1'b1;
			end
    end

    S3:
    begin
      // HBURST: SINGLE, HTRANS: NONSEQ
      // Single burst write
      if (HREADY == 1'b1) begin
        // If ready write to address
				$display("GUCCI");
				$display("prev_HADDR[7:0]: %h", prev_HADDR[7:0]);
        // Choose to not use address 0x00 so data would not be accidentally overwritten.
        if (prev_HADDR[7:0] == 8'h04) begin
          // Key Address (1/4)
          $display("GUCCI GANG");
          next_key[31:0] = SWDATA;
        end if (prev_HADDR[7:0] == 8'h08) begin
          // Key Address (2/4)
          next_key[63:31] = SWDATA;
        end if (prev_HADDR[7:0] == 8'h0C) begin
          // Key Address (3/4)
          next_key[95:64] = SWDATA;
        end if (prev_HADDR[7:0] == 8'h10) begin
          // Key Address
          next_key[127:96] = SWDATA;
        end else if (prev_HADDR[7:0] == 8'h14) begin
          // Nonce Address (1/4)
          next_nonce[31:0] = SWDATA;
        end else if (prev_HADDR[7:0] == 8'h18) begin
          // Nonce Address (2/4)
          next_nonce[63:32] = SWDATA;
        end else if (prev_HADDR[7:0] == 8'h1C) begin
          // Nonce Address (3/4)
          next_nonce[95:64] = SWDATA;
        end else if (prev_HADDR[7:0] == 8'h20) begin
          // Nonce Address (4/4)
          next_nonce[127:96] = SWDATA;
        end else if (prev_HADDR[7:0] == 8'h24) begin
          // Destination Address (1/1)
          next_destination = SWDATA;
        end else if (prev_HADDR[7:0] == 8'h34) begin
          // Plain Text Address (1/4)
          if (fifo_full == 1'b0) begin // if FIFO is full don't wait to write
            next_plain_text[31:0] = SWDATA;
          end else begin
            write_ready = 1'b0;
          end
        end else if (prev_HADDR[7:0] == 8'h38) begin
          // Plain Text Address (2/4)
          if (fifo_full == 1'b0) begin // if FIFO is full don't wait to write
            next_plain_text[63:32] = SWDATA;
          end else begin
            write_ready = 1'b0;
          end
        end else if (prev_HADDR[7:0] == 8'h3C) begin
          // Plain Text Address (3/4)
          if (fifo_full == 1'b0) begin // if FIFO is full don't wait to write
            next_plain_text[95:64] = SWDATA;
          end else begin
            write_ready = 1'b0;
          end
        end else if (prev_HADDR[7:0] == 8'h40) begin
          // Plain Text Address (4/4)
          if (fifo_full == 1'b0) begin // if FIFO is full don't wait to write
            next_plain_text = SWDATA;
            write_out = 1'b1;
          end else begin
            write_ready = 1'b0;
          end
        end else begin
          // Invalid Address
          write_error = 1'b1;
        end
      end
			convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S4:
    begin
      // HBURST: SINGLE, HTRANS: SEQ
      // Nonsensical state, raise error
      write_error = 1'b1;
       convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S5:
    begin
      // HBURST: INCR, HTRANS: IDLE
      // Do not write data in IDLE state

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S6:
    begin
      // HBURST: INCR, HTRANS: BUSY
      // Do not write data in BUSY state.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S7:
    begin
      // HBURST: INCR, HTRANS: NONSEQ
      // Beginning of INCR burst.

      // Not supported
      write_error = 1'b1;
    end

    S8:
    begin
      // HBURST: INCR, HTRANS: SEQ
      // Continuation of burst from state S7

      // Not supported
      write_error = 1'b1;
    end

    S9:
    begin
      // HBURST: WRAP4, HTRANS: IDLE
      // Do not write data in IDLE state.

      // Not supported
      write_error = 1'b1;
    end

    S10:
    begin
      // HBURST: WRAP4, HTRANS: BUSY
      // Do not write data in BUSY state.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S11:
    begin
      // HBURST: WRAP4, HTRANS: NONSEQ
      // Beginning of WRAP4 burst.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S12:
    begin
      // HBURST: WRAP4, HTRANS: SEQ
      // Continuation of burst from state S11.

      // Not supported
      write_error = 1'b1;
    end

    S13:
    begin
      // HBURST: INCR4, HTRANS: IDLE
      // Do not write data in IDLE state.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S14:
    begin
      // HBURST: INCR4, HTRANS: BUSY
      // Do not write data in BUSY state.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S15:
    begin
      // HBURST: INCR4, HTRANS: NONSEQ
      // Beginning of INCR4 burst.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S16:
    begin
      // HBURST: INCR4, HTRANS: SEQ
      // Continuation of burst from state S15.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S17:
    begin
      // HBURST: WRAP8, HTRANS: IDLE
      // Do not write data in IDLE state.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S18:
    begin
      // HBURST: WRAP8, HTRANS: BUSY
      // Do not write data in BUSY state.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S19:
    begin
      // HBURST: WRAP8, HTRANS: NONSEQ
      // Beginning of WRAP8 burst.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S20:
    begin
      // HBURST: WRAP8, HTRANS: SEQ
      // Continuation of burst from state S20.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S21:
    begin
      // HBURST: INCR8, HTRANS: IDLE
      // Do not write data in IDLE state.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S22:
    begin
      // HBURST: INCR8, HTRANS: BUSY
      // Do not write data in BUSY state.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S23:
    begin
      // HBURST: INCR8, HTRANS: NONSEQ
      // Beginning of INCR8 burst.

      // Not supported
      write_error = 1'b1;
    end

    S24:
    begin
      // HBURST: INCR8, HTRANS: SEQ
      // Continuation of burst from state S23.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S25:
    begin
      // HBURST: WRAP16, HTRANS: IDLE
      // Do not write data in IDLE state.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S26:
    begin
      // HBURST: WRAP16, HTRANS: BUSY
      // Do not write data in BUSY state.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S27:
    begin
      // HBURST: WRAP16, HTRANS: NONSEQ
      // Beginning of WRAP16 burst.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S28:
    begin
      // HBURST: WRAP16, HTRANS: SEQ
      // Continuation of burst from state S26.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S29:
    begin
      // HBURST: INCR16, HTRANS: IDLE
      // Do not write data in IDLE state.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S30:
    begin
      // HBURST: INCR16, HTRANS: BUSY
      // Do not write data in BUSY state.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S31:
    begin
      // HBURST: INCR16, HTRANS: NONSEQ
      // Beginning of WRAP16 burst.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

    S32:
    begin
      // HBURST: INCR16, HTRANS: SEQ
      // Continuation of burst from state 31.

      // Not supported
      write_error = 1'b1;
      convert({HBURST, HTRANS}, next_state); // Set next state
			if (HREADY != 1'b1 && state != next_state) begin
				next_state = state;
				write_error = 1'b1;
			end
    end

  endcase

end

task convert;
input reg [4:0] numeric_state;
output stateType state;
begin
	$display("........CONVERTING...........");
	case (numeric_state)
    5'b00000: state = S1;
    5'b00001: state = S2;
    5'b00010: state = S3;
    5'b00011: state = S4;
    5'b00100: state = S5;
    5'b00101: state = S6;
    5'b00110: state = S7;
    5'b00111: state = S8;
    5'b01000: state = S9;
    5'b01001: state = S10;
    5'b01010: state = S11;
    5'b01011: state = S12;
    5'b01100: state = S13;
    5'b01101: state = S14;
    5'b01110: state = S15;
    5'b01111: state = S16;
    5'b10000: state = S17;
    5'b10001: state = S18;
    5'b10010: state = S19;
    5'b10011: state = S20;
    5'b10100: state = S21;
    5'b10101: state = S22;
    5'b10110: state = S23;
    5'b10111: state = S24;
    5'b11000: state = S25;
    5'b11001: state = S26;
    5'b11010: state = S27;
    5'b11011: state = S28;
    5'b11100: state = S29;
    5'b11101: state = S30;
    5'b11110: state = S31;
    5'b11111: state = S32;
	endcase
end
endtask

endmodule // slave_write
