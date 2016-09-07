/******************************************************************************/
/* A test bench for a P-port parallel merge tree          ArchLab. TOKYO TECH */
/*                                                         Version 2016-06-02 */
/******************************************************************************/
`default_nettype none

`include "define.v"
`include "pmt.v"

// module tb_MM_2();
  
//   reg                          CLK; 
//   reg                          RST;
  
//   wire [`RCDW-1:0]             mm_2_din_00;
//   wire [`RCDW-1:0]             mm_2_din_01;
//   wire [`RCDW*(1<<`P_LOG)-1:0] mm_2_din;
//   wire [(1<<`P_LOG)-1:0]       mm_2_full;
//   wire [(1<<`P_LOG)-1:0]       mm_2_dinen;
//   wire [`RCDW*(1<<`P_LOG)-1:0] mm_2_dot;
//   wire                         mm_2_doten;

//   reg [31:0]                   ecnt_a;
//   reg [31:0]                   ecnt_b;
//   reg                          ecntz_a;
//   reg                          ecntz_b;


//   // Clock and reset generator
//   /////////////////////////////////////////////////////////////////////////////////////////
//   initial begin CLK = 0; forever #50 CLK = ~CLK; end
//   initial begin RST = 1; #400; RST = 0;          end

//   // An counter of elapsed cycle
//   /////////////////////////////////////////////////////////////////////////////////////////
//   reg [31:0] cycle;
//   always @(posedge CLK) begin
//     if (RST) cycle <= 1;
//     else     cycle <= cycle + 1;
//   end

//   // Test pattern generator
//   /////////////////////////////////////////////////////////////////////////////////////////
//   reg [`RCDW-1:0] dot_ta;
//   reg [`RCDW-1:0] dot_tb;
//   reg sel_a;
//   reg sel_b;
//   generate
//     if (`D_TYPE == "odd_even") begin
//       always @(posedge CLK) begin
//         if (RST) begin
//           dot_ta <= 1;
//           dot_tb <= 2;
//         end else begin
//           if (mm_2_dinen[0]) dot_ta <= dot_ta + 2;
//           if (mm_2_dinen[1]) dot_tb <= dot_tb + 2;
//         end
//       end
//     end else if (`D_TYPE == "sorted") begin
//       always @(posedge CLK) begin
//         if (RST) begin
//           dot_ta <= 1;
//           dot_tb <= 3;
//           sel_a  <= 0;
//           sel_b  <= 0;
//         end else begin
//           if (mm_2_dinen[0]) begin dot_ta <= (sel_a) ? dot_ta + 3 : dot_ta + 1; sel_a <= ~sel_a; end
//           if (mm_2_dinen[1]) begin dot_tb <= (sel_b) ? dot_tb + 3 : dot_tb + 1; sel_b <= ~sel_b; end
//         end
//       end
//     end else begin
//       always @(posedge CLK) begin
//         $write("Error! D_TYPE is wrong.\n");
//         $write("Please make sure src/define.v\n");
//         $finish();
//       end
//     end
//   endgenerate

//   // A counter of ejected records
//   /////////////////////////////////////////////////////////////////////////////////////////
//   always @(posedge CLK) begin
//     if  (RST) begin
//       ecnt_a  <= (`RCD_NUM >> 1);
//       ecnt_b  <= (`RCD_NUM >> 1);
//       ecntz_a <= 0;
//       ecntz_b <= 0;
//     end else begin
//       if (ecnt_a != 0 && mm_2_dinen[0]) ecnt_a  <= ecnt_a - 1;
//       if (ecnt_b != 0 && mm_2_dinen[1]) ecnt_b  <= ecnt_b - 1;
//       if (ecnt_a == 1 && mm_2_dinen[0]) ecntz_a <= 1;
//       if (ecnt_b == 1 && mm_2_dinen[1]) ecntz_b <= 1;
//     end
//   end  
      
//   // MM(2) instantiation
//   /////////////////////////////////////////////////////////////////////////////////////////
//   assign mm_2_din_00 = (ecntz_a) ? {32'h0,32'hffffffff} : dot_ta;
//   assign mm_2_din_01 = (ecntz_b) ? {32'h0,32'hffffffff} : dot_tb;
//   assign mm_2_din    = {mm_2_din_01, mm_2_din_00};
//   assign mm_2_dinen  = {(~mm_2_full[1] && !RST), (~mm_2_full[0] && !RST)};
//   MM_P #(`P_LOG, `D_LOG, `RCDW) mm_2(CLK, RST, 1'b0, mm_2_din, mm_2_dinen, mm_2_dot, mm_2_doten, mm_2_full);

