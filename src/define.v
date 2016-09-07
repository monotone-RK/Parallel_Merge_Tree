/******************************************************************************/
/* Clock Frequency Definition                                                 */
/* Clock Freq = (CLKIN_FREQ) * (CLKFBOUT_MULT) / (CLKOUT_DIVIDE)              */
/******************************************************************************/
`define CLKIN_FREQ         200   // 200 MHz
`define CLKIN_PERIOD       5.000 // 5.000 ns
`define CLKFBOUT_MULT       5    //
// `define CLKOUT_DIVIDE0      5    //
`define CLKOUT_DIVIDE0     10    //
`define CLKOUT_DIVIDE1     10    //
`define CLKOUT_DIVIDE2     20    // 

`define SYSTEM_CLOCK (`CLKIN_FREQ * `CLKFBOUT_MULT / `CLKOUT_DIVIDE0)

/******************************************************************************/
/* UART Definition                                                            */
/******************************************************************************/
// 1M baud UART wait count (SERIAL_WCNT = Clock Freq / 1M)
`define SERIAL_WCNT `SYSTEM_CLOCK

/******************************************************************************/
/* PMT Definition                                                             */
/******************************************************************************/
`define RCDW        64  // data width of records
`define P_LOG        3  // # of ports in log scale, 1 for 2-port, 2 for 4-port
`define D_LOG        4  // depth of an SRL-based FIFO in log scale, 4 for 16 entries

/******************************************************************************/
/* Debug Definition                                                           */
/******************************************************************************/
// `define D_TYPE      "odd_even"  // Key Distribution pattern (odd_even, sorted)
`define D_TYPE      "sorted"  // Key Distribution pattern (odd_even, sorted)
`define RCD_NUM     8192
// `define RCD_NUM     128
`define PORT_8
