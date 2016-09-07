/******************************************************************************/
/* A Test Module for a P-port parallel merge tree         ArchLab. TOKYO TECH */
/*                                                         Version 2016-06-02 */
/******************************************************************************/
`default_nettype none

`include "define.v"
  
/***** general FIFO (BRAM Version)                                                            *****/
/**************************************************************************************************/
module BFIFO #(parameter                    FIFO_SIZE  =  2, // size in log scale, 2 for 4 entry, 3 for 8 entry
               parameter                    FIFO_WIDTH = 32) // fifo width in bit
              (input  wire                  CLK, 
               input  wire                  RST, 
               input  wire                  enq, 
               input  wire                  deq, 
               input  wire [FIFO_WIDTH-1:0] din, 
               output reg  [FIFO_WIDTH-1:0] dot, 
               output wire                  emp, 
               output wire                  full, 
               output reg  [FIFO_SIZE:0]    cnt);
  
  reg [FIFO_SIZE-1:0]  head, tail;
  reg [FIFO_WIDTH-1:0] mem [(1<<FIFO_SIZE)-1:0];

  assign emp  = (cnt==0);
  assign full = (cnt==(1<<FIFO_SIZE));
  
  always @(posedge CLK) dot <= mem[head];
  
  always @(posedge CLK) begin
    if (RST) {cnt, head, tail} <= 0;
    else begin
      case ({enq, deq})
        2'b01: begin                 head<=head+1;               cnt<=cnt-1; end
        2'b10: begin mem[tail]<=din;               tail<=tail+1; cnt<=cnt+1; end
        2'b11: begin mem[tail]<=din; head<=head+1; tail<=tail+1;             end
      endcase
    end
  end
endmodule


/***** general FIFO (Distributed RAM Version)                                                 *****/
/**************************************************************************************************/
module DFIFO #(parameter                    FIFO_SIZE  =  2, // size in log scale, 2 for 4 entry, 3 for 8 entry
               parameter                    FIFO_WIDTH = 32) // fifo width in bit
              (input  wire                  CLK, 
               input  wire                  RST, 
               input  wire                  enq, 
               input  wire                  deq, 
               input  wire [FIFO_WIDTH-1:0] din, 
               output wire [FIFO_WIDTH-1:0] dot, 
               output wire                  emp, 
               output wire                  full, 
               output reg  [FIFO_SIZE:0]    cnt);
  
  reg [FIFO_SIZE-1:0]  head, tail;
  reg [FIFO_WIDTH-1:0] mem [(1<<FIFO_SIZE)-1:0];

  assign emp  = (cnt==0);
  assign full = (cnt==(1<<FIFO_SIZE));
  assign dot  = mem[head];
  
  always @(posedge CLK) begin
    if (RST) {cnt, head, tail} <= 0;
    else begin
      case ({enq, deq})
        2'b01: begin                 head<=head+1;               cnt<=cnt-1; end
        2'b10: begin mem[tail]<=din;               tail<=tail+1; cnt<=cnt+1; end
        2'b11: begin mem[tail]<=din; head<=head+1; tail<=tail+1;             end
      endcase
    end
  end
endmodule