//   // Displayed debug Info
//   /////////////////////////////////////////////////////////////////////////////////////////
//   reg [1:0] display = 0;
//   always @(posedge CLK) begin
//     if (RST && display < 2) begin
//       display <= display + 1;
//       if (display == 0) begin
//         $write("   cycle   |");
//         $write("         mm_2_din_00          mm_2_din_01 |");
//         $write("                                    FIFO output data                                |");
//         $write("  FIFO cnt   |");
//         $write("  enq |");
//         $write("  deq |");
//         $write("          output data of MM(2)            |");
//       end else begin
//         $write("------------------------------------------");
//         $write("------------------------------------------");
//         $write("------------------------------------------");
//         $write("------------------------------------------");
//         $write("-------------------------------------------");
//       end
//       $write("\n");
//     end else if (!RST) begin
//       $write("%d |", cycle);
//       if (mm_2_dinen[0]) $write("%d ", mm_2_din[ 63: 0]);
//       if (mm_2_dinen[1]) $write("%d |", mm_2_din[127:64]);
//       $write("%d %d %d %d |", mm_2.fifo_mmp_00.fifo_dot[63:0], mm_2.fifo_mmp_00.fifo_dot[127:64], mm_2.fifo_mmp_01.fifo_dot[63:0], mm_2.fifo_mmp_01.fifo_dot[127:64]);
//       $write(" %d %d %d %d |", mm_2.fifo_mmp_00.fifo[0].srl_fifo.cnt, mm_2.fifo_mmp_00.fifo[1].srl_fifo.cnt, mm_2.fifo_mmp_01.fifo[0].srl_fifo.cnt, mm_2.fifo_mmp_01.fifo[1].srl_fifo.cnt);
//       // $write("(%d): %d%d%d%d |", mm_2.bpm_dinen, mm_2.fifo_mmp_emp00[0], mm_2.fifo_mmp_emp00[1], mm_2.fifo_mmp_emp01[0], mm_2.fifo_mmp_emp01[1]);
//       // $write(" %d%d%d%d |", mm_2.s_fb_00[0], mm_2.s_fb_00[1], mm_2.s_fb_01[0], mm_2.s_fb_01[1]);
//       $write(" %d%d%d%d |", mm_2.fifo_mmp_00.dinen[0], mm_2.fifo_mmp_00.dinen[1], mm_2.fifo_mmp_01.dinen[0], mm_2.fifo_mmp_01.dinen[1]);
//       $write(" %d%d%d%d |", mm_2.fifo_mmp_00.s[0], mm_2.fifo_mmp_00.s[1], mm_2.fifo_mmp_01.s[0], mm_2.fifo_mmp_01.s[1]);
//       if (mm_2_doten) $write("%d %d |", mm_2_dot[63:0], mm_2_dot[127:64]);
//       else         $write("                                          |");
//       $write("\n");
//       $fflush();
//     end
//   end

//   // Error checker
//   /////////////////////////////////////////////////////////////////////////////////////////
//   reg [127:0] check_val;
//   always @(posedge CLK) begin
//     if (RST) begin
//       check_val <= {64'd2, 64'd1};
//     end else begin
//       if (mm_2_doten) begin
//         if (check_val != mm_2_dot) begin
//           $write("Error! mm_2_dot:%d %d check_val%d %d\n", mm_2_dot[63:0], mm_2_dot[127:64], check_val[63:0], check_val[127:64]); 
//           $finish();
//         end
//         check_val <= {(check_val[127:64]+64'd2), (check_val[63:0]+64'd2)};
//       end
//     end
//   end    
 
//   // A terminator
//   /////////////////////////////////////////////////////////////////////////////////////////
//   reg [31:0] finish_cnt;
//   always @(posedge CLK) begin
//     if (RST) begin
//       finish_cnt <= 0;
//     end else begin
//       if (mm_2_doten) finish_cnt <= finish_cnt + 2;
//       if(finish_cnt == (`RCD_NUM - (1<<`P_LOG)) && mm_2_doten) begin : simulation_finish
//         $write("\n");
//         $write("Sorting finished!\n");
//         $finish();
//       end
//     end
//   end
  
// endmodule

// module tb_MM_4();
  
//   reg                              CLK; 
//   reg                              RST;
  
//   wire [`RCDW*(1<<(`P_LOG-1))-1:0] mm_4_din_00;
//   wire [`RCDW*(1<<(`P_LOG-1))-1:0] mm_4_din_01;
//   wire [`RCDW*(1<<`P_LOG)-1:0]     mm_4_din;
//   wire [1:0]                       mm_4_dinen;
//   wire [`RCDW*(1<<`P_LOG)-1:0]     mm_4_dot;
//   wire                             mm_4_doten;
//   wire [1:0]                       mm_4_full;

//   reg [31:0]                       ecnt_00;
//   reg [31:0]                       ecnt_01;
//   reg                              ecntz_00;
//   reg                              ecntz_01;


//   // Clock and reset generator
//   /////////////////////////////////////////////////////////////////////////////////////////
//   initial begin CLK = 0; forever #50 CLK = ~CLK; end
//   initial begin RST = 1; #400; RST = 0;          end

