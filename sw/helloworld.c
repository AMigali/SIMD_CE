#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xil_io.h"

//SA and DA register initialization addresses
#define src_addr XPAR_MIG7SERIES_0_BASEADDR+0X01000000 //first read address
#define dest_addr XPAR_MIG7SERIES_0_BASEADDR+0X01100000//first write address


#define DMA_ADDR XPAR_AXI_DMA_0_BASEADDR //DMA base address

#define AXI_REG0 XPAR_SIMD_CONVOLUTION_ENGINE_3X3_0_BASEADDR           // REG0 address (K7,K6,K5,K4,K3,K2,K1,K0)
#define AXI_REG1 XPAR_SIMD_CONVOLUTION_ENGINE_3X3_0_BASEADDR+0x01	   // REG1 address (SIMD, K8)


#define nData 4096 //number of pixels to be processed



int main()
{
    init_platform();

	//DDR PIXELS WRITING
	///////////////////////////////////////////////////////////////////
	for(int i=0;i<nData;i++){
		Xil_Out16(src_addr+(i*2),i); //simd=0
	}

	//IP CORE CONFIGURATION
	///////////////////////////////////////////////////////////////////
	Xil_Out32(AXI_REG1, 0x00000001); //kernel(8)='0001' + SIMD='0'(16bit)
    Xil_Out32(AXI_REG0, 0x11111111); //kernel(0:7)='0001'


	//DMA CHANNELS RESET
	/////////////////////////////////////////////////////////////////////////
	int ctrReg,statReg;
	Xil_Out32(DMA_ADDR,0x4); //RESET 1
	ctrReg=Xil_In32(DMA_ADDR);
	Xil_Out32(DMA_ADDR,ctrReg & 0xFFFFFFFB ); //RESET 0



	//S2MM CHANNEL ACTIVATION
	////////////////////////////////////////////////////////////////////////
	ctrReg=Xil_In32(DMA_ADDR+0X30);
	Xil_Out32(DMA_ADDR+0x30, ctrReg | 0x01);//S2MM State Register RS bit=1
	Xil_Out32(DMA_ADDR+0x48, dest_addr); //S2MM DA= dest_addr
	Xil_Out32(DMA_ADDR+0x58, 4*nData); //S2MM transfer_Length=4*nData


	//MM2S CHANNEL ACTIVATION
	////////////////////////////////////////////////////////////////////////
	ctrReg=Xil_In32(DMA_ADDR);
	Xil_Out32(DMA_ADDR, ctrReg | 0x01); //MM2S State Register RS bit=1
	Xil_Out32(DMA_ADDR+0x18, src_addr); //MM2S DA= dest_addr
	Xil_Out32(DMA_ADDR+0x28, 4*nData); //MM2S transfer_Length=4*nData


	//POLLING MM2S
	///////////////////////////////////////////////////////////////////////
	statReg=Xil_In32(DMA_ADDR+0x04); //MM2S state_reg reading
	while((statReg & 4096)!=4096){ //mm2s_dmasr bit 12 polling (bit IOC.Irq)
		statReg=Xil_In32(DMA_ADDR+0X04);
	}


	//POLLING S2MM
	///////////////////////////////////////////////////////////////////////
	statReg=Xil_In32(DMA_ADDR+0x34); //S2MM state_reg reading
	while((statReg & 4096)!=4096){ //s2mm_dmasr bit 12 polling (bit IOC.Irq)
    	statReg=Xil_In32(DMA_ADDR+0X34);
    }


	//RESULTS READING
	///////////////////////////////////////////////////////////////////////
	for(int i=0;i<nData;i++){
    		xil_printf("%d\n",Xil_In32(dest_addr+i*4));
	}

    cleanup_platform();
    return 0;
}
