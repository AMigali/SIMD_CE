--AXI4LITE INTERFACE FOR CONFIGURATION
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AXI_LITE_REG is

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
end AXI_LITE_REG;

architecture Behavioural of AXI_LITE_REG is

-- AXI4LITE signals
signal axi_awaddr   : std_logic_vector(3 downto 0);
signal axi_awready  : std_logic;
signal axi_wready   : std_logic;
signal axi_bvalid   : std_logic:='0';

signal slv_reg0 :std_logic_vector(31 downto 0);
signal slv_reg1 :std_logic_vector(31 downto 0);

signal slv_reg_wren : std_logic;


begin

axi_awaddr<= S_AXI_AWADDR;
S_AXI_AWREADY   <= axi_awready;
S_AXI_WREADY    <= axi_wready;
S_AXI_BVALID    <= axi_bvalid;

K0<=slv_reg0(3 downto 0);
K1<=slv_reg0(7 downto 4);
K2<=slv_reg0(11 downto 8);
K3<=slv_reg0(15 downto 12);
K4<=slv_reg0(19 downto 16);
K5<=slv_reg0(23 downto 20);
K6<=slv_reg0(27 downto 24);
K7<=slv_reg0(31 downto 28);
K8<=slv_reg1(3 downto 0);
SIMD<=slv_reg1(4);



process (S_AXI_ACLK)
begin
  if rising_edge(S_AXI_ACLK) then 
    if S_AXI_ARESETN = '0' then
      axi_awready <= '0';
    else
      if (axi_awready='0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and config_ready='1' ) then
        axi_awready <= '1';
      else
        axi_awready <= '0';
      end if;
    end if;
  end if;
end process;


process (S_AXI_ACLK)
begin
  if rising_edge(S_AXI_ACLK) then 
    if S_AXI_ARESETN = '0' then
	   axi_wready <= '0';
    else
      if (axi_wready='0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and config_ready='1' ) then
		axi_wready <= '1';
      else
		axi_wready <= '0';
      end if;
    end if;
  end if;
end process;




slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID and config_ready;

process (S_AXI_ACLK)

begin
  if rising_edge(S_AXI_ACLK) then 
    if S_AXI_ARESETN = '0' then
      slv_reg0 <= (others => '0');
      slv_reg1 <= (others => '0');
    else
      if (slv_reg_wren = '1') then
        case axi_awaddr(0) is
          when '0' =>
                slv_reg0<= S_AXI_WDATA;
          when '1' =>
                slv_reg1<= S_AXI_WDATA;
          when others =>
            slv_reg0 <= slv_reg0;
            slv_reg1 <= slv_reg1;
        end case;
      end if;
    end if;
  end if;                   
end process; 

process(S_AXI_ACLK)
begin
   if rising_edge(S_AXI_ACLK) then 
      if S_AXI_ARESETN = '0' then
        axi_bvalid  <= '0';
        S_AXI_BRESP<="00";
      else
        if (slv_reg_wren='1' and axi_bvalid = '0'  ) then
          axi_bvalid <= '1';
          S_AXI_BRESP<="00";
        elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
          axi_bvalid <= '0';                                 
        end if;
      end if;
    end if;          
end process;

end Behavioural;