//   // An counter of elapsed cycle
//   /////////////////////////////////////////////////////////////////////////////////////////
//   reg [31:0] cycle;
//   always @(posedge CLK) begin
//     if (RST) cycle <= 1;
//     else     cycle <= cycle + 1;
//   end

//   // Test pattern generator
//   /////////////////////////////////////////////////////////////////////////////////////////
//   reg [`RCDW-1:0] din_00_0;
//   reg [`RCDW-1:0] din_00_1;
//   reg [`RCDW-1:0] din_01_0;
//   reg [`RCDW-1:0] din_01_1;
//   reg             sel_00;
//   reg             sel_01;
//   generate
//     if (`D_TYPE == "odd_even") begin
//       always @(posedge CLK) begin
//         if (RST) begin
//           din_00_0 <= 1;
//           din_00_1 <= 3;
//           din_01_0 <= 2;
//           din_01_1 <= 4;
//         end else begin
//           if (mm_4_dinen[0]) begin din_00_0 <= din_00_0 + (1<<`P_LOG); din_00_1 <= din_00_1 + (1<<`P_LOG); end
//           if (mm_4_dinen[1]) begin din_01_0 <= din_01_0 + (1<<`P_LOG); din_01_1 <= din_01_1 + (1<<`P_LOG); end
//         end
//       end
//     end else if (`D_TYPE == "sorted") begin
//       always @(posedge CLK) begin
//         if (RST) begin
//           din_00_0 <= 1;
//           din_00_1 <= 2;
//           din_01_0 <= 5;
//           din_01_1 <= 6;
//           sel_00   <= 0;
//           sel_01   <= 0;
//         end else begin
//           if (mm_4_dinen[0]) begin 
//             din_00_0 <= (sel_00) ? din_00_0 + 3*(1<<(`P_LOG-1)) : din_00_0 + (1<<(`P_LOG-1)); 
//             din_00_1 <= (sel_00) ? din_00_1 + 3*(1<<(`P_LOG-1)) : din_00_1 + (1<<(`P_LOG-1)); 
//             sel_00   <= ~sel_00; 
//           end
//           if (mm_4_dinen[1]) begin 
//             din_01_0 <= (sel_01) ? din_01_0 + 3*(1<<(`P_LOG-1)) : din_01_0 + (1<<(`P_LOG-1)); 
//             din_01_1 <= (sel_01) ? din_01_1 + 3*(1<<(`P_LOG-1)) : din_01_1 + (1<<(`P_LOG-1)); 
//             sel_01   <= ~sel_01; 
//           end
//         end
//       end
//     end else begin
//       always @(posedge CLK) begin
//         $write("Error! D_TYPE is wrong.\n");
//         $write("Please make sure src/define.v\n");
//         $finish();
//       end
//     end
//   endgenerate

//   // A counter of ejected records
//   /////////////////////////////////////////////////////////////////////////////////////////
//   always @(posedge CLK) begin
//     if  (RST) begin
//       ecnt_00  <= (`RCD_NUM >> 1);
//       ecnt_01  <= (`RCD_NUM >> 1);
//       ecntz_00 <= 0;
//       ecntz_01 <= 0;
//     end else begin
//       if (ecnt_00 != 0 && mm_4_dinen[0])               ecnt_00  <= ecnt_00 - (1<<(`P_LOG-1));
//       if (ecnt_01 != 0 && mm_4_dinen[1])               ecnt_01  <= ecnt_01 - (1<<(`P_LOG-1));
//       if (ecnt_00 == (1<<(`P_LOG-1)) && mm_4_dinen[0]) ecntz_00 <= 1;
//       if (ecnt_01 == (1<<(`P_LOG-1)) && mm_4_dinen[1]) ecntz_01 <= 1;
//     end
//   end  
      
//   // MM(4) instantiation
//   /////////////////////////////////////////////////////////////////////////////////////////
//   assign mm_4_din_00 = (ecntz_00) ? {32'h0,32'hffffffff,32'h0,32'hffffffff} : {din_00_1,din_00_0};
//   assign mm_4_din_01 = (ecntz_01) ? {32'h0,32'hffffffff,32'h0,32'hffffffff} : {din_01_1,din_01_0};
//   assign mm_4_din    = {mm_4_din_01, mm_4_din_00};
//   assign mm_4_dinen  = {(~mm_4_full[1] && !RST), (~mm_4_full[0] && !RST)};
//   MM_P #(`P_LOG, `D_LOG, `RCDW) mm_4(CLK, RST, 1'b0, mm_4_din, mm_4_dinen, mm_4_dot, mm_4_doten, mm_4_full);

