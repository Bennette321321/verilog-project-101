## Clock signal
set_property -dict { PACKAGE_PIN W5   IOSTANDARD LVCMOS33 } [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

## Reset signal (active low)
set_property -dict { PACKAGE_PIN U18  IOSTANDARD LVCMOS33 } [get_ports reset_n]

## Buttons
set_property -dict { PACKAGE_PIN T18  IOSTANDARD LVCMOS33 } [get_ports btn_next]

## VGA Connector
set_property -dict { PACKAGE_PIN G19  IOSTANDARD LVCMOS33 } [get_ports {vga_r[0]}]
set_property -dict { PACKAGE_PIN H19  IOSTANDARD LVCMOS33 } [get_ports {vga_r[1]}]
set_property -dict { PACKAGE_PIN J19  IOSTANDARD LVCMOS33 } [get_ports {vga_r[2]}]
set_property -dict { PACKAGE_PIN N19  IOSTANDARD LVCMOS33 } [get_ports {vga_r[3]}]
set_property -dict { PACKAGE_PIN J17  IOSTANDARD LVCMOS33 } [get_ports {vga_g[0]}]
set_property -dict { PACKAGE_PIN H17  IOSTANDARD LVCMOS33 } [get_ports {vga_g[1]}]
set_property -dict { PACKAGE_PIN G17  IOSTANDARD LVCMOS33 } [get_ports {vga_g[2]}]
set_property -dict { PACKAGE_PIN D17  IOSTANDARD LVCMOS33 } [get_ports {vga_g[3]}]
set_property -dict { PACKAGE_PIN N18  IOSTANDARD LVCMOS33 } [get_ports {vga_b[0]}]
set_property -dict { PACKAGE_PIN L18  IOSTANDARD LVCMOS33 } [get_ports {vga_b[1]}]
set_property -dict { PACKAGE_PIN K18  IOSTANDARD LVCMOS33 } [get_ports {vga_b[2]}]
set_property -dict { PACKAGE_PIN J18  IOSTANDARD LVCMOS33 } [get_ports {vga_b[3]}]
set_property -dict { PACKAGE_PIN P19  IOSTANDARD LVCMOS33 } [get_ports vga_hsync]
set_property -dict { PACKAGE_PIN R19  IOSTANDARD LVCMOS33 } [get_ports vga_vsync]

## SD Card SPI Interface (using Pmod connector JA)
set_property -dict { PACKAGE_PIN J1   IOSTANDARD LVCMOS33 } [get_ports sd_cs]    # JA1
set_property -dict { PACKAGE_PIN L2   IOSTANDARD LVCMOS33 } [get_ports sd_mosi]  # JA2
set_property -dict { PACKAGE_PIN J2   IOSTANDARD LVCMOS33 } [get_ports sd_miso]  # JA3
set_property -dict { PACKAGE_PIN G2   IOSTANDARD LVCMOS33 } [get_ports sd_sclk]  # JA4