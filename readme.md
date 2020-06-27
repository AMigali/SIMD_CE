## Team number: 
xohw20_244

## Project name: 
Efficient SIMD 2D convolution engine for FPGA-based heterogeneous embedded systems

## Date: 
2020/06/27

## Version of uploaded archive: 
1.0

## University name: 
University of Calabria

## Supervisor name: 
Stefania Perri

## Supervisor e-mail: 
s.perri@unical.it

## Participant: 
Andrea Migali
## Email: 
migaliandrea97@gmail.com

## Participant: 
Roman Huzyuk
## Email: 
roman.huzyuk@gmail.com

## Participant: 
Mario Andrea Sangiovanni
## Email: 
marioandreasangiovanni@hotmail.it

## Board used: 
Nexys4DDR

## Software Version: 
Vivado 2017.4

## Brief description of project: 
The designed system is an Efficient Convolution Engine able to compute 2-D filterings in the 
space domain taking advantage of the SIMD paradigm. It also offers the possibility to configure, with 
an appropriate software, the values of the convolution kernel. The IP-Core has been described in 
VHDL and implemented within an embedded system built on a Nexys4-DDR board. The advantages 
introduced by the use of this system are an efficient exploitation of the hardware resources available 
inside the chip and a reduced power consumption. 
The proposed IP-Core, thanks to its features, can be adapted to various application areas 
where convolution operations are required. In particular, one of the main applications that could 
benefit from a system like this is that of Convolutional Neural Networks (CNNs) which are widely 
used in the realization of AI systems. In order to allow a wide development of this technology, it is 
essential to use techniques of energy consumption and hardware cost optimization without sacrificing performances.



## Description of archive:

- `doc\` :

     .\xohw_20_244_project_report.pdf.
	
     .\DMAs_settings.txt: AXI DMA settings.
	
- `hw\` : contains the project bitstream.

- `ip\` : contains the SIMD Convolution Engine IP Core sources.

    `.\SIMD_CONVOLUTION_ENGINE_3x3\src` : contains all the VHDL design codes, including a testbench.	
	
     .\AXI_LITE_REG.vhd: AXI4LITE interface for configuration.

     .\Convolver.vhd: Convolution Computation module.

     .\FIFO_param.vhd: Parametric FIFO structure.

     .\Filter_3x3.vhd: Convolution Engine top-module.

     .\filter_testbench.vhd: Simulation code.

     .\FSM.vhd: Convolution computation control unit.

     .\PixelBuffer.vhd: SIMD pixel Buffer.
	
     .\SIMD_Adder.vhd: SIMD adder tree.

     .\SIMD_Multiplier.vhd: SIMD binary Multiplier.

     .\SIMD_Sum.vhd: parametric SIMD binary adder.

     .\write_to_file.vhd: results writing code.

- `MATLAB\` : 

    .\simulation_test.m performs the convolution by software and checks the Vivado Simulation results.

- `sw\` : contains the executable software.

- `SIMD_Convolution_Engine_System.xpr.zip` : contains the complete VIVADO project.

- `SIMD_Convolution_Engine_IPCore.xpr.zip` : contains the IPCore-only VIVADO project.

## Instructions to build and test project: 

1. Decompress the SIMD_Convolution_Engine_System.xpr.zip archive and open the project by using VIVADO.

2. Generate all the IP Core Output Products.

3. Run Synthesis,Implementation & Bistream Generation.

4. Export HW results into SDK and launch it.

5. Program FPGA, open the Serial COM Port and run the configuration.

6. Run Results will appear on the SDK Console.


## Link to YouTube Video:

https://youtu.be/oM3hgEmobe8