//   // Displayed debug Info
//   /////////////////////////////////////////////////////////////////////////////////////////
//   reg [1:0] display = 0;
//   always @(posedge CLK) begin
//     if (RST && display < 2) begin
//       display <= display + 1;
//       if (display == 0) begin
//         $write("   cycle   |");
//         // $write("         mm_2_din_00          mm_2_din_01 |");
//         // $write("                                    FIFO output data                                |");
//         // $write("  FIFO cnt   |");
//         // $write("  enq |");
//         // $write("  deq |");
//         $write("                               output data of MM(4)                                 |");
//       end else begin
//         // $write("------------------------------------------");
//         // $write("------------------------------------------");
//         // $write("------------------------------------------");
//         // $write("------------------------------------------");
//         // $write("-------------------------------------------");
//         $write("-------------------------------------------------------------------------------------------------");
//       end
//       $write("\n");
//     end else if (!RST) begin
//       $write("%d |", cycle);
//       // if (mm_4_dinen[0]) $write("%d %d ", mm_4_din[63:0], mm_4_din[127:64]);
//       // if (mm_4_dinen[1]) $write("%d %d |", mm_4_din[191:128], mm_4_din[255:192]);
//       // $write("%d %d %d %d %d %d %d %d |", 
//       //        mm_4.fifo_mmp_00.fifo_dot[63:0], mm_4.fifo_mmp_00.fifo_dot[127:64], mm_4.fifo_mmp_00.fifo_dot[191:128], mm_4.fifo_mmp_00.fifo_dot[255:192], 
//       //        mm_4.fifo_mmp_01.fifo_dot[63:0], mm_4.fifo_mmp_01.fifo_dot[127:64], mm_4.fifo_mmp_01.fifo_dot[191:128], mm_4.fifo_mmp_01.fifo_dot[255:192]);
//       // $write(" %d %d %d %d %d %d %d %d |", 
//       //        mm_4.fifo_mmp_00.fifo[0].srl_fifo.cnt, mm_4.fifo_mmp_00.fifo[1].srl_fifo.cnt, mm_4.fifo_mmp_00.fifo[2].srl_fifo.cnt, mm_4.fifo_mmp_00.fifo[3].srl_fifo.cnt, 
//       //        mm_4.fifo_mmp_01.fifo[0].srl_fifo.cnt, mm_4.fifo_mmp_01.fifo[1].srl_fifo.cnt, mm_4.fifo_mmp_01.fifo[2].srl_fifo.cnt, mm_4.fifo_mmp_01.fifo[3].srl_fifo.cnt);
//       // $write(" %d%d%d%d |", mm_4.fifo_mmp_00.dinen[0], mm_4.fifo_mmp_00.dinen[1], mm_4.fifo_mmp_01.dinen[0], mm_4.fifo_mmp_01.dinen[1]);
//       // $write(" %d%d%d%d %d%d%d%d |", 
//       //        mm_4.fifo_mmp_00.s[0], mm_4.fifo_mmp_00.s[1], mm_4.fifo_mmp_00.s[2], mm_4.fifo_mmp_00.s[3], 
//       //        mm_4.fifo_mmp_01.s[0], mm_4.fifo_mmp_01.s[1], mm_4.fifo_mmp_01.s[2], mm_4.fifo_mmp_01.s[3]);
//       if (mm_4_doten) $write("%d %d %d %d |", mm_4_dot[63:0], mm_4_dot[127:64], mm_4_dot[191:128], mm_4_dot[255:192]);
//       else            $write("                                                                                    |");
//       $write("\n");
//       $fflush();
//     end
//   end

//   // Error checker
//   /////////////////////////////////////////////////////////////////////////////////////////
//   reg [`RCDW*(1<<`P_LOG)-1:0] check_val;
//   always @(posedge CLK) begin
//     if (RST) begin
//       check_val <= {64'd4, 64'd3, 64'd2, 64'd1};
//     end else begin
//       if (mm_4_doten) begin
//         if (check_val != mm_4_dot) begin
//           $write("Error! mm_4_dot:%d %d %d %d check_val:%d %d %d %d\n", 
//                  mm_4_dot[63:0], mm_4_dot[127:64], mm_4_dot[191:128], mm_4_dot[255:192], 
//                  check_val[63:0], check_val[127:64], check_val[191:128], check_val[255:192]); 
//           $finish();
//         end
//         check_val <= {(check_val[255:192]+64'd4),(check_val[191:128]+64'd4),(check_val[127:64]+64'd4),(check_val[63:0]+64'd4)};
//       end
//     end
//   end    
 
//   // A terminator
//   /////////////////////////////////////////////////////////////////////////////////////////
//   reg [31:0] finish_cnt;
//   always @(posedge CLK) begin
//     if (RST) begin
//       finish_cnt <= 0;
//     end else begin
//       if (mm_4_doten) finish_cnt <= finish_cnt + (1<<`P_LOG);
//       if(finish_cnt == (`RCD_NUM - (1<<`P_LOG)) && mm_4_doten) begin : simulation_finish
//         $write("\n");
//         $write("Sorting finished!\n");
//         $finish();
//       end
//     end
//   end
  
// endmodule

// module tb_MM_8();
  
//   reg                              CLK; 
//   reg                              RST;
  
