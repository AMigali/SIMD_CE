--CONVOLUTION COMPUTATION CONTROL UNIT
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity FSM is
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
     Pad_CTRL: out std_logic_vector(7 downto 0);
     Reset,CE: out std_logic;
     config_ready: out std_logic; 
     Pixel_IN: out std_logic_vector(15 downto 0);
     Conv_Pixel: in std_logic_vector(31 downto 0)
    );
end FSM;

architecture Behavioral of FSM is

--Zero Padding Control values
constant PAD_1: std_logic_vector(7 downto 0):="11010000";
constant PAD_2: std_logic_vector(7 downto 0):="00010110";
constant PAD_3: std_logic_vector(7 downto 0):="00001011";
constant PAD_4: std_logic_vector(7 downto 0):="01101000";
constant PAD_5: std_logic_vector(7 downto 0):="11111000";
constant PAD_6: std_logic_vector(7 downto 0):="11010110";
constant PAD_7: std_logic_vector(7 downto 0):="00011111";
constant PAD_8: std_logic_vector(7 downto 0):="01101011";
constant PAD_9: std_logic_vector(7 downto 0):="11111111";


type state_type is (RESET_STATE, IDLE, WAIT_IN, ACTIVE, LAST_ROW, WAIT_OUT);
signal state: state_type:=RESET_STATE;


signal LATENCY: integer:=0;
signal INCR : integer range 0 to 2; 
signal first_valid: integer;
signal LATENCY_IN: integer range 0 to (Column_Size+1);
signal first_image: std_logic:='0';

signal COLUMN:integer range 0  to (Column_Size-1):=0;
signal ROW:integer range 0  to (Row_Size-1):=0;

signal S1_Col:integer range 0 to (Column_Size-1);
signal S2_Col:integer range 0 to (Column_Size-1);

signal S1_Row:integer:=(Row_Size-1);
signal S2_Row:integer:=(Row_Size-2);

signal internal_valid,internal_ce,lastRow:std_logic;

begin


s_axis_tready<=m_axis_tready;
m_axis_tvalid<=internal_valid;
m_axis_tdata<=Conv_Pixel;
Pixel_IN<=s_axis_tdata;

internal_CE<=m_axis_tready and s_axis_tvalid;
CE<='0' WHEN (s_axis_rstn='0' OR internal_ce='0') else
    '1' when (internal_ce='1' or (lastRow='1' and m_axis_tready='1')) else
    '0';

INCR<=1 when SIMD='0' else 2;
first_valid<=6*INCR;
LATENCY_IN<= (Column_Size+1) when SIMD='0' else (Column_Size/2 +1);
S1_Col<=(Column_Size-INCR);
S2_Col<=(Column_Size-INCR-INCR);


