library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use std.textio.all;
use IEEE.std_logic_textio.all;


entity write_to_file is

generic(log_file : string:="D:\VHDL\AXI_SIMD_FILTER_3X3\res.log");

    Port (         
          m_valid: in std_logic;
          clk:in std_logic;
          RISULTATO: in std_logic_vector(31 downto 0)
          );
end write_to_file;

architecture Behavioral of write_to_file is


file res_file: TEXT open write_mode is log_file;

begin

scrittura:
process(clk)
    variable a:line;
begin
    if (rising_edge(clk))then
        if(m_valid='1') then
            write(a, (RISULTATO));
            writeline(res_file, a);
        end if;
    end if;
end process;


end Behavioral;
