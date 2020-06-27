--PARAMETRIC FIFO STRUCTURE
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FIFO_param is
    generic (fifoLen:integer:=61; wordLen:integer:=16);
    Port ( 
           FIFO_in : in STD_LOGIC_VECTOR (wordLen-1 downto 0);
           Clock : in STD_LOGIC;
           Reset : in STD_LOGIC; --active high
           CE : in STD_LOGIC;
           FIFO_out : out STD_LOGIC_VECTOR (wordLen-1 downto 0)
          );
           
end FIFO_param;

architecture Behavioral of FIFO_param is

    type reg_array is array(fifoLen-1 downto 0) of std_logic_vector(wordLen-1 downto 0);
    signal FIFO: reg_array;

begin

    process(Clock)  
        begin
        if(rising_edge(Clock)) then
            if(reset='1') then 
                  resetALL: for j in 0 to (fifoLen-1) loop
                                FIFO(j)<=(others=>'0');
                            end loop; 
            else
                if(CE='1') then 
                    gen_ff: for j in 1 to (fifoLen-1) loop
                                FIFO(j)<=FIFO(j-1);
                            end loop;
                            FIFO(0)<=FIFO_in;
                 end if;
             end if;
         end if;
    end process;

    FIFO_out<=FIFO(fifoLen-1);
			
end Behavioral;