--FSM Process
process(s_axis_clk) is
begin
    if rising_edge(s_axis_clk) then
       
        case state is
       
            when RESET_STATE =>
                internal_valid<='0';
                m_axis_tlast<='0';
                LATENCY<=0;
                ROW<=0;
                COLUMN<=0;
                reset<='1';
                config_ready<='1';
                first_image<='0';
                if(s_axis_rstn='1')then
                    if(m_axis_tready='1')then
                        state<=IDLE;
                        reset<='0';
                    end if;
                end if;
           
           
            when IDLE =>
                if(s_axis_rstn='0')then
                    state<=RESET_STATE;
                    reset<='1';
                end if;
                if(m_axis_tready='1') then
                   if(s_axis_tvalid='1')then
                      reset<='0';
                      config_ready<='0';
                      state<=WAIT_IN;
                   end if;
                end if;
               
            when WAIT_IN =>
                if(s_axis_rstn='0')then
                    state<=RESET_STATE;
                    reset<='1';
                    LATENCY<=0;
                end if;
                if(m_axis_tready='1')then
                    if(s_axis_tvalid='1')then
                        LATENCY<=LATENCY+1;
                        if(LATENCY=LATENCY_IN-1)then
                            state<=ACTIVE;
                            LATENCY<=0;    
                        end if;  
                    end if;
                end if;
               
			when ACTIVE=>
				if(s_axis_rstn='0')then
					state<=RESET_STATE;
					ROW<=0;
					COLUMN<=0;
					internal_valid<='0';
					reset<='1';
					first_image<='0';
				end if;
                if(internal_CE='1')then
                    COLUMN<=COLUMN+INCR;
                    if(COLUMN=S1_Col)then
                        if(ROW=(Row_Size-1))then
                            ROW<=0;   
                        else 
                            ROW<=ROW+1;
                        end if;
                        COLUMN<=0;
                    end if;
                    if(ROW=0)then
                        if(COLUMN>first_valid or first_image='1')then
                            internal_valid<='1';
                        end if;
                    elsif(ROW=(S1_Row)) then
                        internal_valid<='1';
                        first_image<='1';
                    else
                        internal_valid<='1';
                    end if;
                else
                    internal_valid<='0';
                end if;
				if(s_axis_tlast='1')then
					state<=LAST_ROW;
					COLUMN<=COLUMN+INCR;
					first_image<='0';
					lastRow<='1';
					if(m_axis_tready='1')then
					   internal_valid<='1';
					else
					   internal_valid<='0';
					end if;
				end if;
                               
               
            when LAST_ROW=>
                if(s_axis_rstn='0') then
                    state<=RESET_STATE;
                    reset<='1';
                    internal_valid<='0';
                    COLUMN<=0;
                    ROW<=0;
                end if;
                if(m_axis_tready='1')then
                    internal_valid<='1';
                    COLUMN<=COLUMN+INCR;
                    if(COLUMN=(S1_Col))then
                        if(ROW=(S1_Row))then
                            ROW<=0;   
                        else 
                            ROW<=ROW+1;
                        end if;
                        COLUMN<=0;
                    end if;
                end if;
                if(COLUMN=(S1_Col) and ROW=(S1_Row)) then
                    state<=WAIT_OUT;
                end if;
               
            when WAIT_OUT=>
                if(s_axis_rstn='0')then
                    state<=RESET_STATE;
                    reset<='1';
                    LATENCY<=0;
                    internal_valid<='0';
                    m_axis_tlast<='0';
                end if;
                if(m_axis_tready='1')then
                    LATENCY<=LATENCY+1;
                    internal_valid<='1';
                    if(LATENCY=6)then
                        m_axis_tlast<='1';
                        LATENCY<=0;
                        reset<='1';
                        lastRow<='0';
                        state<=RESET_STATE;    
                    end if;
                end if;
        end case;    
    end if;
end process;



zero_pad:
process(COLUMN,ROW,state)
begin
	if (state=ACTIVE) then
		if(ROW=0)then
			if(COLUMN=S1_Col)then   	--row zero, last column
				Pad_CTRL<=PAD_4;
			elsif(COLUMN=0) then 		--row zero, column zero
				Pad_CTRL<=PAD_1;
			else						--row zero, other columns
				Pad_CTRL<=PAD_5;	
			end if;
		elsif(ROW=S1_Row) then  
			if(COLUMN=S1_Col)then  		--last row, last column
				Pad_CTRL<=PAD_3;
			elsif(COLUMN=0) then  		--last row, column zero
				Pad_CTRL<=PAD_2;
			else						--last row, other columns
				Pad_CTRL<=PAD_7; 	
			end if;                                                         
		else
			if(COLUMN=S1_Col)then 		--other rows, last column
				Pad_CTRL<=PAD_8;
			elsif(COLUMN=0) then		--other rows, column zero
				Pad_CTRL<=PAD_6;
			else						--other rows, other columns
				Pad_CTRL<=PAD_9; 	
			end if;
		end if;		
	elsif(state=LAST_ROW) then
		if(ROW=(S2_Row))then			
			if(COLUMN=S1_Col)then		--second-last row, last column
				Pad_CTRL<=PAD_8;
			else						--second-last row, other columns
				Pad_CTRL<=PAD_9;
			end if;                         
		elsif(ROW=(S1_Row)) then		
			if(COLUMN=S1_Col)then		--last row, last column
				Pad_CTRL<=PAD_3;
			elsif(COLUMN=0) then		--last row, column zero
			    Pad_CTRL<=PAD_2;
			else						--last row, other columns
				Pad_CTRL<=PAD_7; 	
			end if;    
		end if;
	else
		Pad_CTRL<=PAD_1;
	end if;
end process;



end Behavioral;
