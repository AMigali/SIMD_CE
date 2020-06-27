library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity filter_testbench is
--  Port ( );
end filter_testbench;

architecture Behavioral of filter_testbench is

component Filter_3x3 is
--generic (Column_Size:integer:=64; Row_Size:integer:=64);
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
end component;

component write_to_file is
generic(log_file : string:="D:\1_TEST_IP_CORE_xohw20\res.log");

    Port (         
          m_valid: in std_logic;
          clk:in std_logic;
          RISULTATO: in std_logic_vector(31 downto 0)
          );
end component;

signal INGRESSO: std_logic_vector(15 downto 0):=(others=>'0'); 
signal USCITA: std_logic_vector(31 downto 0);
signal S_AXIS_TREADY,M_AXIS_TVALID, M_AXIS_TLAST: std_logic;
signal CLOCK,AXI_RESET,S_AXIS_TLAST, S_AXIS_TVALID, M_AXIS_TREADY: std_logic:='0';
signal S_AXI_AWREADY,S_AXI_WREADY, S_AXI_BREADY, S_AXI_BVALID: std_logic;
signal S_AXI_AWVALID,S_AXI_WVALID: std_logic:='0';
signal S_AXI_AWADDR: std_logic_vector(3 downto 0);
signal S_AXI_WDATA: std_logic_vector(31 downto 0);
signal S_AXI_BRESP: std_logic_vector(1 downto 0);
signal SIMD: std_logic;
signal K0,K1,K2,K3,K4,K5,K6,K7,K8: std_logic_vector(3 downto 0);
signal config_ok: std_logic:='0';
signal start: std_logic:='1';

----------------------------------------------------------------------------
-------TESTBENCH CONFIGURATION----------------------------------------------
----------------------------------------------------------------------------
constant Tclk: time := 10 ns; 
constant ResFile:string:="D:\1_TEST_IP_CORE_xohw20\res.log";  

constant Row_Size:integer:=64;
constant Column_Size:integer:=64;
begin
K0<="0001";
K1<="0001";
K2<="0001";
K3<="0001";
K4<="0001";
K5<="0001";
K6<="0001";
K7<="0001";
K8<="0001";    
SIMD<='1'; -- 0=16bit, 1=8bit
----------------------------------------------------------------------------
----------------------------------------------------------------------------

process
begin
    wait for Tclk/2;
    clock<=not(clock);
end process;
      

process
begin
    wait for 9*Tclk;  
    AXI_reset<='1';
    wait;
end process;

process
begin
	wait for 30*Tclk;
	m_axis_tready<='1';
	wait;
end process;	  

S_AXI_BREADY<='1';		
config:	process
		begin
				wait for 10*Tclk;
				S_AXI_AWADDR<="0000";
				S_AXI_AWVALID<='1';
				wait for 4*Tclk; 
				S_AXI_WDATA<=(K7&K6&K5&K4&K3&K2&K1&K0);
				S_AXI_WVALID<='1';
				wait for 4*Tclk; 
				S_AXI_AWADDR<="0001";
				S_AXI_WDATA<="000000000000000000000000000"&SIMD&K8;
				wait for 4*Tclk; 
				S_AXI_AWVALID<='0';
				S_AXI_WVALID<='0';
				config_ok<='1';
				wait;
		end process;

		
process
begin
      wait for 34*Tclk;
	  s_axis_tvalid<='1';
      wait for 256*Tclk;
	  s_axis_tvalid<='0';
	  wait for 10*Tclk;
	  s_axis_tvalid<='1';
	  --wait for ((Column_Size*Row_Size/(conv_integer(SIMD)+1))-256)*Tclk;
	  --s_axis_tvalid<='0';
	  wait;
end process;

        
------16-BIT DataIN     
--process
--begin
--    INGRESSO(15 downto 0)<=(Others=>'1');
--    wait for 34*Tclk;
--    for i in 0 to (Column_Size*Row_Size) loop
--        INGRESSO(15 downto 0)<=INGRESSO(15 downto 0)+1;
--        if(i=256)then
--           wait for 10*Tclk;
--        end if;
--        if(i=(Column_Size*Row_Size - 1))then
--           s_axis_tlast<='1';
--        else
--           s_axis_tlast<='0';
--        end if;
--        wait for Tclk;
--    end loop;
--end process; 
 
----8-BIT DataIN     
process
begin
    INGRESSO(15 downto 0)<=(others=>'1');
    wait for 34*Tclk;
    for i in 0 to ((Column_Size*Row_Size/2)) loop 
        INGRESSO(15 downto 8)<=INGRESSO(15 downto 8)+1;
        INGRESSO(7 downto 0)<=INGRESSO(7 downto 0)+1;
        if(i=256)then
            wait for 10*Tclk;
        end if;
        if(i=((Column_Size*Row_Size/2) - 1))then
           s_axis_tlast<='1';
        else
           s_axis_tlast<='0';
        end if;
        wait for Tclk;
    end loop;
 end process;
 
 

uut: Filter_3x3
     --generic map(Column_Size=>64, Row_Size=>64)
     port map(s_axis_clk=>clock,
              s_axis_rstn=>AXI_RESET,
              s_axis_tvalid=>S_AXIS_TVALID,
              s_axis_tlast=>S_AXIS_TLAST,
              s_axis_tready=>S_AXIS_TREADY,
              s_axis_tdata=>INGRESSO,
              m_axis_tvalid=>M_AXIS_TVALID,
              m_axis_tlast=>M_AXIS_TLAST,
              m_axis_tready=>M_AXIS_TREADY,
              m_axis_tdata=>USCITA,
			  S_AXI_AWADDR=>S_AXI_AWADDR,
 			  S_AXI_AWVALID=>S_AXI_AWVALID,
			  S_AXI_AWREADY=>S_AXI_AWREADY,
			  S_AXI_WDATA=>S_AXI_WDATA,    
			  S_AXI_WVALID=>S_AXI_WVALID,  
			  S_AXI_WREADY=>S_AXI_WREADY,			  
			  S_AXI_BREADY=>S_AXI_BREADY,
			  S_AXI_BVALID=>S_AXI_BVALID,  
			  S_AXI_BRESP=>S_AXI_BRESP             
			 );		

res_log: write_to_file
         generic map(log_file=>ResFile)
         port map(m_valid=>M_AXIS_TVALID, clk=>clock, RISULTATO=>USCITA);
end Behavioral;