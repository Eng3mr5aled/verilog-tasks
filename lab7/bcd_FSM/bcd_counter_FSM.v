module bcd_counter_FSM( 
    input clk,   
    input reset,  
    output reg [3:0] count 
);

    // parameter states
    parameter S0 = 2'b00,
              S1 = 2'b01;
              
    reg [1:0] State;

    // BCD counter
    always @(posedge clk or posedge reset) begin
        if (reset) begin 
            // reset the state to initial state and output to zeros
            State <= S0;
            count <= 4'b0000;
        end else begin
            case (State) // state transitions
                S0: begin
                    State <= S1; // move to state S1 (start counts)
                end
                
                S1: begin
                    if (count < 9) begin
                        count <= count + 1'b1; // addition
                    end else begin
                        State <= S0; // move to S0 (re counts)
                        count <= 4'b0000; // corrected typo: count instead of counts
                    end
                end
                
                default: begin
                    State <= S0; // Added missing semicolon and changed = to <=
                end
            endcase
        end
    end
    
endmodule