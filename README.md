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
This accelerator wraps the University of Toronto's [VGA adapter](https://www.eecg.utoronto.ca/~jayar/ece241_06F/vga/) to allow for usage by a CPU. The write request
consists of a single 32 bit word with address offset 0 with the gollowing encoding:
| word offset | bits   | meaning                    |
| ---- | ------ | --------------------------------- |
|   0  | 30..24 | y coordinate (7 bits)             |
|   0  | 23..16 | x coordinate (8 bits)             |
|   0  | 7..0   | brightness (0=black, 255=white)   |

The accelerator is designed for use on a DE1-SOC.
### Memory copy accelerator
Memory Copy writes from an inputted number of 32-bit words from a source address to a destination address. In total, 4 addresses are written to use this accelerator:
| Address |                       meaning                       |
| ---- | --------------------------------------------------- |
|   0  | write: starts wordcopy; read: stalls until finished |
|   1  | destination byte address                            |
|   2  | source byte address                                 |
|   3  | number of 32-bit words to copy                      |
The user has the option to stall the CPU until the copy is completed by attepting to read from the base address. The result of this read, however, is undefined.
### Dot product accelerator
This accelerator computs the dot product of two vectors, given the length of each one. Here is the address map:
| word offset |                       meaning                                  |
| ---- | -------------------------------------------------------------- |
|   0  | write: starts accelerator; read: stalls and provides result    |
|   1  | _reserved_                                                     |
|   2  | vector 1 byte address                                     |
|   3  | vector 2 byte address                          |
|   4  | _reserved_                                                     |
|   5  | vector length                                |
|   6  | _reserved_                                                     |
|   7  | _reserved_                                                     |
### Concurrent dot product accelerator
This faster accelerator cuts down the speed of the previous acceleratior by ~50%. However, it operates on an underlying assumption that one of the vectors _is guranteed to be read in less
cycles than the other_. A use case for this accelerator is if one of the vectors is stored onchip (such as in SRAM), while the other is stored offchip (such as in SDRAM). The address map is as follows.

| word offset |                       meaning                                  |
| ---- | -------------------------------------------------------------- |
|   0  | write: starts accelerator; read: stalls and provides result    |
|   1  | _reserved_                                                     |
|   2  | SDRAM vector byte address                                     |
|   3  | SRAM vector byte address                          |
|   4  | _reserved_                                                     |
|   5  | vector length                                |
|   6  | _reserved_                                                     |
|   7  | _reserved_                                                     |

### Neural network accelerator
The Neural Network Accelerator builds off the Concurrent Dot Product accelerator. It includs the optionality to apply a ReLu function and the functionality to add the address to a bias and write to a target address.
| word offset |                       meaning                      |
| ---- | -------------------------------------------------- |
|   0  | when written, starts accelerator; may also be read |
|   1  | bias byte address                           |
|   2  | weight matrix (SDRAM) byte address                         |
|   3  | input activations (SRAM) vector byte address              |
|   4  | output activations vector byte address             |
|   5  | input activations vector length                    |
|   6  | _reserved_                                         |
|   7  | activation function: 1 if ReLU, 0 if identity      |
*Note* The output is written through the SRAM facing master, so ensure the address you intend to write to is connected accordingly.

