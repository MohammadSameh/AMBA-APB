# Constraints_basys3.xdc
# Updated to match top-level module APB_Top ports:
#   inputs:  PCLK, PRESETn, transfer[1:0], write_data[31:0], address[31:0]
#   outputs: read_data[31:0], read_user[15:0], read_resp[15:0]
#
# NOTE: Basys3 has limited switches/LEDs. This file maps:
#  - PCLK and PRESETn (required)
#  - transfer[0..1] to two switches
#  - a few LSBs of write_data and read_data to switches/LEDs for testing
#  - the remaining bus pins are left as commented placeholders:
#    enable them only if you have appropriate I/O available.

## ------------------------
## Clock
## ------------------------
# PCLK is the actual top-level clock port in your APB_Top module.
set_property PACKAGE_PIN W5 [get_ports {PCLK}]
set_property IOSTANDARD LVCMOS33 [get_ports {PCLK}]
create_clock -period 10.000 -name sys_clk [get_ports {PCLK}]
# 100 MHz assumed (10 ns period). Change -period if using different frequency.

## ------------------------
## Reset (active low)
## ------------------------
set_property PACKAGE_PIN U18 [get_ports {PRESETn}]
set_property IOSTANDARD LVCMOS33 [get_ports {PRESETn}]

## ------------------------
## transfer[1:0] -> map to two switches (SW0, SW1)
## Basys3 switch pins (example mapping). Adjust if your board layout differs.
set_property PACKAGE_PIN V17 [get_ports {transfer[0]}]
set_property PACKAGE_PIN V16 [get_ports {transfer[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {transfer[*]}]

## ------------------------
## write_data (example: map lower 8 bits to 8 switches)
## NOTE: Basys3 has 16 switches total. You cannot map all 32 bits to switches.
## Map only lower bits for manual input/test. Comment out unused lines.
#
# Example LSB mapping (change as required). These pin names are example Basys3 pins.
set_property PACKAGE_PIN A8  [get_ports {write_data[0]}]
set_property PACKAGE_PIN C11 [get_ports {write_data[1]}]
set_property PACKAGE_PIN K3  [get_ports {write_data[2]}]
set_property PACKAGE_PIN K4  [get_ports {write_data[3]}]
set_property PACKAGE_PIN J4  [get_ports {write_data[4]}]
set_property PACKAGE_PIN J3  [get_ports {write_data[5]}]
set_property PACKAGE_PIN L3  [get_ports {write_data[6]}]
set_property PACKAGE_PIN L4  [get_ports {write_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {write_data[7:0]}]

# If you want to drive more bits from buttons/switches, expand mapping here.
# Otherwise drive write_data/address from a testbench in simulation.

## ------------------------
## address (example: map lower 8 bits to switches/buttons)
## ------------------------
# Example - map address[0..7] similarly to write_data if desired. Commented:
# set_property PACKAGE_PIN ... [get_ports {address[0]}]
# ...

## ------------------------
## read_data -> LEDs (example: map lower 8 bits to 8 LEDs)
## ------------------------
# Basys3 has 16 LEDs, so map only lower bits that you want to observe.
set_property PACKAGE_PIN U16 [get_ports {read_data[0]}]
set_property PACKAGE_PIN E19 [get_ports {read_data[1]}]
set_property PACKAGE_PIN U19 [get_ports {read_data[2]}]
set_property PACKAGE_PIN V19 [get_ports {read_data[3]}]
set_property PACKAGE_PIN W18 [get_ports {read_data[4]}]
set_property PACKAGE_PIN U15 [get_ports {read_data[5]}]
set_property PACKAGE_PIN U14 [get_ports {read_data[6]}]
set_property PACKAGE_PIN V14 [get_ports {read_data[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {read_data[7:0]}]

## ------------------------
## read_user, read_resp (optional)
## ------------------------
# These signals are wide (read_user is USER_DATA_WIDTH, read_resp is USER_RESP_WIDTH).
# Map a few LSBs if you want to observe them on LEDs, or leave for testbench output.
# Example placeholders (commented):
# set_property PACKAGE_PIN ... [get_ports {read_user[0]}]
# set_property PACKAGE_PIN ... [get_ports {read_resp[0]}]

## ------------------------
## Housekeeping: avoid unused port errors
## ------------------------
# If you do not physically map wide buses to pins (recommended for many signals),
# do NOT reference them in the XDC. Only PCLK and PRESETn are strictly required.
# The lines above map a small, testable subset.

## ------------------------
## End of file
## ------------------------