/***** top module                                                                             *****/
/**************************************************************************************************/
module top(input  wire              CLK_P,
           input  wire              CLK_N,
           input  wire              RST_X_IN,
           output wire              TXD);

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
  
  function [32-1:0] mux32;
    input [32-1:0] a;
    input [32-1:0] b;
    input          sel;
    begin
      case (sel)
        1'b0: mux32 = a;
        1'b1: mux32 = b;
      endcase
    end
  endfunction
  
  wire CLK, RST_X_O;
  CLKRSTGEN clkrstgen(CLK_P, CLK_N, ~RST_X_IN, CLK, RST_X_O);
  wire RST = ~RST_X_O;

  wire [`RCDW*(1<<`P_LOG)-1:0] pmt_p_din;
  wire [(1<<`P_LOG)-1:0]       pmt_p_dinen;
  wire [`RCDW*(1<<`P_LOG)-1:0] pmt_p_dot;
  wire                         pmt_p_doten;
  wire [(1<<`P_LOG)-1:0]       pmt_p_full;
  
  wire                         enq    [(1<<`P_LOG)-1:0];
  wire                         deq    [(1<<`P_LOG)-1:0];
  wire [`RCDW-1:0]             im_din [(1<<`P_LOG)-1:0];
  reg  [`RCDW-1:0]             din    [(1<<`P_LOG)-1:0];
  wire                         emp    [(1<<`P_LOG)-1:0];
  wire [4:0]                   cnt    [(1<<`P_LOG)-1:0];
  
  reg [31:0]                   ecnt   [(1<<`P_LOG)-1:0];
  reg                          ecntz  [(1<<`P_LOG)-1:0];

  integer                      i;
  genvar                       j;

  wire                         txfifo_enq;
  wire                         txfifo_deq;
  wire [`RCDW*(1<<`P_LOG)-1:0] txfifo_dot;
  wire                         txfifo_emp;
  reg                          txfifo_emp_r;
  wire                         txfifo_full;
  wire [6:0]                   txfifo_cnt;
  
  reg  [`RCDW*(1<<`P_LOG)-1:0] txfifo_dot_t;
  reg  [`P_LOG-1:0]            txfifo_txcnt;
  reg  [31:0]                  datacnt;
  reg                          buf_stop;

  wire [31:0]                  lcd_data;
  wire                         lcd_we;
  wire                         rdy;
  reg  [31:0]                  lcd_cnt;
      
  reg  [31:0]                  cycle;
  reg                          cycle_lcdwe;
  reg                          cycle_send;
  
  // A counter of elapsed cycle
  /////////////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK) begin
    if      (RST)       cycle <= 0;
    else if (!buf_stop) cycle <= cycle + 1;
  end
  
  // Test pattern generator
  /////////////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK) begin
    if (RST) begin
      for (i=0; i<(1<<`P_LOG); i=i+1) begin
        if (i < (1<<(`P_LOG-1))) din[i] <= 1 + i*(`RCD_NUM >> (`P_LOG-1));
        else                     din[i] <= 2 + (i - (1<<(`P_LOG-1)))*(`RCD_NUM >> (`P_LOG-1));
      end
    end else begin
      for (i=0; i<(1<<`P_LOG); i=i+1) if (enq[i]) din[i] <= din[i] + 2;
    end
  end

  // A counter of ejected records
  /////////////////////////////////////////////////////////////////////////////////////////
  always @(posedge CLK) begin
    if (RST) begin
      for (i=0; i<(1<<`P_LOG); i=i+1) begin
        ecnt[i]  <= (`RCD_NUM >> `P_LOG);
        ecntz[i] <= 0;
      end
    end else begin
      for (i=0; i<(1<<`P_LOG); i=i+1) begin
        if (ecnt[i] != 0 && enq[i]) ecnt[i]  <= ecnt[i] - 1;
        if (ecnt[i] == 1 && enq[i]) ecntz[i] <= 1;
      end
    end
  end

  // DFIFO and PMT(P) instantiations
  /////////////////////////////////////////////////////////////////////////////////////////
  generate
    for (j=0; j<(1<<`P_LOG); j=j+1) begin
      assign enq[j]    = (cnt[j] < (1<<(4-1)));
      assign deq[j]    = (!emp[j] && !pmt_p_full[j]);
      assign im_din[j] = (ecntz[j]) ? {32'h0,32'hffffffff} : din[j];
      DFIFO #(4,`RCDW) im00(.CLK(CLK), .RST(RST), .enq(enq[j]), .deq(deq[j]), .din(im_din[j]), .dot(pmt_p_din[`RCDW*(j+1)-1:`RCDW*j]), .emp(emp[j]), .cnt(cnt[j]));
      assign pmt_p_dinen[j] = deq[j];
    end
  endgenerate
    
  PMT_P #(`P_LOG, `D_LOG, `RCDW) pmt_p(CLK, RST, txfifo_full, pmt_p_din, pmt_p_dinen, pmt_p_dot, pmt_p_doten, pmt_p_full);

  // An FIFO for Tx instantiation
  /////////////////////////////////////////////////////////////////////////////////////////
  assign txfifo_enq = (pmt_p_doten && !buf_stop);
  assign txfifo_deq = (lcd_we && txfifo_txcnt == (1<<`P_LOG)-1);
    
  always @(posedge CLK) txfifo_emp_r <= txfifo_emp;
  
  always @(posedge CLK) begin
    if      (RST)         datacnt <= 0;
    else if (pmt_p_doten) datacnt <= datacnt + (1<<`P_LOG);
  end
  always @(posedge CLK) begin
    if      (RST)                                                buf_stop <= 0;
    else if ((datacnt == `RCD_NUM - (1<<`P_LOG)) && pmt_p_doten) buf_stop <= 1;
  end

  BFIFO #(6, `RCDW*(1<<`P_LOG)) 
  txfifo(.CLK(CLK), .RST(RST), .enq(txfifo_enq), .deq(txfifo_deq), 
        .din(pmt_p_dot), .dot(txfifo_dot), .emp(txfifo_emp), .full(txfifo_full), 
        .cnt(txfifo_cnt));
    
  // An LCD controller instantiation
  /////////////////////////////////////////////////////////////////////////////////////////
  assign lcd_data = mux32(txfifo_dot_t[31:0], txfifo_dot[31:0], (txfifo_txcnt==0));
  assign lcd_we   = (!RST && !txfifo_emp_r && rdy);

  always @(posedge CLK) begin
    if      (RST)    begin txfifo_txcnt <= 0;              lcd_cnt <= 0;         end
    else if (lcd_we) begin txfifo_txcnt <= txfifo_txcnt+1; lcd_cnt <= lcd_cnt+1; end
  end
  always @(posedge CLK) begin
    case ({lcd_we, (txfifo_txcnt == 0)})
      2'b10: txfifo_dot_t <= {{`RCDW{1'b0}}, txfifo_dot_t[`RCDW*(1<<`P_LOG)-1:`RCDW]};
      2'b11: txfifo_dot_t <= txfifo_dot[`RCDW*(1<<`P_LOG)-1:`RCDW];
    endcase
  end
  
  always @(posedge CLK) begin
    if (RST) begin
      cycle_lcdwe <= 0;
      cycle_send  <= 0;
    end else begin
      cycle_lcdwe <= (!cycle_lcdwe && rdy && (lcd_cnt >= `RCD_NUM) && !cycle_send);
      if (cycle_lcdwe) cycle_send <= 1;
    end
  end
  
  LCDCON lcdcon(CLK, 
                RST, 
                (mux32(lcd_data, cycle, cycle_lcdwe)), 
                (mux1(lcd_we, 1'b1, cycle_lcdwe)), 
                TXD, 
                rdy);

endmodule
`default_nettype wire