//   wire [`RCDW*(1<<(`P_LOG-1))-1:0] mm_8_din_00;
//   wire [`RCDW*(1<<(`P_LOG-1))-1:0] mm_8_din_01;
//   wire [`RCDW*(1<<`P_LOG)-1:0]     mm_8_din;
//   wire [1:0]                       mm_8_dinen;
//   wire [`RCDW*(1<<`P_LOG)-1:0]     mm_8_dot;
//   wire                             mm_8_doten;
//   wire [1:0]                       mm_8_full;

//   reg [31:0]                       ecnt_00;
//   reg [31:0]                       ecnt_01;
//   reg                              ecntz_00;
//   reg                              ecntz_01;


//   // Clock and reset generator
//   /////////////////////////////////////////////////////////////////////////////////////////
//   initial begin CLK = 0; forever #50 CLK = ~CLK; end
//   initial begin RST = 1; #400; RST = 0;          end

//   // An counter of elapsed cycle
//   /////////////////////////////////////////////////////////////////////////////////////////
//   reg [31:0] cycle;
//   always @(posedge CLK) begin
//     if (RST) cycle <= 1;
//     else     cycle <= cycle + 1;
//   end

//   // Test pattern generator
//   /////////////////////////////////////////////////////////////////////////////////////////
//   reg [`RCDW-1:0] din_00_0;
//   reg [`RCDW-1:0] din_00_1;
//   reg [`RCDW-1:0] din_00_2;
//   reg [`RCDW-1:0] din_00_3;
//   reg [`RCDW-1:0] din_01_0;
//   reg [`RCDW-1:0] din_01_1;
//   reg [`RCDW-1:0] din_01_2;
//   reg [`RCDW-1:0] din_01_3;
//   reg             sel_00;
//   reg             sel_01;
//   generate
//     if (`D_TYPE == "odd_even") begin
//       always @(posedge CLK) begin
//         if (RST) begin
//           din_00_0 <= 1;
//           din_00_1 <= 3;
//           din_00_2 <= 5;
//           din_00_3 <= 7;
//           din_01_0 <= 2;
//           din_01_1 <= 4;
//           din_01_2 <= 6;
//           din_01_3 <= 8;
//         end else begin
//           if (mm_8_dinen[0]) begin 
//             din_00_0 <= din_00_0 + (1<<`P_LOG); 
//             din_00_1 <= din_00_1 + (1<<`P_LOG); 
//             din_00_2 <= din_00_2 + (1<<`P_LOG); 
//             din_00_3 <= din_00_3 + (1<<`P_LOG); 
//           end
//           if (mm_8_dinen[1]) begin 
//             din_01_0 <= din_01_0 + (1<<`P_LOG); 
//             din_01_1 <= din_01_1 + (1<<`P_LOG); 
//             din_01_2 <= din_01_2 + (1<<`P_LOG); 
//             din_01_3 <= din_01_3 + (1<<`P_LOG); 
//           end
//         end
//       end
//     end else if (`D_TYPE == "sorted") begin
//       always @(posedge CLK) begin
//         if (RST) begin
//           din_00_0 <=  1;
//           din_00_1 <=  2;
//           din_00_2 <=  3;
//           din_00_3 <=  4;
//           din_01_0 <=  9;
//           din_01_1 <= 10;
//           din_01_2 <= 11;
//           din_01_3 <= 12;
//           sel_00   <= 0;
//           sel_01   <= 0;
//         end else begin
//           if (mm_8_dinen[0]) begin 
//             din_00_0 <= (sel_00) ? din_00_0 + 3*(1<<(`P_LOG-1)) : din_00_0 + (1<<(`P_LOG-1)); 
//             din_00_1 <= (sel_00) ? din_00_1 + 3*(1<<(`P_LOG-1)) : din_00_1 + (1<<(`P_LOG-1)); 
//             din_00_2 <= (sel_00) ? din_00_2 + 3*(1<<(`P_LOG-1)) : din_00_2 + (1<<(`P_LOG-1)); 
//             din_00_3 <= (sel_00) ? din_00_3 + 3*(1<<(`P_LOG-1)) : din_00_3 + (1<<(`P_LOG-1)); 
//             sel_00   <= ~sel_00; 
//           end
//           if (mm_8_dinen[1]) begin 
//             din_01_0 <= (sel_01) ? din_01_0 + 3*(1<<(`P_LOG-1)) : din_01_0 + (1<<(`P_LOG-1)); 
//             din_01_1 <= (sel_01) ? din_01_1 + 3*(1<<(`P_LOG-1)) : din_01_1 + (1<<(`P_LOG-1)); 
//             din_01_2 <= (sel_01) ? din_01_2 + 3*(1<<(`P_LOG-1)) : din_01_2 + (1<<(`P_LOG-1)); 
//             din_01_3 <= (sel_01) ? din_01_3 + 3*(1<<(`P_LOG-1)) : din_01_3 + (1<<(`P_LOG-1)); 
//             sel_01   <= ~sel_01; 
//           end
//         end
//       end
//     end else begin
//       always @(posedge CLK) begin
//         $write("Error! D_TYPE is wrong.\n");
//         $write("Please make sure src/define.v\n");
//         $finish();
//       end
//     end
//   endgenerate

