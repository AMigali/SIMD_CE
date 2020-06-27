--CONVOLUTION COMPUTATION MODULE
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity Convolver is
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
end Convolver;

architecture Behavioral of Convolver is

component PixelBuffer is
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
end component;

component SIMD_Multiplier is
     Port (Pixel : in STD_LOGIC_VECTOR (15 downto 0);
           Kernel : in STD_LOGIC_VECTOR (3 downto 0);
           clock : in std_logic;
           CE : in std_logic;
           reset : in std_logic;
           SIMD: in std_logic; 
           Product : out STD_LOGIC_VECTOR (23 downto 0)  
           );
end component;

component SIMD_Adder is
    Port ( 
           OP1,OP2,OP3,OP4,OP5,OP6,OP7,OP8,OP9 : in STD_LOGIC_VECTOR (23 downto 0);
           SIMD : in STD_LOGIC;
           Clock : in STD_LOGIC;
           Reset : in STD_LOGIC;
           CE : in STD_LOGIC;
           Conv_Pixel : out STD_LOGIC_VECTOR (31 downto 0)
          );
end component;

type pixel_array is array(8 downto 0) of std_logic_vector(15 downto 0); 
type product_array is array(8 downto 0) of std_logic_vector(23 downto 0);
type kernel_array is array(8 downto 0) of std_logic_vector(3 downto 0);
type op_array is array(9 downto 1) of std_logic_vector(23 downto 0);

signal PIXEL: pixel_array;
signal Product: product_array;
signal KERNEL: kernel_array;
signal OP: op_array;


begin

KERNEL(0)<=K0;
KERNEL(1)<=K1;
KERNEL(2)<=K2;
KERNEL(3)<=K3;
KERNEL(4)<=K4;
KERNEL(5)<=K5;
KERNEL(6)<=K6;
KERNEL(7)<=K7;
KERNEL(8)<=K8;



buff: PixelBuffer
      generic map(Column_Size=>Column_Size)
      port map(
               Pixel_IN=>Pixel_IN,  
               Pad_CTRL=>Pad_CTRL,  
               Clock=>clock,  
               Reset=>reset,  
               CE=>CE,   
               SIMD=>SIMD, 
               Pixel_00=>PIXEL(8),
               Pixel_01=>PIXEL(7), 
               Pixel_02=>PIXEL(6),                    
               Pixel_10=>PIXEL(5), 
               Pixel_11=>PIXEL(4), 
               Pixel_12=>PIXEL(3),   
               Pixel_20=>PIXEL(2),
               Pixel_21=>PIXEL(1), 
               Pixel_22=>PIXEL(0) 
               );
MULT: for i in 0  to 8 generate
     inst:   SIMD_Multiplier 
             port map(Pixel=>PIXEL(i),
					  Kernel=>KERNEL(i),
					  clock=>clock,
					  CE=>CE,
					  reset=>reset,
					  SIMD=>SIMD,
					  Product=>Product(i)
					  );
     end generate; 

ADDER: SIMD_Adder
       port map(OP1=>OP(1),OP2=>OP(2),OP3=>OP(3),
				OP4=>OP(4),OP5=>OP(5),OP6=>OP(6),
				OP7=>OP(7),OP8=>OP(8),OP9=>OP(9),
				SIMD=>SIMD,Clock=>clock, 
				Reset=>reset, CE=>CE, 
				Conv_Pixel=>Conv_Pixel
				);




with SIMD select
     OP(1)<=Product(8) when '0',
                  (Product(8)(11 downto 0))&(Product(8)(23 downto 12)) when '1',
                  (Others=>'X') when others;

with SIMD select
     OP(2)<=Product(5) when '0',
                  (Product(5)(11 downto 0))&(Product(5)(23 downto 12)) when '1',
                  (Others=>'X') when others;

with SIMD select
     OP(3)<=Product(2) when '0',
                  (Product(2)(11 downto 0))&(Product(2)(23 downto 12)) when '1',
                  (Others=>'X') when others;

with SIMD select
     OP(7)<=Product(6) when '0',
                  (Product(6)(11 downto 0))&(Product(6)(23 downto 12)) when '1',
                  (Others=>'X') when others;                  

with SIMD select
     OP(8)<=Product(3) when '0',
                  (Product(3)(11 downto 0))&(Product(3)(23 downto 12)) when '1',
                  (Others=>'X') when others;

with SIMD select
     OP(9)<=Product(0) when '0',
                  (Product(0)(11 downto 0))&(Product(0)(23 downto 12)) when '1',
                  (Others=>'X') when others;


OP(4)<= Product(7);
OP(5)<= Product(4);
OP(6)<= Product(1);



end Behavioral;
