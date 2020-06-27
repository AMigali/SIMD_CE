--SIMD BINARY MULTIPLIER FOR CONVOLUTIONS
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_signed.all;

entity SIMD_Multiplier is
     Port (Pixel : in STD_LOGIC_VECTOR (15 downto 0);
           Kernel : in STD_LOGIC_VECTOR (3 downto 0);
           clock : in std_logic;
           CE : in std_logic;
           reset : in std_logic;
           SIMD: in std_logic; 
           Product : out STD_LOGIC_VECTOR (23 downto 0)  
           );
end SIMD_Multiplier;

architecture Behavioral of SIMD_Multiplier is

signal AND0,AND1,AND2,AND3: std_logic_vector(15 downto 0);
signal KV0,KV1,KV2,KV3: std_logic_vector(15 downto 0);

--Partial Products to be registered and extended
signal P0,P1,P2: std_logic_vector(19 downto 0); 
signal P3: std_logic_vector(20 downto 0);

--Registered partial products (to be extended)
signal R0,R1,R2: std_logic_vector(19 downto 0); 
signal R3: std_logic_vector(20 downto 0);

signal K3_2, K3_reg1, K3_reg2 : std_logic;

--Partial products to be summed
signal PP0,PP1,PP2,PP3,PP4: std_logic_vector(23 downto 0); 

--Registered PP4
signal RPP4, RRPP4: std_logic_vector(23 downto 0);

--Partial sums and registered partial sums 
signal SP01, SP23, SP03, SP04: std_logic_vector(23 downto 0);
signal RSP01, RSP23, RSP03: std_logic_vector(23 downto 0);

signal AND3XOR : std_logic_vector(15 downto 0);

begin

KV0<=(Others => Kernel(0));
KV1<=(Others => Kernel(1));
KV2<=(Others => Kernel(2));
KV3<=(Others => Kernel(3));


--Partial Products computation
AND0<= Pixel and KV0;
AND1<= Pixel and KV1;
AND2<= Pixel and KV2;
AND3<= Pixel and KV3;


--SIMD management of partial products

with SIMD select
   P0(19 downto 8)<= ("0000"&AND0(15 downto 8)) when '0',
					 (AND0(15 downto 8)&"0000") when '1',
					 (others=>'X') when others;
P0(7 downto 0)<=AND0(7 downto 0);

                     
with SIMD select
   P1(19 downto 8)<= ("0000"&AND1(15 downto 8)) when '0',
					 (AND1(15 downto 8)&"0000") when '1',
					 (others=>'X') when others;
P1(7 downto 0)<=AND1(7 downto 0);                             


                     
with SIMD select
    P2(19 downto 8)<= ("0000"&AND2(15 downto 8)) when '0',
					  (AND2(15 downto 8)&"0000") when '1',
					  (others=>'X') when others;
P2(7 downto 0)<=AND2(7 downto 0);



AND3XOR<=AND3 xor KV3;

with SIMD select
    P3(19 downto 8)<= (KV3(3 downto 0)&AND3XOR(15 downto 8)) when '0',
					  (AND3XOR(15 downto 8)&"000"&KV3(0)) when '1',
					  (others=>'X') when others;
P3(20)<=KV3(0);
P3(7 downto 0)<=AND3XOR(7 downto 0);


with SIMD select
   K3_2<= '0' when '0',
          Kernel(3) when '1',
          'X' when others;

           
--Registers
process(Clock)
begin
    if(rising_edge(Clock)) then
        if(reset='1') then
              R0<=(Others=>'0');
              R1<=(Others=>'0');
              R2<=(Others=>'0');
              R3<=(Others=>'0');
              K3_reg1<='0';
              K3_reg2<='0';
        else 
            if (CE='1') then
                R0<=P0;
                R1<=P1;
                R2<=P2;
                R3<=P3;
                K3_reg1<=Kernel(3);
                K3_reg2<=K3_2;                   
            end if;
        end if;
    end if;
end process;


--Partial Products extension
PP0<="0000"&R0;
PP1<="000"&R1&'0';
PP2<="00"&R2&"00";
PP3<=R3&"000";
PP4<=(15=>K3_reg2, 3=>K3_reg1, others=>'0');



--Partial Products Sum
SP01<=PP0+PP1;
SP23<=PP2+PP3;
SP03<=RSP01+RSP23;
SP04<=RSP03+RRPP4;

--Adder Pipeline Registers 
process(Clock)
begin
    if(rising_edge(Clock)) then
        if(reset='1') then
              RSP01<=(Others=>'0');
              RSP23<=(Others=>'0');
              RSP03<=(Others=>'0');
              RPP4<=(Others=>'0');
			  RRPP4<=(Others=>'0');
			  Product<=(Others=>'0');
        else 
            if (CE='1') then
				  RSP01<=SP01;
				  RSP23<=SP23;
				  RSP03<=SP03;
				  RPP4<=PP4;
				  RRPP4<=RPP4;
				  Product<=SP04;
            end if;
        end if;
    end if;
end process;




end Behavioral;