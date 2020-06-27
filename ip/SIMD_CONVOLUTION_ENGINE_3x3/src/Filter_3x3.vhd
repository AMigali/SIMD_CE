----------------------------------------------------------------------------------
-- Company: Unical - Dipartimento di Ingegneria Informatica, Modellistica, Elettronica e Sistemistica
-- Students: Huzyuk R., Migali A., Sangiovanni M. A.
-- 
-- Create Date: 06.02.2020 15:06:53
-- Design Name: 3x3 AXI Image Filter
-- Module Name: Filter_3x3 - Behavioral
-- Project Name: 3x3 AXI Image Filter
-- Target Devices: Nexys4DDR
-- Tool Versions: 2017.4
-- 
-- Revision:
-- Revision 0.01 - File Created
-- 
----------------------------------------------------------------------------------

--SIMD CONVOLUTION ENGINE TOP MODULE
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity Filter_3x3 is
generic (Column_Size:integer:=64; Row_Size:integer:=64);
PORT(
     s_axis_clk,s_axis_rstn: in std_logic; 
	 s_axis_tvalid,s_axis_tlast: in std_logic;
	 s_axis_tready: out std_logic; 
	 s_axis_tdata: in std_logic_vector(15 downto 0);

	 m_axis_tvalid,m_axis_tlast: out std_logic;
	 m_axis_tready: in std_logic; 
	 m_axis_tdata: out std_logic_vector(31 downto 0);
	 
	 S_AXI_AWADDR    : in std_logic_vector(3 downto 0);
     S_AXI_AWVALID   : in std_logic;
     S_AXI_AWREADY   : out std_logic;
     S_AXI_WDATA     : in std_logic_vector(31 downto 0);
     S_AXI_WVALID    : in std_logic;
     S_AXI_WREADY    : out std_logic;
     S_AXI_BREADY    : in std_logic;
     S_AXI_BVALID    : out std_logic;
     S_AXI_BRESP     : out std_logic_vector(1 downto 0) 
	);
end Filter_3x3;

architecture Behavioral of Filter_3x3 is

component Convolver is
    generic (Column_Size:integer:=64);
    Port ( 
           Pixel_IN : in STD_LOGIC_VECTOR (15 downto 0);
           clock : in STD_LOGIC;
           CE : in STD_LOGIC;
           Reset : in STD_LOGIC;
           SIMD : in STD_LOGIC;
           Pad_CTRL : in STD_LOGIC_VECTOR (7 downto 0);
           Conv_Pixel : out STD_LOGIC_VECTOR (31 downto 0);
           K0,K1,K2,K3,K4,K5,K6,K7,K8: in std_logic_vector(3 downto 0)
          ); 
end component;

component FSM is
generic (Column_Size:integer:=64; Row_Size:integer:=64);
PORT(
     s_axis_clk,s_axis_rstn: in std_logic; 
	 s_axis_tvalid,s_axis_tlast: in std_logic;
	 s_axis_tready: out std_logic; 
	 s_axis_tdata: in std_logic_vector(15 downto 0);

	 m_axis_tvalid,m_axis_tlast: out std_logic;
	 m_axis_tready: in std_logic; 
	 m_axis_tdata: out std_logic_vector(31 downto 0);
	 
	 SIMD: in std_logic;
	 config_ready: out std_logic; 
	 Pad_CTRL: out std_logic_vector(7 downto 0);
	 Reset,CE: out std_logic; 
	 Pixel_IN: out std_logic_vector(15 downto 0);
	 Conv_Pixel: in std_logic_vector(31 downto 0)
	);
end component;

component AXI_LITE_REG is

port(
	config_ready	: in std_logic;
	K0,K1,K2,K3,K4,K5,K6,K7,K8: out std_logic_vector(3 downto 0);
	SIMD: out std_logic;
    S_AXI_ACLK  	: in std_logic;
    S_AXI_ARESETN   : in std_logic;
    S_AXI_AWADDR    : in std_logic_vector(3 downto 0);
    S_AXI_AWVALID   : in std_logic;
    S_AXI_AWREADY   : out std_logic;
    S_AXI_WDATA 	: in std_logic_vector(31 downto 0);
    S_AXI_WVALID    : in std_logic;
    S_AXI_WREADY    : out std_logic;
    S_AXI_BREADY    : in std_logic;
    S_AXI_BVALID    : out std_logic;
    S_AXI_BRESP     : out std_logic_vector(1 downto 0) 
);
end component;


signal PIXEL_IN: std_logic_vector(15 downto 0);
signal INPUT_DATA: std_logic_vector(15 downto 0);
signal OUTPUT_DATA, CONV_PIXEL: std_logic_vector(31 downto 0);

