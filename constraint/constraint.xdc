
## Clock Signal
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

## Reset Button
set_property PACKAGE_PIN U18 [get_ports reset_n]
set_property IOSTANDARD LVCMOS33 [get_ports reset_n]

## Image Next Button
set_property PACKAGE_PIN U19 [get_ports btn_next]
set_property IOSTANDARD LVCMOS33 [get_ports btn_next]

## VGA Output
set_property PACKAGE_PIN P19 [get_ports vga_hsync]
set_property IOSTANDARD LVCMOS33 [get_ports vga_hsync]

set_property PACKAGE_PIN R19 [get_ports vga_vsync]
set_property IOSTANDARD LVCMOS33 [get_ports vga_vsync]

set_property PACKAGE_PIN N19 [get_ports {vga_r[3]}]
set_property PACKAGE_PIN J19 [get_ports {vga_r[2]}]
set_property PACKAGE_PIN H19 [get_ports {vga_r[1]}]
set_property PACKAGE_PIN G19 [get_ports {vga_r[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_r[*]}]

set_property PACKAGE_PIN D17 [get_ports {vga_g[3]}]
set_property PACKAGE_PIN G17 [get_ports {vga_g[2]}]
set_property PACKAGE_PIN H17 [get_ports {vga_g[1]}]
set_property PACKAGE_PIN J17 [get_ports {vga_g[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_g[*]}]

set_property PACKAGE_PIN J18 [get_ports {vga_b[3]}]
set_property PACKAGE_PIN K18 [get_ports {vga_b[2]}]
set_property PACKAGE_PIN L18 [get_ports {vga_b[1]}]
set_property PACKAGE_PIN N18 [get_ports {vga_b[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vga_b[*]}]

## SD Card SPI Interface (PMOD JA example)
set_property PACKAGE_PIN J1 [get_ports sd_cs]
set_property PACKAGE_PIN L2 [get_ports sd_sclk]
set_property PACKAGE_PIN K2 [get_ports sd_mosi]
set_property PACKAGE_PIN H1 [get_ports sd_miso]

set_property IOSTANDARD LVCMOS33 [get_ports sd_cs]
set_property IOSTANDARD LVCMOS33 [get_ports sd_sclk]
set_property IOSTANDARD LVCMOS33 [get_ports sd_mosi]
set_property IOSTANDARD LVCMOS33 [get_ports sd_miso]
