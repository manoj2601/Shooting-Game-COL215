
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.ALL;
use ieee.std_logic_arith.all;

entity PmodOLEDCtrl is
	Port ( 
		CLK 	: in  STD_LOGIC;
		RST 	: in	STD_LOGIC;
		CS  	: out STD_LOGIC;
		SDIN	: out STD_LOGIC;
		SCLK	: out STD_LOGIC;
		DC		: out STD_LOGIC;
		RES	: out STD_LOGIC;
		VBAT	: out STD_LOGIC;
		VDD	: out STD_LOGIC;
		low : in std_logic;
		medium : in std_logic;
		high : in std_logic;
		PB1 : in std_logic;
		PB2 : in std_logic;
		PB3 : in std_logic;
		PB4 : in std_logic;
        an0 : OUT std_logic;
        an1 : OUT std_logic;
        an2 : OUT std_logic;
        an3 : OUT std_logic;
        seg : OUT std_logic_vector(6 downto 0);
         led : out std_logic_vector(15 downto 0)
		);
end PmodOLEDCtrl;

architecture Behavioral of PmodOLEDCtrl is

component OledInit is
Port ( CLK 	: in  STD_LOGIC;
		RST 	: in	STD_LOGIC;
		EN		: in  STD_LOGIC;
		CS  	: out STD_LOGIC;
		SDO	: out STD_LOGIC;
		SCLK	: out STD_LOGIC;
		DC		: out STD_LOGIC;
		RES	: out STD_LOGIC;
		VBAT	: out STD_LOGIC;
		VDD	: out STD_LOGIC;
		FIN  : out STD_LOGIC);
end component;



component OledEx is
    Port ( CLK 	: in  STD_LOGIC;
		RST 	: in	STD_LOGIC;
		EN		: in  STD_LOGIC;
		CS  	: out STD_LOGIC;
		SDO		: out STD_LOGIC;
		SCLK	: out STD_LOGIC;
		DC		: out STD_LOGIC;
		FIN  : out STD_LOGIC;
		low : in std_logic;
		medium : in std_logic;
		high : in std_logic;
		PB1 : in std_logic;
        PB2 : in std_logic;
        PB3 : in std_logic;
        PB4 : in std_logic;
        led : out std_logic_vector(15 downto 0);
        an0 : OUT std_logic;
                an1 : OUT std_logic;
                an2 : OUT std_logic;
                an3 : OUT std_logic;
                seg : OUT std_logic_vector(6 downto 0)
		);
end component;

type states is (Idle,
					OledInitialize,
					OledExample,
					Done);

signal current_state 	: states := Idle;

signal init_en				: STD_LOGIC := '0';
signal init_done			: STD_LOGIC;
signal init_cs				: STD_LOGIC;
signal init_sdo			: STD_LOGIC;
signal init_sclk			: STD_LOGIC;
signal init_dc				: STD_LOGIC;

signal example_en			: STD_LOGIC := '0';
signal example_cs			: STD_LOGIC;
signal example_sdo		: STD_LOGIC;
signal example_sclk		: STD_LOGIC;
signal example_dc			: STD_LOGIC;
signal example_done		: STD_LOGIC;

begin

	Init: OledInit port map(CLK, RST, init_en, init_cs, init_sdo, init_sclk, init_dc, RES, VBAT, VDD, init_done);
	Example: OledEx Port map(CLK, RST, example_en, example_cs, example_sdo, example_sclk, example_dc, example_done, low, medium, high, PB1, PB2, PB3, PB4, led, an0, an1, an2, an3, seg);
	CS <= init_cs when (current_state = OledInitialize) else
			example_cs;
	SDIN <= init_sdo when (current_state = OledInitialize) else
			example_sdo;
	SCLK <= init_sclk when (current_state = OledInitialize) else
			example_sclk;
	DC <= init_dc when (current_state = OledInitialize) else
			example_dc;
	init_en <= '1' when (current_state = OledInitialize) else
					'0';
	example_en <= '1' when (current_state = OledExample) else
					'0';
	process(CLK)
	begin
		if(rising_edge(CLK)) then
			if(RST = '1') then
				current_state <= Idle;
			else
				case(current_state) is
					when Idle =>
						current_state <= OledInitialize;
					when OledInitialize =>
						if(init_done = '1') then
							current_state <= OledExample;
						end if;
					when OledExample =>
						if(example_done = '1') then
							current_state <= Done;
						end if;
				
					when Done =>
						current_state <= Done;
					when others =>
						current_state <= Idle;
				end case;
			end if;
		end if;
	end process;
	
	
end Behavioral;