signal CE, SIMD,RESET,SAXIS_TREADY,MAXIS_TVALID, MAXIS_TLAST, MAXIS_TREADY: std_logic;
signal CLOCK,AXI_RESET,SAXIS_TLAST, SAXIS_TVALID: std_logic;
signal PAD_CTRL:std_logic_vector(7 downto 0);
signal config_ready: std_logic;

signal SAXI_AWADDR: std_logic_vector(3 downto 0);
signal SAXI_WDATA: std_logic_vector(31 downto 0);   
signal SAXI_AWVALID, SAXI_AWREADY,  SAXI_WVALID, SAXI_WREADY, SAXI_BREADY, SAXI_BVALID : std_logic;   
signal SAXI_BRESP: std_logic_vector(1 downto 0);

signal K0,K1,K2,K3,K4,K5,K6,K7,K8: std_logic_vector(3 downto 0);


begin


clock<=s_axis_clk;
AXI_RESET<=s_axis_rstn;
SAXIS_TVALID<=s_axis_tvalid;
SAXIS_TLAST<=s_axis_tlast;
s_axis_tready<=SAXIS_TREADY;
INPUT_DATA<=s_axis_tdata;
m_axis_tvalid<=MAXIS_TVALID;
m_axis_tlast<= MAXIS_TLAST;	

MAXIS_TREADY<=m_axis_tready;
m_axis_tdata<=OUTPUT_DATA; 

SAXI_AWADDR<=S_AXI_AWADDR;
SAXI_AWVALID<=S_AXI_AWVALID;
S_AXI_AWREADY<=SAXI_AWREADY;
SAXI_WDATA<=S_AXI_WDATA;
SAXI_WVALID<=S_AXI_WVALID;
S_AXI_WREADY<=SAXI_WREADY;
S_AXI_BRESP<=SAXI_BRESP;
S_AXI_BVALID<=SAXI_BVALID;
SAXI_BREADY<=S_AXI_BREADY;



Afsm:FSM
     generic map(Column_Size=>Column_Size, Row_Size=>Row_Size)
     port map(s_axis_clk=>clock,
              s_axis_rstn=>AXI_RESET,
              s_axis_tvalid=>  SAXIS_TVALID,
              s_axis_tlast=>SAXIS_TLAST,
              s_axis_tready=>SAXIS_TREADY,
              s_axis_tdata=>INPUT_DATA,
              m_axis_tvalid=>MAXIS_TVALID,
              m_axis_tlast=>MAXIS_TLAST,
              m_axis_tready=>MAXIS_TREADY,
              m_axis_tdata=>OUTPUT_DATA,
              Pad_CTRL=>PAD_CTRL,
              config_ready=>config_ready,
              Reset=>RESET,
              CE=>CE,
              PIXEL_IN=>PIXEL_IN,
              SIMD=>SIMD,
              CONV_PIXEL=>CONV_PIXEL
     );

CONV: Convolver
      generic map(Column_Size=>Column_Size)
      port map(PIXEL_IN=>PIXEL_IN,
               CONV_PIXEL=>CONV_PIXEL,
               Pad_CTRL=>PAD_CTRL,
               Reset=>RESET,
               CE=>CE,
               CLOCK=>CLOCK, 
               SIMD=>SIMD,
               K0=>K0,
               K1=>K1,
               K2=>K2,
               K3=>K3,
               K4=>K4,
               K5=>K5,
               K6=>K6,
               K7=>K7,
               K8=>K8                
      );

reg_fsm: AXI_LITE_REG
         port map(
             config_ready=>config_ready,   
             K0=>K0,
             K1=>K1,
             K2=>K2,
             K3=>K3,
             K4=>K4,
             K5=>K5,
             K6=>K6,
             K7=>K7,
             K8=>K8,
             SIMD=>SIMD, 
             S_AXI_ACLK=>clock,      
             S_AXI_ARESETN=>axi_reset,    
             S_AXI_AWADDR=>SAXI_AWADDR,     
             S_AXI_AWVALID=>SAXI_AWVALID,    
             S_AXI_AWREADY=>SAXI_AWREADY,    
             S_AXI_WDATA=>SAXI_WDATA,     
             S_AXI_WVALID=>SAXI_WVALID,    
             S_AXI_WREADY=>SAXI_WREADY,
             S_AXI_BRESP=>SAXI_BRESP,
             S_AXI_BVALID=>SAXI_BVALID,
             S_AXI_BREADY=>SAXI_BREADY     
         );


end Behavioral;
