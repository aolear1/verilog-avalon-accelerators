# verilog-avalon-accelerators
A collection of hardware accelerators built using Intel's Avalon Interface.

## Contents

* [Instructions](#instructions)

* [Acceleratos](#accelerators)
  * [VGA adapter accelerator](#vga-adapter-accelerator)
  * [Memory copy accelerator](#memory-copy-accelerator)
  * [Dot product accelerator](#dot-product-accelerator)
  * [Concurrent dot product accelerator](#concurrent-dot-product-accelerator)
  * [Neural network accelerator](#neural-network-accelerator)


## Instuctions
To use any one of these accelerators, open Quartus and navigate to _Tools&rarr;Options&rarr;IP Catalog Search Locations_ then add the
paths to any of the accelerators subdirectories.

## Accelerators
### VGA adapter accelerator
This accelerator wraps the [VGA Core](https://www.eecg.utoronto.ca/~jayar/ece241_06F/vga/) to allow for usage by a CPU. The write request
consists of a single 32 bit word with address offset 0 with the gollowing encoding:
| word offset | bits   | meaning                    |
| ---- | ------ | --------------------------------- |
|   0  | 30..24 | y coordinate (7 bits)             |
|   0  | 23..16 | x coordinate (8 bits)             |
|   0  | 7..0   | brightness (0=black, 255=white)   |
### Memory copy accelerator
text
### Dot product accelerator
text
### Concurrent dot product accelerator
text
### Neural network accelerator
text
