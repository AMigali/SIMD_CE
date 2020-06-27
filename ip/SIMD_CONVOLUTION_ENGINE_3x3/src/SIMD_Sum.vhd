--PARAMETRIC SIMD ADDER MODULE
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SIMD_Sum is
	generic(N:integer:=24);
    Port ( 
           A,B : in STD_LOGIC_VECTOR ((N-1) downto 0);
           SIMD : in STD_LOGIC;
           Clock : in STD_LOGIC;
           Reset : in STD_LOGIC;
           CE : in STD_LOGIC;
           SUM : out STD_LOGIC_VECTOR ((N+1) downto 0)
          );
end SIMD_Sum;

architecture Behavioral of SIMD_Sum is

signal A_ext, B_ext : std_logic_vector((N+1) downto 0);
signal Sum_MSB: std_logic_vector((N/2) downto 0);
signal Sum_LSB: std_logic_vector((N/2)+1 downto 0);
signal Cin_MSB, Cout_LSB: std_logic;
signal SUM2REG: std_logic_vector((N+1) downto 0);

begin

--Operators Construction
A_ext(((N/2)-1) downto 0)<=A(((N/2)-1) downto 0);
B_ext(((N/2)-1) downto 0)<=B(((N/2)-1) downto 0);

A_ext((N+1) downto N)<=A(N-1)&A(N-1);
B_ext((N+1) downto N)<=B(N-1)&B(N-1);	

with SIMD select
	 A_ext((N-1) downto N/2) <= A((N-1) downto N/2) when '0',
								A((N-2) downto N/2)&A((N/2)-1) when '1',
								(others=>'X') when others;
with SIMD select
	 B_ext((N-1) downto N/2) <= B((N-1) downto N/2) when '0',
								B((N-2) downto N/2)&B((N/2)-1) when '1',
								(others=>'X') when others;

--SIMD Sum computation								
Sum_LSB<=('0'&A_ext((N/2) downto 0)) + ('0'&B_ext((N/2)  downto 0));
Cout_LSB<=Sum_LSB((N/2)+1);

Sum_MSB<=A_ext((N+1) downto (N/2)+1)+B_ext((N+1) downto (N/2)+1)+Cin_MSB;

with SIMD select 
	 Cin_MSB<= Cout_LSB when '0',
			   '0' when '1',
			   'X' when others;
			   
SUM2REG<=Sum_MSB&Sum_LSB((N/2) downto 0);			   

--Output register
process(Clock)
         begin
             if(rising_edge(Clock)) then
                 if(reset='1') then
					SUM<=(others=>'0');
                 else 
                     if (CE='1') then
                         SUM<=SUM2REG;                
                     end if;
                 end if;
             end if;
         end process; 

			   
								
end Behavioral;
