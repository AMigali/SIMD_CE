--SIMD ADDER TREE FOR CONVOLUTION
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SIMD_Adder is
    Port ( 
           OP1,OP2,OP3,OP4,OP5,OP6,OP7,OP8,OP9 : in STD_LOGIC_VECTOR (23 downto 0);
           SIMD : in STD_LOGIC;
           Clock : in STD_LOGIC;
           Reset : in STD_LOGIC;
           CE : in STD_LOGIC;
           Conv_Pixel : out STD_LOGIC_VECTOR (31 downto 0)
          );
end SIMD_Adder;


architecture Behavioral of SIMD_Adder is

component  SIMD_Sum is
	generic(N:integer:=24);
    Port ( 
           A,B : in STD_LOGIC_VECTOR ((N-1) downto 0);
           SIMD : in STD_LOGIC;
           Clock : in STD_LOGIC;
           Reset : in STD_LOGIC;
           CE : in STD_LOGIC;
           SUM : out STD_LOGIC_VECTOR ((N+1) downto 0)
          );
end component;

type OP_array is array(8 downto 0) of std_logic_vector(23 downto 0);
type SUM1_array is array(3 downto 0) of std_logic_vector(25 downto 0);
type SUM2_array is array(1 downto 0) of std_logic_vector(27 downto 0);


signal OP: OP_array;
signal SUM1: SUM1_array;
signal SUM2: SUM2_array;
signal SUM3: std_logic_vector(29 downto 0);
signal OP9_EXT,OP9_EXT_R1,OP9_EXT_R2,OP9_EXT_R3: std_logic_vector(29 downto 0);
signal SIGN9_MSB: std_logic_vector(5 downto 0);
signal SIGN9_LSB: std_logic_vector(2 downto 0);



begin
OP(0)<=OP1;
OP(1)<=OP2;
OP(2)<=OP3;
OP(3)<=OP4;
OP(4)<=OP5;
OP(5)<=OP6;
OP(6)<=OP7;
OP(7)<=OP8;
OP(8)<=OP9;

SIGN9_MSB<=(others=>OP9(23));
SIGN9_LSB<=(others=>OP9(11));

--Adder tree levels
adder_level_1: for i in 0  to 3 generate
			   inst: SIMD_Sum 
				 	 generic map(N=>24)
					 port map(A=>OP(2*i), B=>OP(2*i+1),clock=>clock,CE=>CE,reset=>reset,SIMD=>SIMD, SUM=>SUM1(i));
			   end generate;

adder_level_2: for i in 0  to 1 generate
			   inst: SIMD_Sum 
				 	 generic map(N=>26)
					 port map(A=>SUM1(2*i), B=>SUM1(2*i+1),clock=>clock,CE=>CE,reset=>reset,SIMD=>SIMD, SUM=>SUM2(i));
			   end generate;

adder_level_3: SIMD_Sum
			   generic map(N=>28)
			   port map(A=>SUM2(0), B=>SUM2(1),clock=>clock,CE=>CE,reset=>reset,SIMD=>SIMD, SUM=>SUM3);

with SIMD select
	 OP9_EXT<= SIGN9_MSB&OP9 when '0',
			   SIGN9_MSB(2 downto 0)&OP9(23 downto 12)&SIGN9_LSB&OP9(11 downto 0) when '1',
			   (others=>'X') when others;

adder_level_4: SIMD_Sum
			   generic map(N=>30)
			   port map(A=>SUM3, B=>OP9_EXT_R3,clock=>clock,CE=>CE,reset=>reset,SIMD=>SIMD, SUM=>Conv_Pixel);

--OP9 registers		   
process(Clock)
         begin
             if(rising_edge(Clock)) then
                 if(reset='1') then
					OP9_EXT_R1<=(others=>'0');
					OP9_EXT_R2<=(others=>'0');
					OP9_EXT_R3<=(others=>'0');
                 else 
                     if (CE='1') then
                         OP9_EXT_R1<=OP9_EXT;
						 OP9_EXT_R2<=OP9_EXT_R1;
						 OP9_EXT_R3<=OP9_EXT_R2;
                     end if;
                 end if;
             end if;
         end process; 			   
			   
end Behavioral;