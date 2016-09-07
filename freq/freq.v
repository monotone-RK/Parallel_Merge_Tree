/******************************************************************************/
/* A freq test project for a P-port parallel merge tree   ArchLab. TOKYO TECH */
/*                                                         Version 2016-06-01 */
/******************************************************************************/
`default_nettype none
  
`include "../src/define.v"
  
module freq(input  wire                   CLK,
            input  wire                   RST,
            input  wire [`RCDW-1:0]       PMT_P_DIN,
            input  wire [(1<<`P_LOG)-1:0] PMT_P_DINEN,
            output wire                   O_bit,
            output wire                   PMT_P_DOTEN,
            output wire [(1<<`P_LOG)-1:0] PMT_P_FULL);

  // input registers
  reg [`RCDW*(1<<`P_LOG)-1:0]  pmt_p_din;
  reg [(1<<`P_LOG)-1:0]        pmt_p_dinen;

  // output registers
  reg [`RCDW*(1<<`P_LOG)-1:0]  dot;
  reg                          doten;
  reg [(1<<`P_LOG)-1:0]        r_full;
  
  wire [`RCDW*(1<<`P_LOG)-1:0] pmt_p_dot;
  wire                         pmt_p_doten;
  wire [(1<<`P_LOG)-1:0]       pmt_p_full;

  PMT_P #(`P_LOG, `D_LOG, `RCDW) pmt_p(CLK, RST, 1'b0, pmt_p_din, pmt_p_dinen, pmt_p_dot, pmt_p_doten, pmt_p_full);
  
  assign O_bit       = |dot;
  assign PMT_P_DOTEN = doten;
  assign PMT_P_FULL  = r_full;

  always @(posedge CLK) begin
    if (!RST) begin
      pmt_p_din   <= {PMT_P_DIN, pmt_p_din[`RCDW*(1<<`P_LOG)-1:`RCDW]};
      pmt_p_dinen <= PMT_P_DINEN;
      
      dot         <= pmt_p_dot;
      doten       <= pmt_p_doten;
      r_full      <= pmt_p_full;
    end
  end

endmodule
`default_nettype wire