//   // A counter of ejected records
//   /////////////////////////////////////////////////////////////////////////////////////////
//   always @(posedge CLK) begin
//     if  (RST) begin
//       ecnt_00  <= (`RCD_NUM >> 1);
//       ecnt_01  <= (`RCD_NUM >> 1);
//       ecntz_00 <= 0;
//       ecntz_01 <= 0;
//     end else begin
//       if (ecnt_00 != 0 && mm_8_dinen[0])               ecnt_00  <= ecnt_00 - (1<<(`P_LOG-1));
//       if (ecnt_01 != 0 && mm_8_dinen[1])               ecnt_01  <= ecnt_01 - (1<<(`P_LOG-1));
//       if (ecnt_00 == (1<<(`P_LOG-1)) && mm_8_dinen[0]) ecntz_00 <= 1;
//       if (ecnt_01 == (1<<(`P_LOG-1)) && mm_8_dinen[1]) ecntz_01 <= 1;
//     end
//   end  
      
//   // MM(4) instantiation
//   /////////////////////////////////////////////////////////////////////////////////////////
//   assign mm_8_din_00 = (ecntz_00) ? {32'h0,32'hffffffff,32'h0,32'hffffffff,32'h0,32'hffffffff,32'h0,32'hffffffff} : {din_00_3,din_00_2,din_00_1,din_00_0};
//   assign mm_8_din_01 = (ecntz_01) ? {32'h0,32'hffffffff,32'h0,32'hffffffff,32'h0,32'hffffffff,32'h0,32'hffffffff} : {din_01_3,din_01_2,din_01_1,din_01_0};
//   assign mm_8_din    = {mm_8_din_01, mm_8_din_00};
//   assign mm_8_dinen  = {(~mm_8_full[1] && !RST), (~mm_8_full[0] && !RST)};
//   MM_P #(`P_LOG, `D_LOG, `RCDW) mm_8(CLK, RST, 1'b0, mm_8_din, mm_8_dinen, mm_8_dot, mm_8_doten, mm_8_full);

//   // Displayed debug Info
//   /////////////////////////////////////////////////////////////////////////////////////////
//   reg [1:0] display = 0;
//   always @(posedge CLK) begin
//     if (RST && display < 2) begin
//       display <= display + 1;
//       if (display == 0) begin
//         $write("   cycle   |");
//         // $write("         mm_8_din_00          mm_8_din_01 |");
//         // $write("                                    FIFO output data                                |");
//         // $write("  FIFO cnt   |");
//         // $write("  enq |");
//         // $write("  deq |");
//         $write("                                                                        output data of MM(8)                                                                            |");
//       end else begin
//         // $write("------------------------------------------");
//         // $write("------------------------------------------");
//         // $write("------------------------------------------");
//         // $write("------------------------------------------");
//         // $write("-------------------------------------------");
//         $write("-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------");
//       end
//       $write("\n");
//     end else if (!RST) begin
//       $write("%d |", cycle);
//       // if (mm_8_dinen[0]) $write("%d %d ", mm_8_din[63:0], mm_8_din[127:64]);
//       // if (mm_8_dinen[1]) $write("%d %d |", mm_8_din[191:128], mm_8_din[255:192]);
//       // $write("%d %d %d %d %d %d %d %d |", 
//       //        mm_8.fifo_mmp_00.fifo_dot[63:0], mm_8.fifo_mmp_00.fifo_dot[127:64], mm_8.fifo_mmp_00.fifo_dot[191:128], mm_8.fifo_mmp_00.fifo_dot[255:192], 
//       //        mm_8.fifo_mmp_01.fifo_dot[63:0], mm_8.fifo_mmp_01.fifo_dot[127:64], mm_8.fifo_mmp_01.fifo_dot[191:128], mm_8.fifo_mmp_01.fifo_dot[255:192]);
//       // $write(" %d %d %d %d %d %d %d %d |", 
//       //        mm_8.fifo_mmp_00.fifo[0].srl_fifo.cnt, mm_8.fifo_mmp_00.fifo[1].srl_fifo.cnt, mm_8.fifo_mmp_00.fifo[2].srl_fifo.cnt, mm_8.fifo_mmp_00.fifo[3].srl_fifo.cnt, 
//       //        mm_8.fifo_mmp_01.fifo[0].srl_fifo.cnt, mm_8.fifo_mmp_01.fifo[1].srl_fifo.cnt, mm_8.fifo_mmp_01.fifo[2].srl_fifo.cnt, mm_8.fifo_mmp_01.fifo[3].srl_fifo.cnt);
//       // $write(" %d%d%d%d |", mm_8.fifo_mmp_00.dinen[0], mm_8.fifo_mmp_00.dinen[1], mm_8.fifo_mmp_01.dinen[0], mm_8.fifo_mmp_01.dinen[1]);
//       // $write(" %d%d%d%d %d%d%d%d |", 
//       //        mm_8.fifo_mmp_00.s[0], mm_8.fifo_mmp_00.s[1], mm_8.fifo_mmp_00.s[2], mm_8.fifo_mmp_00.s[3], 
//       //        mm_8.fifo_mmp_01.s[0], mm_8.fifo_mmp_01.s[1], mm_8.fifo_mmp_01.s[2], mm_8.fifo_mmp_01.s[3]);
//       if (mm_8_doten) $write("%d %d %d %d %d %d %d %d |", 
//                              mm_8_dot[63:0], mm_8_dot[127:64], mm_8_dot[191:128], mm_8_dot[255:192],
//                              mm_8_dot[319:256], mm_8_dot[383:320], mm_8_dot[447:384], mm_8_dot[511:448]);
//       else            $write("                                                                                                                                                                        |");
//       $write("\n");
//       $fflush();
//     end
//   end

