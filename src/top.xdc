################################################################################
# XDC for VC707                                            ArchLab. TOKYO TECH #
################################################################################

## Clock
create_clock -period 5.000 [get_ports CLK_P]

set_property PACKAGE_PIN E19 [get_ports CLK_P]
set_property IOSTANDARD LVDS [get_ports CLK_P]

set_property PACKAGE_PIN E18 [get_ports CLK_N]
set_property IOSTANDARD LVDS [get_ports CLK_N]

## Switch
set_property PACKAGE_PIN AW40 [get_ports RST_X_IN]
set_property IOSTANDARD LVCMOS18 [get_ports RST_X_IN]

## UART
set_property PACKAGE_PIN AU36 [get_ports TXD]
set_property IOSTANDARD LVCMOS18 [get_ports TXD]
