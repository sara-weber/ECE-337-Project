module serpent_fsm
(
	input wire clk,
	input wire go,
	output logic [2:0] sBoxSelect,
	output logic [2:0] keyBoxSelect,
	output logic [4:0] round,
	output logic rst,
	output logic keyLock,
	output logic fsmGo,
	output logic done
);

typedef enum bit [3:0] {IDLE, START, R0, R1, R2, R3, R4, R5, R6, NR7, FR7, END} stateType;
stateType state;
stateType nextState;
reg [2:0] tick; //Start must be held for 8 clocks, Every other active state for four. Allows for precise timing
reg [2:0] newTick;
reg [2:0] nsBoxSelect;
reg [2:0] nkeyBoxSelect;
reg [4:0] nround;
always_ff @ (posedge clk)
begin
	if(go != 1 && state == IDLE)
	begin
		state <= IDLE;
		tick <= 0;
		sBoxSelect <= 0;
		keyBoxSelect <= 0;
		round <= 0;
	end
	else
	begin
		state <= nextState;
		tick <= newTick;
		sBoxSelect <= nsBoxSelect;
		keyBoxSelect <= nkeyBoxSelect;
		round <= nround;
	end
end

always_comb
begin
	nextState = IDLE;
	done = 0;
	keyLock = 0;
	rst = 0;
	fsmGo = 0;
	nround = round;
	nsBoxSelect = sBoxSelect;
	nkeyBoxSelect = keyBoxSelect;
	newTick = tick + 1;
	case(state)
	IDLE:begin //Self-explanitory
		keyLock = 0;
		fsmGo = 0;
		nround = 5'b0;
		nsBoxSelect = 3'd0;
		nkeyBoxSelect = 3'd3;
		rst = 1;
		if(go == 1)
		begin
			nextState = START;
			rst = 0;
		end
		else
		begin
			nextState = IDLE;
		end
	end
	START:begin //Primes the key-blocks, allows keys to generate
		keyLock = 0;
		if(tick == 7)
		begin
			nextState = R0;
		end
		else
		begin
			
			nextState = START;
		end
	end
	R0:begin //Each set of 8 rounds iterates through all 8 s-boxes. R0-5 are identical. R6 must split between the normal round 7 and the final round 7
		keyLock = 0;
		if(tick == 0)
		begin
			keyLock = 1;
			nextState = R0;
		end
		else if(tick == 1) //Starts encryption
		begin
			fsmGo = 1;
			nextState = R0;
		end
		else	if(tick == 3)
		begin
			nextState = R1;
			newTick = 0;
			nround = round + 1;
			nsBoxSelect = sBoxSelect + 1;
			nkeyBoxSelect = keyBoxSelect - 1; 
		end
		else
		begin
			nextState = R0;
		end
	end
	R1:begin
		keyLock = 0;
		if(tick == 0)
		begin
			keyLock = 1;
			nextState = R0;
		end
		if(tick == 3)
		begin
			nextState = R2;
			newTick = 0;
			nround = round + 1;
			nsBoxSelect = sBoxSelect + 1;
			nkeyBoxSelect = keyBoxSelect - 1; 
		end
		else
		begin
			nextState = R1;
		end
	end
	R2:begin
		keyLock = 0;
		if(tick == 0)
		begin
			keyLock = 1;
			nextState = R2;
		end
		if(tick == 3)
		begin
			nextState = R3;
			newTick = 0;
			nround = round + 1;
			nsBoxSelect = sBoxSelect + 1;
			nkeyBoxSelect = keyBoxSelect - 1;
		end
		else
		begin
			nextState = R2;
		end
	end
	R3:begin
		keyLock = 0;
		if(tick == 0)
		begin
			keyLock = 1;
			nextState = R3;
		end
		if(tick == 3)
		begin
			nextState = R4;
			newTick = 0;
			nround = round + 1;
			nsBoxSelect = sBoxSelect + 1;
			nkeyBoxSelect = keyBoxSelect - 1;
		end
		else
		begin
			nextState = R3;
			
		end
	end
	R4:begin
		keyLock = 0;
		if(tick == 0)
		begin
			keyLock = 1;
			nextState = R4;
		end
		if(tick == 3)
		begin
			nextState = R5;
			newTick = 0;
			nround = round + 1;
			nsBoxSelect = sBoxSelect + 1;
			nkeyBoxSelect = keyBoxSelect - 1;
		end
		else
		begin
			nextState = R4;
			
		end
	end
	R5:begin
		keyLock = 0;
		if(tick == 0)
		begin
			keyLock = 1;
			nextState = R5;
		end
		if(tick == 3)
		begin
			nextState = R6;
			newTick = 0;
			nround = round + 1;
			nsBoxSelect = sBoxSelect + 1;
			nkeyBoxSelect = keyBoxSelect - 1;
		end
		else
		begin
			nextState = R5;
			
		end
	end	
	R6:begin
		keyLock = 0;
		if(tick == 0)
		begin
			keyLock = 1;
			nextState = R6;
		end
		if(tick == 3 && round > 29)
		begin
			nextState = FR7;
			newTick = 0;
			nround = round + 1;
			nsBoxSelect = sBoxSelect + 1;
			nkeyBoxSelect = keyBoxSelect - 1;
		end
		else if(tick == 3)
		begin
			nextState = NR7;
			newTick = 0;
			nround = round + 1;
			nsBoxSelect = sBoxSelect + 1;
			nkeyBoxSelect = keyBoxSelect - 1;
		end
		else
		begin
			nextState = R6;
			
		end
	end
	NR7:begin
		keyLock = 0;
		if(tick == 0)
		begin
			keyLock = 1;
			nextState = NR7;
		end
		if(tick == 3)
		begin
			nextState = R0;
			newTick = 0;
			nround = round + 1;
			nsBoxSelect = sBoxSelect + 1;
			nkeyBoxSelect = keyBoxSelect - 1;
		end
		else
		begin
			nextState = NR7;
			
		end
	end
	FR7:begin 
		keyLock = 0;
		if(tick == 0)
		begin
			keyLock = 1;
			nextState = FR7;
		end
		if(tick == 3)
		begin
			nextState = END;
			newTick = 0;
			nround = round + 1;
			nsBoxSelect = sBoxSelect + 1;
			nkeyBoxSelect = keyBoxSelect - 1;
		end
		else
		begin
			nextState = FR7;
			
		end
	end
	END:begin //After final round, dump now-encrypted text to AHB
		keyLock = 0;
		done = 1;
		if(tick == 3)
		begin
			nextState = IDLE;
			newTick = 0;
			done = 1; 
		end
		else
		begin
			
			nextState = END;
		end
	end
	default:begin
		nextState = IDLE;	
	end
endcase
end


endmodule