//   // Error checker
//   /////////////////////////////////////////////////////////////////////////////////////////
//   reg [`RCDW*(1<<`P_LOG)-1:0] check_val;
//   always @(posedge CLK) begin
//     if (RST) begin
//       check_val <= {64'd8, 64'd7, 64'd6, 64'd5, 64'd4, 64'd3, 64'd2, 64'd1};
//     end else begin
//       if (mm_8_doten) begin
//         if (check_val != mm_8_dot) begin
//           $write("Error!\n");
//           $write("mm_8_dot:%d %d %d %d %d %d %d %d \n",
//                  mm_8_dot[63:0], mm_8_dot[127:64], mm_8_dot[191:128], mm_8_dot[255:192],
//                  mm_8_dot[319:256], mm_8_dot[383:320], mm_8_dot[447:384], mm_8_dot[511:448]);
//           $write("check_val:%d %d %d %d %d %d %d %d \n",
//                  check_val[63:0], check_val[127:64], check_val[191:128], check_val[255:192],
//                  check_val[319:256], check_val[383:320], check_val[447:384], check_val[511:448]);
//           $finish();
//         end
//         check_val <= {(check_val[511:448]+64'd8),(check_val[447:384]+64'd8),(check_val[383:320]+64'd8),(check_val[319:256]+64'd8),
//                       (check_val[255:192]+64'd8),(check_val[191:128]+64'd8),(check_val[127:64]+64'd8),(check_val[63:0]+64'd8)};
//       end
//     end
//   end    
 
//   // A terminator
//   /////////////////////////////////////////////////////////////////////////////////////////
//   reg [31:0] finish_cnt;
//   always @(posedge CLK) begin
//     if (RST) begin
//       finish_cnt <= 0;
//     end else begin
//       if (mm_8_doten) finish_cnt <= finish_cnt + (1<<`P_LOG);
//       if(finish_cnt == (`RCD_NUM - (1<<`P_LOG)) && mm_8_doten) begin : simulation_finish
//         $write("\n");
//         $write("Sorting finished!\n");
//         $finish();
//       end
//     end
//   end
  
// endmodule


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

module tb_PMT_P();

  reg                          CLK; 
  reg                          RST;
  
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
  
  // Clock and reset generator
  /////////////////////////////////////////////////////////////////////////////////////////
  initial begin CLK = 0; forever #50 CLK = ~CLK; end
  initial begin RST = 1; #400; RST = 0;          end

  // A counter of elapsed cycle
  /////////////////////////////////////////////////////////////////////////////////////////
  reg [31:0] cycle;
  always @(posedge CLK) begin
    if (RST) cycle <= 1;
    else     cycle <= cycle + 1;
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
  
  // Module instantiations
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
    
  PMT_P #(`P_LOG, `D_LOG, `RCDW) pmt_p(CLK, RST, 1'b0, pmt_p_din, pmt_p_dinen, pmt_p_dot, pmt_p_doten, pmt_p_full);
  
  // Displayed debug Info
  /////////////////////////////////////////////////////////////////////////////////////////
  reg [1:0] display = 0;
`ifdef PORT_2
  always @(posedge CLK) begin
    if (RST && display < 2) begin
      display <= display + 1;
      if (display == 0) begin
        $write("   cycle   |");
        $write("         output data of PMT(2)            |");
      end else begin
        $write("-------------------------------------------------------");
      end
      $write("\n");
    end else if (!RST) begin
      $write("%d |", cycle);
      if (pmt_p_doten) $write("%d %d |", pmt_p_dot[63:0], pmt_p_dot[127:64]);
      else            $write("                                          |");
      $write("\n");
      $fflush();
    end
  end
`elsif PORT_4
  always @(posedge CLK) begin
    if (RST && display < 2) begin
      display <= display + 1;
      if (display == 0) begin
        $write("   cycle   |");
        $write("                              output data of PMT(4)                                 |");
      end else begin
        $write("-------------------------------------------------------------------------------------------------");
      end
      $write("\n");
    end else if (!RST) begin
      $write("%d |", cycle);
      if (pmt_p_doten) $write("%d %d %d %d |", pmt_p_dot[63:0], pmt_p_dot[127:64], pmt_p_dot[191:128], pmt_p_dot[255:192]);
      else            $write("                                                                                    |");
      $write("\n");
      $fflush();
    end
  end
