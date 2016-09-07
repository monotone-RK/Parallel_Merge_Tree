/******************************************************************************/
/* PMT(P), a P-port parallel merge tree                   ArchLab. TOKYO TECH */
/*                                                         Version 2016-06-01 */
/******************************************************************************/
`default_nettype none
  
  
/***** Compare-and-exchange (CAE)                                         *****/
/******************************************************************************/
module CAE #(parameter               WIDTH = 64)
            (input  wire [WIDTH-1:0] DIN0,
             input  wire [WIDTH-1:0] DIN1,
             output wire [WIDTH-1:0] DOUT0,
             output wire [WIDTH-1:0] DOUT1);
    
  function [WIDTH-1:0] mux;
    input [WIDTH-1:0] a;
    input [WIDTH-1:0] b;
    input             sel;
    begin
      case (sel)
        1'b0: mux = a;
        1'b1: mux = b;
      endcase
    end
  endfunction

  wire comp_rslt = (DIN0[31:0] < DIN1[31:0]);
  
  assign DOUT0 = mux(DIN1, DIN0, comp_rslt);
  assign DOUT1 = mux(DIN0, DIN1, comp_rslt);
  
endmodule


/***** Compare-and-select (CAS)                                           *****/
/******************************************************************************/
module CAS #(parameter               WIDTH = 64)
            (input  wire [WIDTH-1:0] DIN0,
             input  wire [WIDTH-1:0] DIN1,
             output wire [WIDTH-1:0] DOUT);

  function [WIDTH-1:0] mux;
    input [WIDTH-1:0] a;
    input [WIDTH-1:0] b;
    input             sel;
    begin
      case (sel)
        1'b0: mux = a;
        1'b1: mux = b;
      endcase
    end
  endfunction
  
  wire comp_rslt = (DIN0[31:0] < DIN1[31:0]);
  assign DOUT = mux(DIN1, DIN0, comp_rslt);
  
endmodule   


/***** A selection feedback generator                                     *****/
/******************************************************************************/
module SFGEN #(parameter               WIDTH = 64)
              (input  wire [WIDTH-1:0] DIN0,
               input  wire [WIDTH-1:0] DIN1,
               output wire             S);
  
  assign S = (DIN0[31:0] < DIN1[31:0]);
  
endmodule


/***** A 2P-to-P Bitonic partial merger                                   *****/
/******************************************************************************/
module BPM_2P_to_P #(parameter                              P_LOG = 2,
                     parameter                              WIDTH = 64)
                    (input  wire                            CLK,
                     input  wire                            RST_IN,
                     input  wire                            DRIVE,
                     input  wire [WIDTH*(1<<(P_LOG+1))-1:0] DIN,
                     input  wire                            DINEN,
                     output wire [(1<<P_LOG)-1:0]           S_FB,
                     output wire  [WIDTH*(1<<P_LOG)-1:0]    DOUT,
                     output wire                            DOUTEN);

  // buffering reset signal
  reg RST;
  always @(posedge CLK) RST <= RST_IN;

  reg  [WIDTH*(1<<P_LOG)-1:0] pd [P_LOG:0];  // pipeline regester for data
  reg                         pc [P_LOG:0];  // pipeline regester for control
  
  reg [WIDTH*(1<<(P_LOG+1))-1:0] din;
  always @(posedge CLK) if (DRIVE) din <= DIN;

  reg dinen;
  always @(posedge CLK) begin
    if      (RST)   dinen <= 0;
    else if (DRIVE) dinen <= DINEN;
  end

  genvar i, j, k;
  generate
    for (j=0; j<(1<<P_LOG); j=j+1) begin
      SFGEN #(WIDTH) sfgen(DIN[WIDTH*(j+1)-1:WIDTH*j], DIN[WIDTH*((1<<(P_LOG+1))-j)-1:WIDTH*((1<<(P_LOG+1))-(j+1))], S_FB[j]);
    end
  endgenerate
  
  generate
    for (i=0; i<(P_LOG+1); i=i+1) begin: stage
      wire [WIDTH*(1<<P_LOG)-1:0] dout;
      if (i == 0) begin
        for (j=0; j<(1<<P_LOG); j=j+1) begin
          CAS #(WIDTH) cas(din[WIDTH*(j+1)-1:WIDTH*j], 
                           din[WIDTH*((1<<(P_LOG+1))-j)-1:WIDTH*((1<<(P_LOG+1))-(j+1))], 
                           dout[WIDTH*(j+1)-1:WIDTH*j]);
        end
      end else begin
        for (k=0; k<(1<<(i-1)); k=k+1) begin
          for (j=0; j<(1<<(P_LOG-i)); j=j+1) begin
            CAE #(WIDTH) cae(pd[i-1][WIDTH*((j+1)+k*(1<<(P_LOG-(i-1))))-1:WIDTH*(j+k*(1<<(P_LOG-(i-1))))], 
                             pd[i-1][WIDTH*((j+1)+(1<<(P_LOG-i))+k*(1<<(P_LOG-(i-1))))-1:WIDTH*(j+(1<<(P_LOG-i))+k*(1<<(P_LOG-(i-1))))], 
                             dout[WIDTH*((j+1)+k*(1<<(P_LOG-(i-1))))-1:WIDTH*(j+k*(1<<(P_LOG-(i-1))))], 
                             dout[WIDTH*((j+1)+(1<<(P_LOG-i))+k*(1<<(P_LOG-(i-1))))-1:WIDTH*(j+(1<<(P_LOG-i))+k*(1<<(P_LOG-(i-1))))]);
          end
        end
      end
      always @(posedge CLK) if (DRIVE) pd[i] <= dout;
    end
  endgenerate
    
  integer p;
  always @(posedge CLK) begin
    if (RST) begin
      for (p=0; p<(P_LOG+1); p=p+1) pc[p] <= 0;
    end else if (DRIVE) begin
      pc[0] <= dinen;
      for (p=1; p<(P_LOG+1); p=p+1) pc[p] <= pc[p-1];
    end
  end

  assign DOUT   = pd[P_LOG];
  assign DOUTEN = pc[P_LOG];
  
endmodule


/***** A rate converter                                                   *****/
/******************************************************************************/
module RATE_CONVERTER #(parameter                    P_LOG = 2)
                       (input  wire [(1<<P_LOG)-1:0] S,
                        output wire [(1<<P_LOG):0]   M);
  
  genvar i;
  generate
    for (i=0; i<(1<<P_LOG)+1; i=i+1) begin
      if      (i == 0)          assign M[i] = ~S[i];
      else if (i == (1<<P_LOG)) assign M[i] = S[i-1];
      else                      assign M[i] = (~S[i]&S[i-1]);
    end
  endgenerate
  
endmodule


/***** An output xbar                                                     *****/
/******************************************************************************/
module XBAR_OUT #(parameter                          P_LOG = 2,
                  parameter                          WIDTH = 64)
                 (input  wire                        CLK,
                  input  wire                        RST,
                  input  wire                        DRIVE,
                  input  wire [(1<<P_LOG):0]         OFFSET,
                  input  wire [WIDTH*(1<<P_LOG)-1:0] DIN,
                  input  wire [(1<<P_LOG)-1:0]       S_IN,
                  output reg  [WIDTH*(1<<P_LOG)-1:0] DOUT,
                  output reg  [(1<<P_LOG)-1:0]       S_OUT);

  function [(1<<P_LOG)-1:0] mux;
    input [(1<<P_LOG)-1:0] a;
    input [(1<<P_LOG)-1:0] b;
    input                  sel;
    begin
      case (sel)
        1'b0: mux = a;
        1'b1: mux = b;
      endcase
    end
  endfunction
  
  // reg  [(1<<P_LOG)-1:0]   barrel_shifter;
  // wire [(4*1<<P_LOG)-1:0] mult_out = {barrel_shifter,barrel_shifter} * OFFSET;
  // // wire [(4*1<<P_LOG)-1:0] mult_out;
  // // MULT_MACRO #(.DEVICE("7SERIES"), .LATENCY(0), .WIDTH_A((2*1<<P_LOG)), .WIDTH_B((2*1<<P_LOG)))
  // // multiplier(.P(mult_out), .A({barrel_shifter,barrel_shifter}), .B(OFFSET), .CE(DRIVE), .CLK(CLK), .RST(RST));
                         
  // always @(posedge CLK) begin
  //   if      (RST)   barrel_shifter <= 1;
  //   else if (DRIVE) barrel_shifter <= mult_out[(2*1<<P_LOG)-1:(1<<P_LOG)];
  // end
  
  // generate  // would like to be improved
  //   if (P_LOG == 1) begin
  //     always @(*) begin
  //       case (barrel_shifter)
  //         2'b01:   begin DOUT = DIN;                                                S_OUT = S_IN;                             end
  //         2'b10:   begin DOUT = {DIN[WIDTH*1-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*1]}; S_OUT = {S_IN[0:0],S_IN[(1<<P_LOG)-1:1]}; end
  //         default: begin DOUT = 0;                                                  S_OUT = 0;                                end
  //       endcase
  //     end
  //   end else if (P_LOG == 2) begin
  //     always @(*) begin
  //       case (barrel_shifter)
  //         4'b0001: begin DOUT = DIN;                                                S_OUT = S_IN;                             end
  //         4'b0010: begin DOUT = {DIN[WIDTH*1-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*1]}; S_OUT = {S_IN[0:0],S_IN[(1<<P_LOG)-1:1]}; end
  //         4'b0100: begin DOUT = {DIN[WIDTH*2-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*2]}; S_OUT = {S_IN[1:0],S_IN[(1<<P_LOG)-1:2]}; end
  //         4'b1000: begin DOUT = {DIN[WIDTH*3-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*3]}; S_OUT = {S_IN[2:0],S_IN[(1<<P_LOG)-1:3]}; end
  //         default: begin DOUT = 0;                                                  S_OUT = 0;                                end
  //       endcase
  //     end
  //   end else if (P_LOG == 3) begin
  //     always @(*) begin
  //       case (barrel_shifter)
  //         8'b00000001: begin DOUT = DIN;                                                S_OUT = S_IN;                             end
  //         8'b00000010: begin DOUT = {DIN[WIDTH*1-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*1]}; S_OUT = {S_IN[0:0],S_IN[(1<<P_LOG)-1:1]}; end
  //         8'b00000100: begin DOUT = {DIN[WIDTH*2-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*2]}; S_OUT = {S_IN[1:0],S_IN[(1<<P_LOG)-1:2]}; end
  //         8'b00001000: begin DOUT = {DIN[WIDTH*3-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*3]}; S_OUT = {S_IN[2:0],S_IN[(1<<P_LOG)-1:3]}; end
  //         8'b00010000: begin DOUT = {DIN[WIDTH*4-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*4]}; S_OUT = {S_IN[3:0],S_IN[(1<<P_LOG)-1:4]}; end
  //         8'b00100000: begin DOUT = {DIN[WIDTH*5-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*5]}; S_OUT = {S_IN[4:0],S_IN[(1<<P_LOG)-1:5]}; end
  //         8'b01000000: begin DOUT = {DIN[WIDTH*6-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*6]}; S_OUT = {S_IN[5:0],S_IN[(1<<P_LOG)-1:6]}; end
  //         8'b10000000: begin DOUT = {DIN[WIDTH*7-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*7]}; S_OUT = {S_IN[6:0],S_IN[(1<<P_LOG)-1:7]}; end
  //         default:     begin DOUT = 0;                                                  S_OUT = 0;                                end
  //       endcase
  //     end
  //   end
  // endgenerate
  
  reg  [(1<<P_LOG)-1:0] barrel_shifter;
  generate  // would like to be improved
    if (P_LOG == 1) begin
      reg                   drive;
      reg  [(1<<P_LOG):0]   offset;
      wire [(1<<P_LOG)-1:0] state = mux(barrel_shifter, ~barrel_shifter, (drive && offset[P_LOG]));
      always @(posedge CLK) offset         <= OFFSET;
      always @(posedge CLK) drive          <= (RST) ? 0 : DRIVE;
      always @(posedge CLK) barrel_shifter <= (RST) ? 1 : state;
      always @(*) begin
        case (state)
          2'b01:   begin DOUT = DIN;                                                S_OUT = S_IN;                             end
          2'b10:   begin DOUT = {DIN[WIDTH*1-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*1]}; S_OUT = {S_IN[0:0],S_IN[(1<<P_LOG)-1:1]}; end
          default: begin DOUT = 0;                                                  S_OUT = 0;                                end
        endcase
      end
    end else if (P_LOG == 2) begin
      always @(posedge CLK) begin
        if (RST) begin  
          barrel_shifter <= 1;
        end else if (DRIVE) begin
          case (OFFSET[3:1])
            3'b001: barrel_shifter <= {barrel_shifter[2:0],barrel_shifter[3:3]};
            3'b010: barrel_shifter <= {barrel_shifter[1:0],barrel_shifter[3:2]};
            3'b100: barrel_shifter <= {barrel_shifter[0:0],barrel_shifter[3:1]};
          endcase
        end
      end
      always @(*) begin
        case (barrel_shifter)
          4'b0001: begin DOUT = DIN;                                                S_OUT = S_IN;                             end
          4'b0010: begin DOUT = {DIN[WIDTH*1-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*1]}; S_OUT = {S_IN[0:0],S_IN[(1<<P_LOG)-1:1]}; end
          4'b0100: begin DOUT = {DIN[WIDTH*2-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*2]}; S_OUT = {S_IN[1:0],S_IN[(1<<P_LOG)-1:2]}; end
          4'b1000: begin DOUT = {DIN[WIDTH*3-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*3]}; S_OUT = {S_IN[2:0],S_IN[(1<<P_LOG)-1:3]}; end
          default: begin DOUT = 0;                                                  S_OUT = 0;                                end
        endcase
      end
    end else if (P_LOG == 3) begin
      always @(posedge CLK) begin
        if (RST) begin  
          barrel_shifter <= 1;
        end else if (DRIVE) begin
          case (OFFSET[7:1])
            7'b0000001: barrel_shifter <= {barrel_shifter[6:0],barrel_shifter[7:7]};
            7'b0000010: barrel_shifter <= {barrel_shifter[5:0],barrel_shifter[7:6]};
            7'b0000100: barrel_shifter <= {barrel_shifter[4:0],barrel_shifter[7:5]};
            7'b0001000: barrel_shifter <= {barrel_shifter[3:0],barrel_shifter[7:4]};
            7'b0010000: barrel_shifter <= {barrel_shifter[2:0],barrel_shifter[7:3]};
            7'b0100000: barrel_shifter <= {barrel_shifter[1:0],barrel_shifter[7:2]};
            7'b1000000: barrel_shifter <= {barrel_shifter[0:0],barrel_shifter[7:1]};
          endcase
        end
      end
      always @(*) begin
        case (barrel_shifter)
          8'b00000001: begin DOUT = DIN;                                                S_OUT = S_IN;                             end
          8'b00000010: begin DOUT = {DIN[WIDTH*1-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*1]}; S_OUT = {S_IN[0:0],S_IN[(1<<P_LOG)-1:1]}; end
          8'b00000100: begin DOUT = {DIN[WIDTH*2-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*2]}; S_OUT = {S_IN[1:0],S_IN[(1<<P_LOG)-1:2]}; end
          8'b00001000: begin DOUT = {DIN[WIDTH*3-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*3]}; S_OUT = {S_IN[2:0],S_IN[(1<<P_LOG)-1:3]}; end
          8'b00010000: begin DOUT = {DIN[WIDTH*4-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*4]}; S_OUT = {S_IN[3:0],S_IN[(1<<P_LOG)-1:4]}; end
          8'b00100000: begin DOUT = {DIN[WIDTH*5-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*5]}; S_OUT = {S_IN[4:0],S_IN[(1<<P_LOG)-1:5]}; end
          8'b01000000: begin DOUT = {DIN[WIDTH*6-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*6]}; S_OUT = {S_IN[5:0],S_IN[(1<<P_LOG)-1:6]}; end
          8'b10000000: begin DOUT = {DIN[WIDTH*7-1:0],DIN[WIDTH*(1<<P_LOG)-1:WIDTH*7]}; S_OUT = {S_IN[6:0],S_IN[(1<<P_LOG)-1:7]}; end
          default:     begin DOUT = 0;                                                  S_OUT = 0;                                end
        endcase
      end
    end
  endgenerate
  
endmodule


/***** An SRL-based FIFO                                                  *****/
/******************************************************************************/
module SRL_FIFO #(parameter                    FIFO_SIZE  = 4,   // size in log scale, 4 for 16 entry
                  parameter                    FIFO_WIDTH = 64)  // fifo width in bit
                 (input  wire                  CLK,
                  input  wire                  RST,
                  input  wire                  enq,
                  input  wire                  deq,
                  input  wire [FIFO_WIDTH-1:0] din,
                  output wire [FIFO_WIDTH-1:0] dot,
                  output wire                  emp,
                  output wire                  full,
                  output reg  [FIFO_SIZE:0]    cnt);

  reg  [FIFO_SIZE-1:0]  head;
  reg  [FIFO_WIDTH-1:0] mem [(1<<FIFO_SIZE)-1:0];
  
  assign emp  = (cnt==0);
  assign full = (cnt==(1<<FIFO_SIZE));
  assign dot  = mem[head];
    
  always @(posedge CLK) begin
    if (RST) begin
      cnt  <= 0;
      head <= {(FIFO_SIZE){1'b1}};
    end else begin
      case ({enq, deq})
        2'b01: begin cnt <= cnt - 1; head <= head - 1; end
        2'b10: begin cnt <= cnt + 1; head <= head + 1; end
      endcase
    end
  end

  integer i;
  always @(posedge CLK) begin
    if (enq) begin
      mem[0] <= din;
      for (i=1; i<(1<<FIFO_SIZE); i=i+1) mem[i] <= mem[i-1];
    end
  end
  
endmodule


/***** An FIFO for multirate mergers                                      *****/
/******************************************************************************/
module FIFOs #(parameter                              P_LOG = 2,
               parameter                              D_LOG = 4,
               parameter                              WIDTH = 64)
              (input  wire                            CLK,
               input  wire                            RST_IN,
               input  wire                            enq,
               input  wire [(1<<P_LOG)-1:0]           S,
               input  wire                            S_EN,
               input  wire [WIDTH*(1<<(P_LOG-1))-1:0] din,
               output wire [WIDTH*(1<<P_LOG)-1:0]     dot,
               output wire [(1<<P_LOG)-1:0]           emp,
               output wire [(1<<P_LOG)-1:0]           full);
  
  function mux1;
    input a;
    input b;
    input sel;
    begin
      case (sel)
        1'b0: mux1 = a;
        1'b1: mux1 = b;
      endcase
    end
  endfunction
  
  // buffering reset signal
  reg RST;
  always @(posedge CLK) RST <= RST_IN;
  
  // Registers and Wires for an input xbar 
  // ################################################################
  wire [1:0]                  dinen;       // enq input signal
  reg  [1:0]                  enq_sel;     // enq selector
  reg [WIDTH*(1<<P_LOG)-1:0]  xbar_i_dot;  // data emitted from an input xbar

  // Wires for SRL-based FIFOs
  // ################################################################
  wire [WIDTH*(1<<P_LOG)-1:0] fifo_dot;    // output data of SRL-based FIFOs
  
  // Wires for an output xbar a rate converter and outupt xbar
  // ################################################################
  wire [(1<<P_LOG):0]         offset;      // offset generated from a rate converter
  wire [WIDTH*(1<<P_LOG)-1:0] xbar_o_dot;  // output data of SRL-based FIFOs
  wire [(1<<P_LOG)-1:0]       s;           // selection feedback signals
  
  // An input xbar
  ////////////////////////////////////////////////////////////////////////////////////////////////
  assign dinen = {(2){enq}} & enq_sel;

  always @(posedge CLK) begin
    if      (RST) enq_sel <= 2'b01;
    else if (enq) enq_sel <= ~enq_sel;
  end

  always @(*) begin
    case (enq_sel)
      2'b01:   begin xbar_i_dot = {{(WIDTH*(1<<(P_LOG-1))){1'b0}},din}; end
      2'b10:   begin xbar_i_dot = {din,{(WIDTH*(1<<(P_LOG-1))){1'b0}}}; end
      default: begin xbar_i_dot = 0;                                    end
    endcase
  end  

  // SRL-based FIFOs
  ////////////////////////////////////////////////////////////////////////////////////////////////
  genvar i;
  generate
    for (i=0; i<(1<<P_LOG); i=i+1) begin: fifo
      wire e = mux1(dinen[1], dinen[0], (i<(1<<(P_LOG-1))));
      SRL_FIFO #(D_LOG, WIDTH) srl_fifo(.CLK(CLK), .RST(RST), .enq(e), .deq(s[i]), .din(xbar_i_dot[WIDTH*(i+1)-1:WIDTH*i]), 
                                        .dot(fifo_dot[WIDTH*(i+1)-1:WIDTH*i]), .emp(emp[i]), .full(full[i]));
    end
  endgenerate
  
  // A rate converter and output xbar
  ////////////////////////////////////////////////////////////////////////////////////////////////
  RATE_CONVERTER #(P_LOG) rate_converter(S, offset);
  XBAR_OUT #(P_LOG, WIDTH) xbar_out(CLK, RST, S_EN, offset, fifo_dot, S, xbar_o_dot, s);
  
  assign dot = xbar_o_dot;
  
endmodule


/***** MM(P), a P-port multirate merger                                             *****/
/****************************************************************************************/
module MM_P #(parameter                          P_LOG = 2,
              parameter                          D_LOG = 4,
              parameter                          WIDTH = 64)
             (input  wire                        CLK,
              input  wire                        RST_IN,
              input  wire                        IN_FULL,
              input  wire [WIDTH*(1<<P_LOG)-1:0] DIN,
              input  wire [1:0]                  DINEN,
              output wire [WIDTH*(1<<P_LOG)-1:0] DOUT,
              output wire                        DOUTEN,
              output wire [1:0]                  FULL);
  
  wire [WIDTH*(1<<P_LOG)-1:0] fifo_mmp_dot01, fifo_mmp_dot00; 
  wire [(1<<P_LOG)-1:0]       fifo_mmp_emp01, fifo_mmp_emp00; 
  wire [(1<<P_LOG)-1:0]       fifo_mmp_ful01, fifo_mmp_ful00;
  
  wire [WIDTH*(1<<(P_LOG+1))-1:0] bpm_din   = {fifo_mmp_dot01,fifo_mmp_dot00};
  wire                            bpm_dinen = ~|{fifo_mmp_emp01,fifo_mmp_emp00,IN_FULL};  // (~|{fifo_mmp_emp01,fifo_mmp_emp00}) && !IN_FULL;
  wire [WIDTH*(1<<P_LOG)-1:0]     bpm_dot;
  wire                            bpm_doten;
  
  wire [(1<<P_LOG)-1:0] s_fb;
  wire [(1<<P_LOG)-1:0] s_fb_inv;
  genvar i;
  generate
    for (i=0; i<(1<<P_LOG); i=i+1) begin
      assign s_fb_inv[i] = ~s_fb[(1<<P_LOG)-(i+1)];
    end
  endgenerate
  
  wire [(1<<P_LOG)-1:0] s_fb_00 = {(1<<P_LOG){bpm_dinen}} & s_fb;
  wire [(1<<P_LOG)-1:0] s_fb_01 = {(1<<P_LOG){bpm_dinen}} & s_fb_inv;

  FIFOs #(P_LOG, D_LOG, WIDTH) fifo_mmp_00(CLK, RST_IN, DINEN[0], s_fb_00, bpm_dinen, DIN[WIDTH*(1<<(P_LOG-1))-1:0], 
                                           fifo_mmp_dot00, fifo_mmp_emp00, fifo_mmp_ful00);
  FIFOs #(P_LOG, D_LOG, WIDTH) fifo_mmp_01(CLK, RST_IN, DINEN[1], s_fb_01, bpm_dinen, DIN[WIDTH*(1<<P_LOG)-1:WIDTH*(1<<(P_LOG-1))], 
                                           fifo_mmp_dot01, fifo_mmp_emp01, fifo_mmp_ful01);
  
  BPM_2P_to_P #(P_LOG, WIDTH) bpm_2p_to_p(CLK, RST_IN, !IN_FULL, bpm_din, bpm_dinen, s_fb, bpm_dot, bpm_doten);

  assign DOUT   = bpm_dot;
  assign DOUTEN = (bpm_doten && !IN_FULL);
  assign FULL   = {((|fifo_mmp_ful01[(1<<(P_LOG))-1:(1<<(P_LOG-1))]) & (|fifo_mmp_ful01[(1<<(P_LOG-1))-1:0])), 
                   ((|fifo_mmp_ful00[(1<<(P_LOG))-1:(1<<(P_LOG-1))]) & (|fifo_mmp_ful00[(1<<(P_LOG-1))-1:0]))};
  
endmodule


/***** PMT(P), an P-port parallel merge-tree                                        *****/
/****************************************************************************************/
module PMT_P #(parameter                          P_LOG = 2,
               parameter                          D_LOG = 4,
               parameter                          WIDTH = 64)
              (input  wire                        CLK,
               input  wire                        RST_IN,
               input  wire                        IN_FULL,
               input  wire [WIDTH*(1<<P_LOG)-1:0] DIN,
               input  wire [(1<<P_LOG)-1:0]       DINEN,
               output wire [WIDTH*(1<<P_LOG)-1:0] DOUT,
               output wire                        DOUTEN,
               output wire [(1<<P_LOG)-1:0]       FULL);

  genvar i, j;
  generate
    for (i=0; i<P_LOG; i=i+1) begin: level
      wire [(1<<(P_LOG-(i+1)))-1:0] mm_p_in_full;
      wire [WIDTH*(1<<P_LOG)-1:0]   mm_p_din;
      wire [(1<<(P_LOG-i))-1:0]     mm_p_dinen;
      wire [WIDTH*(1<<P_LOG)-1:0]   mm_p_dot;
      wire [(1<<(P_LOG-(i+1)))-1:0] mm_p_doten;
      wire [(1<<(P_LOG-i))-1:0]     mm_p_full;
      for (j=0; j<(1<<(P_LOG-(i+1))); j=j+1) begin: mm
        MM_P #((i+1), D_LOG, WIDTH) mm_p(CLK, RST_IN, mm_p_in_full[j], mm_p_din[WIDTH*(1<<(i+1))*(j+1)-1:WIDTH*(1<<(i+1))*j], mm_p_dinen[2*(j+1)-1:2*j],
                                         mm_p_dot[WIDTH*(1<<(i+1))*(j+1)-1:WIDTH*(1<<(i+1))*j], mm_p_doten[j], mm_p_full[2*(j+1)-1:2*j]);
      end
    end
  endgenerate

  generate
    for (i=0; i<(P_LOG-1); i=i+1) begin
      assign level[i].mm_p_in_full = level[i+1].mm_p_full;
      assign level[i+1].mm_p_din   = level[i].mm_p_dot;
      assign level[i+1].mm_p_dinen = level[i].mm_p_doten;
    end
  endgenerate
  
  assign level[P_LOG-1].mm_p_in_full = IN_FULL;
  assign level[0].mm_p_din           = DIN;
  assign level[0].mm_p_dinen         = DINEN;
  assign DOUT                        = level[P_LOG-1].mm_p_dot;
  assign DOUTEN                      = level[P_LOG-1].mm_p_doten;
  assign FULL                        = level[0].mm_p_full;
  
endmodule
`default_nettype wire
