--SIMD BUFFER
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PixelBuffer is
    generic (Column_Size:integer:=64);
    Port ( 
           Pixel_IN : in STD_LOGIC_VECTOR (15 downto 0); 
           Pad_CTRL : in STD_LOGIC_VECTOR (7 downto 0); 
           Clock : in STD_LOGIC;
           Reset : in STD_LOGIC;
           CE : in STD_LOGIC; 
           SIMD: in std_logic;
           Pixel_00 : out STD_LOGIC_VECTOR (15 downto 0);
           Pixel_01 : out STD_LOGIC_VECTOR (15 downto 0);
           Pixel_02 : out STD_LOGIC_VECTOR (15 downto 0);                       
           Pixel_10 : out STD_LOGIC_VECTOR (15 downto 0);
           Pixel_11 : out STD_LOGIC_VECTOR (15 downto 0);
           Pixel_12 : out STD_LOGIC_VECTOR (15 downto 0);   
           Pixel_20 : out STD_LOGIC_VECTOR (15 downto 0);
           Pixel_21 : out STD_LOGIC_VECTOR (15 downto 0);
           Pixel_22 : out STD_LOGIC_VECTOR (15 downto 0)
          );
           
end PixelBuffer;

architecture Behavioral of PixelBuffer is

    constant FIFO_H1_len: integer:= (Column_Size/2)-3;
	constant FIFO_H2_len: integer:= Column_Size/2;

   
    type fifoIn is array(1 downto 0) of std_logic_vector(15 downto 0);
	type fifoOut is array(1 downto 0) of std_logic_vector(15 downto 0);
     
    signal FIFO_H1_in, FIFO_H2_in: fifoIn;
    signal FIFO_H1_out, FIFO_H2_out: fifoOut;	
   
    signal P00,P01,P02,P10,P12,P20,P21,P22: std_logic_vector(15 downto 0);
    
    signal CE2: std_logic;
    
    
    signal d00,d01,d02,d10,d11,d12,d20,d21,d22,FIFO1_out,FIFO2_out: std_logic_vector(15 downto 0); 
   
    
    
	
	component FIFO_param is
    generic (fifoLen:integer:=61; wordLen:integer:=16);
    Port ( 
           FIFO_in : in STD_LOGIC_VECTOR (wordLen-1 downto 0);
           Clock : in STD_LOGIC;
           Reset : in STD_LOGIC; --active high
           CE : in STD_LOGIC;
           FIFO_out : out STD_LOGIC_VECTOR (wordLen-1 downto 0)
          );
           
	end component;

        
begin

--Window Registers
REGISTERS:  process(Clock) 
            begin
            if(rising_edge(Clock)) then
                if(reset='1') then 
                      d00<=(Others=>'0');
                      d01<=(Others=>'0');
                      d02<=(Others=>'0');
                      d10<=(others=>'0');
                      d11<=(others=>'0');
                      d12<=(others=>'0');
                      d20<=(others=>'0');
                      d21<=(others=>'0');
                      d22<=(others=>'0');
                else 
                    if (CE='1') then  
                        d00<=Pixel_IN;
                        d01<=d00;
                        d02<=d01;
                        d10<=FIFO1_out;
                        d11<=d10;
                        d12<=d11;
                        d20<=FIFO2_out;
                        d21<=d20;
                        d22<=d21;
                    end if;
                end if;
            end if;
            end process;
    
	
--FIFOs second half clock enable signal   	
with SIMD select  
     CE2<=CE when '0',
          '0' when '1',
          'X' when others;
 

--FIFOs
fifo_H1:   for i in 0  to 1 generate
           inst: FIFO_param 
                 generic map(fifoLen=>FIFO_H1_len, wordLen=>16)
                 port map(FIFO_in=>FIFO_H1_in(i),clock=>clock,CE=>CE,reset=>reset,FIFO_out=>FIFO_H1_out(i));
           end generate;
 
 FIFO_H1_in(0)<=d02;
 FIFO_H1_in(1)<=d12;
 
fifo_H2:   for i in 0  to 1 generate
           inst: FIFO_param 
                 generic map(fifoLen=>FIFO_H2_len, wordLen=>16)
                 port map(FIFO_in=>FIFO_H2_in(i),clock=>clock,CE=>CE2,reset=>reset,FIFO_out=>FIFO_H2_out(i));
           end generate;
 
 FIFO_H2_in(0)<=FIFO_H1_out(0);
 FIFO_H2_in(1)<=FIFO_H1_out(1);

    
with SIMD select
     FIFO1_out<= FIFO_H2_out(0) when '0',
                 FIFO_H1_out(0) when '1',
                 (others=>'X') when others;


with SIMD select
     FIFO2_out<= FIFO_H2_out(1) when '0',
                 FIFO_H1_out(1) when '1',
                 (others=>'X') when others;    
    
    
-- Zero Padding Multiplexers
    with Pad_CTRL(7) select
        P00 <= d00 when '1',
               (others=>'0') when '0',
               (others=>'X') when others;
 
     with Pad_CTRL(6) select
         P01 <= d01 when '1',
                (others=>'0') when '0',
                (others=>'X') when others;  

     with Pad_CTRL(5) select
         P02 <= d02 when '1',
                (others=>'0') when '0',
                (others=>'X') when others;  

     with Pad_CTRL(4) select
         P10 <= d10 when '1',
                (others=>'0') when '0',
                (others=>'X') when others;  
      
     Pixel_11 <= d11; 
                     
     with Pad_CTRL(3) select
         P12 <= d12 when '1',
                (others=>'0') when '0',
                (others=>'X') when others;  
    
     with Pad_CTRL(2) select
          P20 <= d20 when '1',
                (others=>'0') when '0',
                (others=>'X') when others;  
               
     with Pad_CTRL(1) select
          P21 <= d21 when '1',
                (others=>'0') when '0',
                (others=>'X') when others;  

     with Pad_CTRL(0) select
          P22 <= d22 when '1',
                (others=>'0') when '0',
                (others=>'X') when others;  
     
     
 
 -- Window construction multiplexers
    Pixel_02(7 downto 0)<=P02(7 downto 0);
    with SIMD select
         Pixel_02(15 downto 8) <= P02(15 downto 8) when '0',
                                  P01(15 downto 8) when '1',
                                  (others=>'X') when others;
    
    Pixel_12(7 downto 0)<=P12(7 downto 0);
    with SIMD select
         Pixel_12(15 downto 8) <= P12(15 downto 8) when '0',
                                  d11(15 downto 8) when '1',
                                  (others=>'X') when others;

    Pixel_22(7 downto 0)<=P22(7 downto 0);
    with SIMD select
         Pixel_22(15 downto 8) <= P22(15 downto 8) when '0',
                                  P21(15 downto 8) when '1',
                                  (others=>'X') when others;
    
     Pixel_00(15 downto 8)<=P00(15 downto 8);
     with SIMD select
          Pixel_00(7 downto 0) <= P00(7 downto 0) when '0',
                                  P01(7 downto 0) when '1',
                                  (others=>'X') when others;
     
     Pixel_10(15 downto 8)<=P10(15 downto 8);
     with SIMD select
          Pixel_10(7 downto 0) <= P10(7 downto 0) when '0',
                                  d11(7 downto 0) when '1',
                                  (others=>'X') when others;
    
     Pixel_20(15 downto 8)<=P20(15 downto 8);
     with SIMD select
          Pixel_20(7 downto 0) <= P20(7 downto 0) when '0',
                                  P21(7 downto 0) when '1',
                                  (others=>'X') when others;
    Pixel_01<=P01;
    Pixel_21<=P21;

end Behavioral;