`elsif PORT_8
  always @(posedge CLK) begin
    if (RST && display < 2) begin
      display <= display + 1;
      if (display == 0) begin
        $write("   cycle   |");
        $write("                                                                        output data of PMT(8)                                                                           |");
      end else begin
        $write("-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------");
      end
      $write("\n");
    end else if (!RST) begin
      $write("%d |", cycle);
      if (pmt_p_doten) $write("%d %d %d %d %d %d %d %d |", 
                              pmt_p_dot[63:0], pmt_p_dot[127:64], pmt_p_dot[191:128], pmt_p_dot[255:192],
                              pmt_p_dot[319:256], pmt_p_dot[383:320], pmt_p_dot[447:384], pmt_p_dot[511:448]);
      else            $write("                                                                                                                                                                        |");
      $write("\n");
      $fflush();
    end
  end
`endif

  // Error checker
  /////////////////////////////////////////////////////////////////////////////////////////
  reg [`RCDW*(1<<`P_LOG)-1:0] check_val;
  generate
    if (`P_LOG == 1) begin
      always @(posedge CLK) begin
        if (RST) begin
          check_val <= {64'd2, 64'd1};
        end else begin
          if (pmt_p_doten) begin
            if (check_val != pmt_p_dot) begin
              $write("\nError!\n");
              $write("pmt_p_dot:%d %d\n", 
                     pmt_p_dot[63:0], pmt_p_dot[127:64]);
              $write("check_val:%d %d\n", 
                     check_val[63:0], check_val[127:64]);
              $finish();
            end
            check_val <= {(check_val[127:64]+64'd2),(check_val[63:0]+64'd2)};
          end
        end
      end    
    end else if (`P_LOG == 2) begin
      always @(posedge CLK) begin
        if (RST) begin
          check_val <= {64'd4, 64'd3, 64'd2, 64'd1};
        end else begin
          if (pmt_p_doten) begin
            if (check_val != pmt_p_dot) begin
              $write("\nError!\n");
              $write("pmt_p_dot:%d %d %d %d\n", 
                     pmt_p_dot[63:0], pmt_p_dot[127:64], pmt_p_dot[191:128], pmt_p_dot[255:192]);
              $write("check_val:%d %d %d %d\n", 
                     check_val[63:0], check_val[127:64], check_val[191:128], check_val[255:192]); 
              $finish();
            end
            check_val <= {(check_val[255:192]+64'd4),(check_val[191:128]+64'd4),(check_val[127:64]+64'd4),(check_val[63:0]+64'd4)};
          end
        end
      end    
    end else if (`P_LOG == 3) begin
      always @(posedge CLK) begin
        if (RST) begin
          check_val <= {64'd8, 64'd7, 64'd6, 64'd5, 64'd4, 64'd3, 64'd2, 64'd1};
        end else begin
          if (pmt_p_doten) begin
            if (check_val != pmt_p_dot) begin
              $write("\nError!\n");
              $write("pmt_p_dot:%d %d %d %d %d %d %d %d\n", 
                     pmt_p_dot[63:0], pmt_p_dot[127:64], pmt_p_dot[191:128], pmt_p_dot[255:192],
                     pmt_p_dot[319:256], pmt_p_dot[383:320], pmt_p_dot[447:384], pmt_p_dot[511:448]);
              $write("check_val:%d %d %d %d %d %d %d %d\n", 
                     check_val[63:0], check_val[127:64], check_val[191:128], check_val[255:192],
                     check_val[319:256], check_val[383:320], check_val[447:384], check_val[511:448]); 
              $finish();
            end
            check_val <= {(check_val[511:448]+64'd8),(check_val[447:384]+64'd8),(check_val[383:320]+64'd8),(check_val[319:256]+64'd8),
                          (check_val[255:192]+64'd8),(check_val[191:128]+64'd8),(check_val[127:64]+64'd8),(check_val[63:0]+64'd8)};
          end
        end
      end
    end
  endgenerate
 
  // A terminator
  /////////////////////////////////////////////////////////////////////////////////////////
  reg [31:0] finish_cnt;
  always @(posedge CLK) begin
    if (RST) begin
      finish_cnt <= 0;
    end else begin
      if (pmt_p_doten) finish_cnt <= finish_cnt + (1<<`P_LOG);
      if(finish_cnt == (`RCD_NUM - (1<<`P_LOG)) && pmt_p_doten) begin : simulation_finish
        $write("\n");
        $write("Sorting finished!\n");
        $finish();
      end
    end
  end
  
endmodule

`default_nettype wire
