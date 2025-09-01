module tt_um_perceptron_mac (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        ena,
    input  wire [7:0]  ui_in,
    output wire [7:0]  uo_out,
    input  wire [7:0]  uio_in,
    output wire [7:0]  uio_out,
    output wire [7:0]  uio_oe
);
    
    // Unused bidirectional ios set to high z, uio_in unused
    assign uio_out = 8'h00;
    assign uio_oe  = 8'h00;  
    
    //unpack inputs to 4 bits
    wire signed [3:0] x0 = ui_in[3:0];
    wire signed [3:0] x1 = ui_in[7:4];

   
    // hardcoded weights and bias (signed)
    // y = sign( 3*x0 - 2*x1 + 1 )
    localparam signed [3:0] W0   =  4'sd3;
    localparam signed [3:0] W1   = -4'sd2;
    localparam signed [7:0] BIAS =  8'sd1;

    // calling MAC instance
    reg        mac_start;
    wire       mac_busy;
    reg signed [7:0] acc_init;
    reg signed [3:0] mac_a, mac_b;
    wire signed [7:0] acc_out;

    tiny_mac_sequential u_mac (
        .clk(clk),
        .rst_n(rst_n),
        .ena(ena),
        .start(mac_start),
        .busy(mac_busy),
        .a(mac_a),
        .b(mac_b),
        .acc_init(acc_init),
        .acc_out(acc_out)
    );

    
    //FSM: S_BIAS --> S_MAC0 --> S_MAC1 --> S_DONE and repeat
  
    localparam [1:0] S_BIAS = 2'd0,
                     S_MAC0 = 2'd1,
                     S_MAC1 = 2'd2,
                     S_DONE = 2'd3;
    reg [1:0] state, next_state;

    // Output registers
    reg  signed [7:0] sum_reg;  // latched accumulator for debug/LEDs
    reg               y_reg;    // perceptron output

    always @* begin
        // defaults
        next_state = state;
        mac_start  = 1'b0;
        acc_init   = 8'sd0;
        mac_a      = 4'sd0;
        mac_b      = 4'sd0;

        case (state)
            S_BIAS: begin
                // load bias then multiply first 4bits
                acc_init  = BIAS;
                mac_a     = x0;
                mac_b     = W0;
                mac_start = 1'b1;      
                next_state = S_MAC0;
            end
            S_MAC0: begin
                //wait MAC  idle, then start second 4bits multiplication
                if (!mac_busy) begin
                    acc_init  = acc_out; // carry over
                    mac_a     = x1;
                    mac_b     = W1;
                    mac_start = 1'b1;    // BIAS + x0*W0 + x1*W1
                    next_state = S_MAC1;
                end
            end
            S_MAC1: begin
                // wait MAC, then decide sign 
                if (!mac_busy) begin
                    next_state = S_DONE;
                end
            end
            S_DONE: begin
                // Hold result n repeat
                next_state = S_BIAS;
            end
            default: next_state = S_BIAS;
        endcase
    end

    // State and outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= S_BIAS;
            sum_reg <= 8'sd0;
            y_reg   <= 1'b0;
        end else if (ena) begin
            state <= next_state;
            if (state == S_MAC1 && !mac_busy) begin
                //finished second multiply, so latch and classify 1 or 0
                sum_reg <= acc_out;
                y_reg   <= (acc_out >= 0);
            end
        end
    end 
    
    assign uo_out[0]   = y_reg;
    assign uo_out[7:1] = sum_reg[7:1];

endmodule


// -----------------------------------------------------------------------------
// Tiny sequential MAC (signed 4x4 -> 8-bit) with accumulate
// One-cycle multiply + add when 'start' is pulsed and 'ena' is high.
// 'busy' stays high for exactly one cycle (simple handshake).
// -----------------------------------------------------------------------------
module tiny_mac_sequential (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        ena,
    input  wire        start,
    output reg         busy,
    input  wire signed [3:0] a,
    input  wire signed [3:0] b,
    input  wire signed [7:0] acc_init,
    output reg  signed [7:0] acc_out
);
    wire signed [7:0] prod = a * b; // 4x4 signed multiply -> 8-bit

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy    <= 1'b0;
            acc_out <= 8'sd0;
        end else if (ena) begin
            if (start) begin
                busy    <= 1'b1;                 // indicate work this cycle
                acc_out <= acc_init + prod;      // accumulate
            end else begin
                busy    <= 1'b0;
            end
        end
    end
endmodule
