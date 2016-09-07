/******************************************************************************/
/* Clock & Reset Generator                                                    */
/******************************************************************************/
`default_nettype none

`include "define.v"

/* Clock Generator                                                            */
/******************************************************************************/
module clockgen(// Clock in ports
                input  wire clk_p,
                input  wire clk_n,
                // Clock out ports
                output wire clk_out1,
                output wire clk_out2,
                output wire clk_out3,
                // Status and control signals
                output wire locked);
                
  // Input buffering
  //------------------------------------
  wire clk_ibuf;
  IBUFGDS ibuf (.I (clk_p), .IB(clk_n), .O (clk_ibuf));
  
  // Clocking PRIMITIVE
  //------------------------------------
  // Instantiation of the MMCM PRIMITIVE
  //    * Unused inputs are tied off
  //    * Unused outputs are labeled unused
  wire [15:0] do_unused;
  wire        drdy_unused;
  wire        psdone_unused;
  wire        locked_int;
  wire        clkfbout_clk_wiz_0;
  wire        clkfbout_buf_clk_wiz_0;
  wire        clk_out1_clk_wiz_0;
  wire        clk_out2_clk_wiz_0;
  wire        clk_out3_clk_wiz_0;
  wire        clkfboutb_unused;
  wire        clkout0b_unused;
  wire        clkout1b_unused;
  wire        clkout2b_unused;
  wire        clkout3_unused;
  wire        clkout3b_unused;
  wire        clkout4_unused;
  wire        clkout5_unused;
  wire        clkout6_unused;
  wire        clkfbstopped_unused;
  wire        clkinstopped_unused;

  MMCME2_ADV
    #(.BANDWIDTH            ("OPTIMIZED"),
      .CLKOUT4_CASCADE      ("FALSE"),
      .COMPENSATION         ("ZHOLD"),
      .STARTUP_WAIT         ("FALSE"),
      .DIVCLK_DIVIDE        (1),
      .CLKFBOUT_MULT_F      (`CLKFBOUT_MULT),
      .CLKFBOUT_PHASE       (0.000),
      .CLKFBOUT_USE_FINE_PS ("FALSE"),
      .CLKOUT0_DIVIDE_F     (`CLKOUT_DIVIDE0),
      .CLKOUT0_PHASE        (0.000),
      .CLKOUT0_DUTY_CYCLE   (0.500),
      .CLKOUT0_USE_FINE_PS  ("FALSE"),
      .CLKOUT1_DIVIDE       (`CLKOUT_DIVIDE1),
      .CLKOUT1_PHASE        (0.000),
      .CLKOUT1_DUTY_CYCLE   (0.500),
      .CLKOUT1_USE_FINE_PS  ("FALSE"),
      .CLKOUT2_DIVIDE       (`CLKOUT_DIVIDE2),
      .CLKOUT2_PHASE        (0.000),
      .CLKOUT2_DUTY_CYCLE   (0.500),
      .CLKOUT2_USE_FINE_PS  ("FALSE"),
      .CLKIN1_PERIOD        (`CLKIN_PERIOD))
  mmcm_adv_inst
    (// Output clocks
     .CLKFBOUT            (clkfbout_clk_wiz_0),
     .CLKFBOUTB           (clkfboutb_unused),
     .CLKOUT0             (clk_out1_clk_wiz_0),
     .CLKOUT0B            (clkout0b_unused),
     .CLKOUT1             (clk_out2_clk_wiz_0),
     .CLKOUT1B            (clkout1b_unused),
     .CLKOUT2             (clk_out3_clk_wiz_0),
     .CLKOUT2B            (clkout2b_unused),
     .CLKOUT3             (clkout3_unused),
     .CLKOUT3B            (clkout3b_unused),
     .CLKOUT4             (clkout4_unused),
     .CLKOUT5             (clkout5_unused),
     .CLKOUT6             (clkout6_unused),
     // Input clock control
     .CLKFBIN             (clkfbout_buf_clk_wiz_0),
     .CLKIN1              (clk_ibuf),
     .CLKIN2              (1'b0),
     // Tied to always select the primary input clock
     .CLKINSEL            (1'b1),
     // Ports for dynamic reconfiguration
     .DADDR               (7'h0),
     .DCLK                (1'b0),
     .DEN                 (1'b0),
     .DI                  (16'h0),
     .DO                  (do_unused),
     .DRDY                (drdy_unused),
     .DWE                 (1'b0),
     // Ports for dynamic phase shift
     .PSCLK               (1'b0),
     .PSEN                (1'b0),
     .PSINCDEC            (1'b0),
     .PSDONE              (psdone_unused),
     // Other control and status signals
     .LOCKED              (locked_int),
     .CLKINSTOPPED        (clkinstopped_unused),
     .CLKFBSTOPPED        (clkfbstopped_unused),
     .PWRDWN              (1'b0),
     .RST                 (1'b0));
     
  assign locked = locked_int;
  
  // Output buffering
  //-----------------------------------
  BUFG clkf_buf
    (.O (clkfbout_buf_clk_wiz_0),
     .I (clkfbout_clk_wiz_0));
  
  BUFG clkout1_buf
    (.O   (clk_out1),
     .I   (clk_out1_clk_wiz_0));
  BUFG clkout2_buf
    (.O   (clk_out2),
     .I   (clk_out2_clk_wiz_0));
  BUFG clkout3_buf
    (.O   (clk_out3),
     .I   (clk_out3_clk_wiz_0));
  
endmodule


/* Reset Generator :  generate about 100 cycle reset signal                   */
/******************************************************************************/
module resetgen(input  wire CLK, 
                input  wire RST_X_I, 
                output wire RST_X_O);

  reg [7:0] cnt;
  assign RST_X_O = cnt[7];

  always @(posedge CLK) begin
    if      (!RST_X_I) cnt <= 0;
    else if (~RST_X_O) cnt <= (cnt + 1'b1);
  end
endmodule


/******************************************************************************/
module CLKRSTGEN(input  wire CLK_P,
                 input  wire CLK_N,
                 input  wire RST_X_I, 
                 output wire CLK_O, 
                 output wire RST_X_O);

  wire LOCKED;
  clockgen clkgen(.clk_p(CLK_P),
                  .clk_n(CLK_N), 
                  .clk_out1(CLK_O), 
                  .clk_out2(), 
                  .clk_out3(), 
                  .locked(LOCKED));
  resetgen rstgen(CLK_O, (RST_X_I & LOCKED), RST_X_O);
endmodule 
`default_nettype wire
