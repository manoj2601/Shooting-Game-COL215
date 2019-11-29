
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity OledEx is
    Port ( CLK 	: in  STD_LOGIC; --System CLK
			  RST 	: in	STD_LOGIC; --Synchronous Reset
			  EN		: in  STD_LOGIC; --Example block enable pin
			  CS  	: out STD_LOGIC; --SPI Chip Select
			  SDO		: out STD_LOGIC; --SPI Data out
			  SCLK	: out STD_LOGIC; --SPI Clock
			  DC		: out STD_LOGIC; --Data/Command Controller
			  FIN  	: out STD_LOGIC;
			  low : in STD_LOGIC;
			  medium : in STD_LOGIC;
			  high : in std_logic;
			  PB1 : in std_logic;
			  PB2 : in std_logic;
			  PB3 : in std_logic;
			  PB4 : in std_logic;
			  led : out std_logic_vector(15 downto 0);
			  an0 : out std_logic;
			  an1 : OUT std_logic;
              an2 : OUT std_logic;
              an3 : OUT std_logic;
              seg : OUT std_logic_vector(6 downto 0)
			  );--Finish flag for example block
end OledEx;

architecture Behavioral of OledEx is

--SPI Controller Component
COMPONENT SpiCtrl
    PORT(
         CLK : IN  std_logic;
         RST : IN  std_logic;
         SPI_EN : IN  std_logic;
         SPI_DATA : IN  std_logic_vector(7 downto 0);
         CS : OUT  std_logic;
         SDO : OUT  std_logic;
         SCLK : OUT  std_logic;
         SPI_FIN : OUT  std_logic
        );
    END COMPONENT;

--Delay Controller Component
COMPONENT Delay
    PORT(
         CLK : IN  std_logic;
         RST : IN  std_logic;
         DELAY_MS : IN  std_logic_vector(11 downto 0);
         DELAY_EN : IN  std_logic;
         DELAY_FIN : OUT  std_logic
        );
    END COMPONENT;
	 
COMPONENT charLib
  PORT (
    clka : IN STD_LOGIC; --Attach System Clock to it
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0); --First 8 bits is the ASCII value of the character the last 3 bits are the parts of the char
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) --Data byte out
  );
END COMPONENT;

component sevensegment is
  Port (
  clk : IN std_logic;
  an0 : OUT std_logic;
  an1 : OUT std_logic;
  an2 : OUT std_logic;
  an3 : OUT std_logic;
  seg : OUT std_logic_vector(6 downto 0);
    print : in integer;
  en1 : in std_logic
   );
end component;

--States for state machine
type states is (Idle,
				ClearDC,
				SetPage,
				PageNum,
				LeftColumn1,
				LeftColumn2,
				SetDC,
				Alphabet,
				Page1, Page2, Page3, Page4,Page5, Page6, Page7, Page8 , Page9, Page10,Page11 , Page12,
				Wait1,
				Wait11,Wait12, Wait13, Wait14 , Wait15 , Wait16 , Wait17 , Wait18 , Wait19, Wait110, Wait111,Wait112, Wait113,
				ClearScreen,ClearScreen0,
				ClearScreen1, ClearScreen2, ClearScreen3, ClearScreen4, ClearScreen5, ClearScreen6, ClearScreen7, ClearScreen8, ClearScreen9, ClearScreen10, ClearScreen11,ClearScreen12, ClearScreen13,
				Wait2,Wait0, Wait00,
				Wait21,Wait22, Wait23, Wait24 , Wait25 , Wait26 , Wait27 , Wait28 , Wait29, Wait210, Wait211, Wait212, Wait213, 
				DigilentScreen,
				Next11,
				UpdateScreen,
				SendChar1,
				SendChar2,
				SendChar3,
				SendChar4,
				SendChar5,
				SendChar6,
				SendChar7,
				SendChar8,
				ReadMem, scorecard,
				ReadMem2,
				Done,
				Transition1,
				Transition2,
				Transition3,
				Transition4,
				Transition5,
				Welcome
					);
type OledMem is array(0 to 3, 0 to 15) of STD_LOGIC_VECTOR(7 downto 0);

--Variable that contains what the screen will be after the next UpdateScreen state
signal current_screen : OledMem; 
signal next1 : OledMem;

constant alphabet_screen : OledMem :=((X"20",X"20",X"57",X"65",X"6c",X"63",X"6f",X"6d",X"65",X"20",X"74",X"6f",X"2e",X"2e",X"2e",X"20"),	
												(X"20",X"20",X"20",X"54",X"68",X"65",X"20",X"67",X"61",X"6d",X"65",X"20",X"20",X"20",X"20",X"20"),
												(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
												(X"20",X"20",X"20",X"20",X"20",X"53",X"48",X"4f",X"54",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
												
											

--Constant that fills the screen with blank (spaces) entries
constant clear_screen : OledMem :=   ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
												(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
												(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
												(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));

constant welcome_screen : OledMem :=   ((X"53",X"65",X"6c",X"65",X"63",X"74",X"20",X"61",X"20",X"6d",X"6f",X"64",X"65",X"20",X"3a",X"20"),	
												(X"4c",X"6f",X"77",X"20",X"20",X"20",X"20",X"20",X"53",X"77",X"69",X"74",X"63",X"68",X"20",X"31"),
												(X"4d",X"65",X"64",X"69",X"75",X"6d",X"20",X"20",X"53",X"77",X"69",X"74",X"63",X"68",X"20",X"32"),
												(X"48",X"69",X"67",X"68",X"20",X"20",X"20",X"20",X"53",X"77",X"69",X"74",X"63",X"68",X"20",X"33"));												
							
constant Page1_screen : OledMem := ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"31"),

                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"31",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"31",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
                                                
constant Page2_screen : OledMem := ((X"20",X"20",X"20",X"20",X"42",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"42",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"42",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"42",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
                                                
constant Page3_screen : OledMem := ((X"20",X"20",X"63",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"63",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
                                                
                                                
constant Page4_screen : OledMem := ((X"37",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"37",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"",X"20",X"20",X"20",X"20",X"20",X"37",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"37",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
                                                
                                                
  constant Page5_screen : OledMem := ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"48",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
                                                
                                                
constant Page6_screen : OledMem := ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"40",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"40",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
                                                
                                                
constant Page7_screen : OledMem := ((X"20",X"70",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"70",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"70",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
                                                
                                                
constant Page8_screen : OledMem := ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"21",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"21",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"21",X"20",X"20",X"20",X"20",X"20"));
                                                
                                                
constant Page9_screen : OledMem := ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"23",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
                                                
                                                
constant Page10_screen : OledMem := ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"2a"),
                                                (X"2a",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"2a",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"2a"));
                                                
constant Page11_screen : OledMem :=   ((X"20",X"20",X"5a",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                       (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                      (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"5a",X"20",X"20",X"20",X"20"),
                                      (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));       
                                      
constant Page12_screen : OledMem :=   ((X"20",X"20",X"20",X"20",X"25",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                      (X"20",X"20",X"25",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                       (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"2a",X"20",X"25",X"20",X"20"),
                                       (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"25",X"20",X"20",X"20",X"20",X"20",X"20"));                                                
                                                                                                                                                                     
                                                
   --scorecard screens                                             
  constant scorecard_screen0 : OledMem :=   ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                            (X"59",X"6f",X"75",X"72",X"20",X"53",X"63",X"6f",X"72",X"65",X"20",X"69",X"73",X"20",X"3a",X"20"),
                                           (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"30",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                           (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
                                    
  constant scorecard_screen1 : OledMem :=   ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                            (X"59",X"6f",X"75",X"72",X"20",X"53",X"63",X"6f",X"72",X"65",X"20",X"69",X"73",X"20",X"3a",X"20"),
                                            (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"31",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                            (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20")); 
                                            
  constant scorecard_screen2 : OledMem :=   ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                              (X"59",X"6f",X"75",X"72",X"20",X"53",X"63",X"6f",X"72",X"65",X"20",X"69",X"73",X"20",X"3a",X"20"),
                                               (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"32",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                              (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));      
                                              
   constant scorecard_screen3 : OledMem :=   ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                              (X"59",X"6f",X"75",X"72",X"20",X"53",X"63",X"6f",X"72",X"65",X"20",X"69",X"73",X"20",X"3a",X"20"),
                                                (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"33",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                              (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));    
                                              
  constant scorecard_screen4 : OledMem :=   ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                            (X"59",X"6f",X"75",X"72",X"20",X"53",X"63",X"6f",X"72",X"65",X"20",X"69",X"73",X"20",X"3a",X"20"),
                                            (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"34",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                            (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));      
                                                                                                                                                                
constant scorecard_screen5 : OledMem := ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                                        (X"59",X"6f",X"75",X"72",X"20",X"53",X"63",X"6f",X"72",X"65",X"20",X"69",X"73",X"20",X"3a",X"20"),
                                                        (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"35",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                                        (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));                                                                       
                                           
 constant scorecard_screen6 : OledMem :=   ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                           (X"59",X"6f",X"75",X"72",X"20",X"53",X"63",X"6f",X"72",X"65",X"20",X"69",X"73",X"20",X"3a",X"20"),
                                           (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"36",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                           (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
                                           
  constant scorecard_screen7 : OledMem :=   ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                            (X"59",X"6f",X"75",X"72",X"20",X"53",X"63",X"6f",X"72",X"65",X"20",X"69",X"73",X"20",X"3a",X"20"),
                                             (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"37",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                            (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
                                            
   constant scorecard_screen8 : OledMem :=   ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                              (X"59",X"6f",X"75",X"72",X"20",X"53",X"63",X"6f",X"72",X"65",X"20",X"69",X"73",X"20",X"3a",X"20"),
                                             (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"38",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                             (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
                                             
 constant scorecard_screen9 : OledMem :=   ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                            (X"59",X"6f",X"75",X"72",X"20",X"53",X"63",X"6f",X"72",X"65",X"20",X"69",X"73",X"20",X"3a",X"20"),
                                           (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"39",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                           (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));                                             
                                             
   constant scorecard_screen10 : OledMem :=   ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                              (X"59",X"6f",X"75",X"72",X"20",X"53",X"63",X"6f",X"72",X"65",X"20",X"69",X"73",X"20",X"3a",X"20"),
                                              (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"31",X"30",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                              (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));

constant scorecard_screen11 : OledMem :=   ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                              (X"59",X"6f",X"75",X"72",X"20",X"53",X"63",X"6f",X"72",X"65",X"20",X"69",X"73",X"20",X"3a",X"20"),
                                              (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"31",X"31",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                              (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));

constant scorecard_screen12 : OledMem :=   ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
                                              (X"59",X"6f",X"75",X"72",X"20",X"53",X"63",X"6f",X"72",X"65",X"20",X"69",X"73",X"20",X"3a",X"20"),
                                              (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"31",X"32",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
                                              (X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));

--Constant that holds "Thank you"
constant digilent_screen : OledMem:= ((X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),	
												(X"2e",X"2e",X"2e",X"54",X"48",X"41",X"4e",X"4b",X"20",X"59",X"4f",X"55",X"2e",X"2e",X"2e",X"2e"),
												(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"),
												(X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20",X"20"));
--Current overall state of the state machine
signal current_state : states := Idle;
--State to go to after the SPI transmission is finished
signal after_state : states;
signal countled : integer := 0;
--State to go to after the set page sequence
signal after_page_state : states;
--State to go to after sending the character sequence
signal after_char_state : states;
--State to go to after the UpdateScreen is finished
signal after_update_state : states;

--Contains the value to be outputted to DC
signal temp_dc : STD_LOGIC := '0';
signal score : integer := 0;

--Variables used in the Delay Controller Block
signal temp_delay_ms : STD_LOGIC_VECTOR (11 downto 0); --amount of ms to delay
signal temp_delay_en : STD_LOGIC := '0'; --Enable signal for the delay block
signal temp_delay_fin : STD_LOGIC; --Finish signal for the delay block

--Variables used in the SPI controller block
signal temp_spi_en : STD_LOGIC := '0'; --Enable signal for the SPI block
signal temp_spi_data : STD_LOGIC_VECTOR (7 downto 0) := (others => '0'); --Data to be sent out on SPI
signal temp_spi_fin : STD_LOGIC; --Finish signal for the SPI block

signal temp_char : STD_LOGIC_VECTOR (7 downto 0) := (others => '0'); --Contains ASCII value for character
signal temp_addr : STD_LOGIC_VECTOR (10 downto 0) := (others => '0'); --Contains address to BYTE needed in memory
signal temp_dout : STD_LOGIC_VECTOR (7 downto 0); --Contains byte outputted from memory
signal temp_page : STD_LOGIC_VECTOR (1 downto 0) := (others => '0'); --Current page
signal temp_index : integer range 0 to 15 := 0; --Current character on page
signal en1 : std_logic := '0';
begin
DC <= temp_dc;
--led<="1111111111111111";
--Example finish flag only high when in done state
FIN <= '1' when (current_state = Done) else
					'0';
--Instantiate SPI Block
 SPI_COMP: SpiCtrl PORT MAP (
          CLK => CLK,
          RST => RST,
          SPI_EN => temp_spi_en,
          SPI_DATA => temp_spi_data,
          CS => CS,
          SDO => SDO,
          SCLK => SCLK,
          SPI_FIN => temp_spi_fin
        );
--Instantiate Delay Block
   DELAY_COMP: Delay PORT MAP (
          CLK => CLK,
          RST => RST,
          DELAY_MS => temp_delay_ms,
          DELAY_EN => temp_delay_en,
          DELAY_FIN => temp_delay_fin
        );
        
        Segment : sevensegment Port Map
        (
            clk => clk,
            an0 => an0,
            an1 => an1,
            an2 => an2,
            an3 => an3,
            seg => seg,
            print => score,
            en1 => en1
        );
        
--Instantiate Memory Block
	CHAR_LIB_COMP : Charlib
  PORT MAP (
    clka => CLK,
    addra => temp_addr,
    douta => temp_dout
  );
	process (CLK)
	begin
		if(rising_edge(CLK)) then
		
			case(current_state) is
				--Idle until EN pulled high than intialize Page to 0 and go to state Alphabet afterwards
				when Idle => 
				en1 <= '0';
				score <= 0;
					if(EN = '1') then
						current_state <= ClearDC;

						after_page_state <= Alphabet;
						temp_page <= "00";
					end if;

                            when Alphabet =>
                            led <= "1000000000000000" ;
                            en1 <= '0';
                            current_screen <= alphabet_screen;
                            current_state <= UpdateScreen;
                            after_update_state <= Wait1;
                        --Wait 4ms and go to ClearScreen
                        when Wait1 =>      
                            temp_delay_ms <= "111110100000"; --4000
                            after_state <= ClearScreen;
                            current_state <= Transition3; --Transition3 = The delay transition states
                        when ClearScreen => 
                            current_screen <= clear_screen;
                            after_update_state <= Wait2;
                            current_state <= UpdateScreen;
                        when Wait2 =>
                            temp_delay_ms <= "001111101000"; --1000se kam                            
                            after_state <= welcome;
                            current_state <= Transition3; --Transition3 = The delay transition states
                        
                       -- ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
                       
                        when welcome => 
                                                en1 <= '1';
                                                 led <= "1100000000000000" ;
                                                                        current_screen <= welcome_screen;
                                                                        current_state <= UpdateScreen;
                                                                        after_update_state <= Wait0;
                                                                    when Wait0 => 
                                                                      
                                                                      if(low = '1') then 
                                                                        temp_delay_ms <= "111110100000"; --4000
                                                                        elsif(medium = '1') then
                                                                        temp_delay_ms <= "011111010000"; -- 2000
                                                                        
                                                                        else
                                                                        temp_delay_ms <= "001111101000"; -- 1000
                                                                        end if;
                                                                        
                                                                        
                                                                        if (low= '1' or medium = '1' or high = '1') then 
                                                                        after_state <= ClearScreen0;
                                                                        
                                                                        current_state <= Transition3;
                                                                        end if;
                                                                         --Transition3 = The delay transition states
                                                                   
                                                                    when ClearScreen0 => 
                                                                    
                                                                        current_screen <= clear_screen;
                                                                        after_update_state <= Wait00;
                                                                        current_state <= UpdateScreen;
                                                                   
                                                                    when Wait00 =>
                                                                        temp_delay_ms <= "000111110100"; --1000
                                            --              
                                                                        
                                                                        after_state <= Page1;
                                                                        current_state <= Transition3;
                       
                       ---------------------------------------------------------------------------------------------------------------------------------------- 
                          when Page1 => 
                          en1 <= '1';
                           led <= "1110000000000000" ;
                                                  current_screen <= Page1_screen;
                                                  current_state <= UpdateScreen;
                                                  after_update_state <= Wait11;
                                              
                                              when Wait11 => 
                                                if(low = '1') then 
                                                  temp_delay_ms <= "111110100000"; --4000
                                                  elsif(medium = '1') then
                                                  temp_delay_ms <= "011111010000"; -- 2000
                                                  
                                                  else
                                                  temp_delay_ms <= "001111101000"; -- 1000
                                                  end if;
                                                  
                                                  after_state <= ClearScreen1;
                                                  current_state <= Transition3; --Transition3 = The delay transition states
                                              
                                              when ClearScreen1 => 
                                              if(PB3 = '1') then score <= score +1; end if; 
                                                  current_screen <= clear_screen;
                                                  after_update_state <= Wait21;
                                                  current_state <= UpdateScreen;
                                              
                                              when Wait21 =>
                                                  temp_delay_ms <= "000111110100"; --1000
                      --                           
                                                  
                                                  after_state <= Page2;
                                                  current_state <= Transition3;
                        
			--	,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
				
				 when Page2 => 
				  led <= "1111000000000000" ;
				 
                                                                 current_screen <= Page2_screen;
                                                                 current_state <= UpdateScreen;
                                                                 after_update_state <= Wait12;
                                                     
                                                             when Wait12  => 
                                                                 if(low = '1') then 
                                                                  temp_delay_ms <= "111110100000"; --4000
                                                                  
                                                                  
                                                                  elsif(medium = '1') then
                                                                  temp_delay_ms <= "011111010000"; -- 2000
                                                                  
                                                                  
                                                                  else 
                                                                  temp_delay_ms <= "001111101000"; -- 1000
                                                                  
                                                                  
                                                                  end if;
                                                          
                                                                 after_state <= ClearScreen2;
                                                                 current_state <= Transition3; --Transition3 = The delay transition states
                                                     
                                                             when ClearScreen2 => 
                                                                     if(PB4 = '1') then score <= score +1; end if;
                                                                 current_screen <= clear_screen;
                                                                 after_update_state <= Wait22;
                                                                 current_state <= UpdateScreen;
                                                           
                                                             when Wait22 =>
                                                                 temp_delay_ms <= "000111110100"; --1000
                                     --                          
                                                                 
                                                                 after_state <= Page3;
                                                                 current_state <= Transition3;
                                       
			--	,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
				
				 when Page3 => 
				  led <= "1111100000000000" ;
                                                                                current_screen <= Page3_screen;
                                                                                current_state <= UpdateScreen;
                                                                                after_update_state <= Wait13;
                                                                            
                                                                            when Wait13 => 
                                                                                if(low = '1') then 
                                                                                temp_delay_ms <= "111110100000"; --4000
                                                                                elsif(medium = '1') then
                                                                                  temp_delay_ms <= "011111010000"; -- 2000
                                                                                      else
                                                                             temp_delay_ms <= "001111101000"; -- 1000
                                                                              end if;
                                                                             
                                                                                after_state <= ClearScreen3;
                                                                                current_state <= Transition3; --Transition3 = The delay transition states
                                                                            
                                                                            when ClearScreen3 => 
                                                                             if(PB2 = '1') then score <= score +1; end if;
                                                                                current_screen <= clear_screen;
                                                                                after_update_state <= Wait23;
                                                                                current_state <= UpdateScreen;

                                                                            when Wait23 =>
                                                   temp_delay_ms <= "000111110100"; --1000

                                  
    after_state <= Page4;
    current_state <= Transition3;
                                                                                
         -- ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
                       
                       
                           when Page4 => 
                           led <= "1111110000000000" ;
                                                                                          current_screen <= Page4_screen;
                                                                                          current_state <= UpdateScreen;
                                                                                          after_update_state <= Wait14;
                                                                                      --Wait 4ms and go to ClearScreen
                                                                                      when Wait14 => 
                                                                                          if(low = '1') then 
                                                                                      temp_delay_ms <= "111110100000"; --4000
                                                                                        elsif(medium = '1') then
                                                                                       temp_delay_ms <= "011111010000"; -- 2000
                                                                                       else
                                                                                        temp_delay_ms <= "001111101000"; -- 1000
                                                                                        end if;
                                                                                      
                                                                                          after_state <= ClearScreen4;
                                                                                          current_state <= Transition3; --Transition3 = The delay transition states
                                                                                     
                                                                                      when ClearScreen4 => 
                                                                                        if(PB4 = '1') then score <= score +1; end if;
                                                                                          current_screen <= clear_screen;
                                                                                          after_update_state <= Wait24;
                                                                                          current_state <= UpdateScreen;
                      
                                                                                      when Wait24 =>
                                                                                          temp_delay_ms <= "000111110100"; --1000
                                                            
                                                                                          
                                                                                          after_state <= Page5;
                                                                                          current_state <= Transition3;
                        --          ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
                                  
                                  
				  when Page5 => 
				        led <= "1111111000000000" ;
                       current_screen <= Page5_screen;
                       current_state <= UpdateScreen;
                       after_update_state <= Wait15;
                                                                                                                      
                when Wait15 => 
                       if(low = '1') then 
                       temp_delay_ms <= "111110100000"; --4000
                       elsif(medium = '1') then
                       temp_delay_ms <= "011111010000"; -- 2000
                      else
                      temp_delay_ms <= "001111101000"; -- 1000
                      end if;--4000

                      after_state <= ClearScreen5;
                      current_state <= Transition3; --Transition3 = The delay transition states

                       when ClearScreen5 => 
                                             if(PB1 = '1') then score <= score +1; end if;
                       current_screen <= clear_screen;
                         after_update_state <= Wait25;
                         current_state <= UpdateScreen;
                         
                         when Wait25 =>
                        temp_delay_ms <= "000111110100"; --1000
                                                                                              --                            after_state <= next11;
                                                                                                                          
                        after_state <= Page6;
                        current_state <= Transition3;
                                                                                                                          
 when Page6 => 
  led <= "1111111100000000" ;
current_screen <= Page6_screen;
current_state <= UpdateScreen;
after_update_state <= Wait16;
                                                                                                                                                                                                                                               --Wait 4ms and go to ClearScreen
when Wait16 => 
if(low = '1') then 
 temp_delay_ms <= "111110100000"; --4000
  elsif(medium = '1') then
 temp_delay_ms <= "011111010000"; -- 2000
else
temp_delay_ms <= "001111101000"; -- 1000
end if; --4000

after_state <= ClearScreen6;
   current_state <= Transition3; --Transition3 = The delay transition states
                                                                                                                                                                                                                                               --set current_screen to constant clear_screen and update the screen. Go to state Wait2 afterwards
 when ClearScreen6 => 
 if(PB2 = '1') then score <= score +1; end if;
current_screen <= clear_screen;
after_update_state <= Wait26;
current_state <= UpdateScreen;
                                                                                                                                                                                                                                               --Wait 1ms and go to DigilentScreen
 when Wait26 =>
temp_delay_ms <= "000111110100"; --1000
                                                                                                                                                                                                                       --                            after_state <= next11;
                                                                                                                                                                                                                                                   
after_state <= Page7;
current_state <= Transition3;  
         -------------------------------------------------------------------------------------------------                                                                                                                                                                                                                                          
 when Page7 => 
   led <= "1111111110000000" ;
current_screen <= Page7_screen;
current_state <= UpdateScreen;
after_update_state <= Wait17;
                                                                                                                                                                                                                                                                                                                                                       --Wait 4ms and go to ClearScreen
when Wait17 => 
if(low = '1') then 
     temp_delay_ms <= "111110100000"; --4000
      elsif(medium = '1') then
     temp_delay_ms <= "011111010000"; -- 2000
       else
      temp_delay_ms <= "001111101000"; -- 1000
        end if;--4000

after_state <= ClearScreen7;
current_state <= Transition3; --Transition3 = The delay transition states
                                                                                                                                                                                                                                                                                                                                                       --set current_screen to constant clear_screen and update the screen. Go to state Wait2 afterwards
when ClearScreen7 => 
        if(PB3 = '1') then score <= score +1; end if;
current_screen <= clear_screen;
after_update_state <= Wait27;
current_state <= UpdateScreen;
                                                                                                                                                                                                                                                                                                                                                       --Wait 1ms and go to DigilentScreen
when Wait27 =>
temp_delay_ms <= "000111110100"; --1000                                                                                                                                                                                                                                                                                                                           
after_state <= Page8;
current_state <= Transition3;
 ---------------------------------------------------------------------------
  when Page8 => 
   led <= "1111111111000000" ;
current_screen <= Page8_screen;
current_state <= UpdateScreen;
after_update_state <= Wait18;
                                                                                                                                                                                                                                                                                                                                                       --Wait 4ms and go to ClearScreen
when Wait18 => 
if(low = '1') then 
     temp_delay_ms <= "111110100000"; --4000
      elsif(medium = '1') then
     temp_delay_ms <= "011111010000"; -- 2000
       else
      temp_delay_ms <= "001111101000"; -- 1000
        end if;--4000

after_state <= ClearScreen8;
current_state <= Transition3; --Transition3 = The delay transition states
                                                                                                                                                                                                                                                                                                                                                       --set current_screen to constant clear_screen and update the screen. Go to state Wait2 afterwards
when ClearScreen8 => 
        if(PB3 = '1') then score <= score +1; end if;
current_screen <= clear_screen;
after_update_state <= Wait28;
current_state <= UpdateScreen;
                                                                                                                                                                                                                                                                                                                                                       --Wait 1ms and go to DigilentScreen
when Wait28 =>
temp_delay_ms <= "000111110100"; --1000
                                                                                                                                                                                                                                                                                                                               --                            after_state <= next11;
                                                                                                                                                                                                                                                                                                                                                           
after_state <= Page9;
current_state <= Transition3;
 -----------------------------------------------------------------
when Page9 => 
 led <= "1111111111100000" ;
current_screen <= Page9_screen;
current_state <= UpdateScreen;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
         after_update_state <= Wait19;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            --Wait 4ms and go to ClearScreen
when Wait19 => 
if(low = '1') then 
     temp_delay_ms <= "111110100000"; --4000
      elsif(medium = '1') then
     temp_delay_ms <= "011111010000"; -- 2000
       else
      temp_delay_ms <= "001111101000"; -- 1000
        end if;--4000

after_state <= ClearScreen9;
current_state <= Transition3; --Transition3 = The delay transition states
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    --set current_screen to constant clear_screen and update the screen. Go to state Wait2 afterwards
when ClearScreen9 => 
        if(PB1 = '1') then score <= score +1; end if;
current_screen <= clear_screen;
after_update_state <= Wait29;
current_state <= UpdateScreen;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    --Wait 1ms and go to DigilentScreen
when Wait29 =>
temp_delay_ms <= "000111110100"; --1000                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
after_state <= Page10;
current_state <= Transition3;  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
  ----------------------------------------------------------------------------------------------
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
when Page10 => 
 led <= "1111111111110000" ;
current_screen <= Page10_screen;
current_state <= UpdateScreen;
after_update_state <= Wait110;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          --Wait 4ms and go to ClearScreen
when Wait110 => 
if(low = '1') then 
     temp_delay_ms <= "111110100000"; --4000
      elsif(medium = '1') then
     temp_delay_ms <= "011111010000"; -- 2000
       else
      temp_delay_ms <= "001111101000"; -- 1000
        end if;--4000

after_state <= ClearScreen10;
current_state <= Transition3; --Transition3 = The delay transition states
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          --set current_screen to constant clear_screen and update the screen. Go to state Wait2 afterwards
when ClearScreen10 => 
        if(PB4 = '1') then score <= score +1; end if;
current_screen <= clear_screen;
     after_update_state <= Wait210;
     current_state <= UpdateScreen;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          --Wait 1ms and go to DigilentScreen
 when Wait210 =>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
           temp_delay_ms <= "000111110100"; --1000
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
            after_state <= Page11;
           current_state <= Transition3;
                                     
    ---------------------------------------------------------------------------------------------   
    when Page11 => 
     led <= "1111111111111000" ;
    current_screen <= Page11_screen;
    current_state <= UpdateScreen;
    after_update_state <= Wait111;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              --Wait 4ms and go to ClearScreen
    when Wait111 => 
    if(low = '1') then 
         temp_delay_ms <= "111110100000"; --4000
          elsif(medium = '1') then
         temp_delay_ms <= "011111010000"; -- 2000
           else
          temp_delay_ms <= "001111101000"; -- 1000
            end if;--4000
    
    after_state <= ClearScreen11;
    current_state <= Transition3; --Transition3 = The delay transition states
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              --set current_screen to constant clear_screen and update the screen. Go to state Wait2 afterwards
    when ClearScreen11 => 
            if(PB2 = '1') then score <= score +1; end if;
    current_screen <= clear_screen;
         after_update_state <= Wait211;
         current_state <= UpdateScreen;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              --Wait 1ms and go to DigilentScreen
     when Wait211 =>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
               temp_delay_ms <= "000111110100"; --1000
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
                after_state <= Page12;
               current_state <= Transition3;
                                                                                                                                                                                                    
	---------------------------------------------------------------------------------------------
	
	 when Page12 => 
        led <= "1111111111111100" ;
       current_screen <= Page12_screen;
       current_state <= UpdateScreen;
       after_update_state <= Wait112;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 --Wait 4ms and go to ClearScreen
       when Wait112 => 
       if(low = '1') then 
            temp_delay_ms <= "111110100000"; --4000
             elsif(medium = '1') then
            temp_delay_ms <= "011111010000"; -- 2000
              else
             temp_delay_ms <= "001111101000"; -- 1000
               end if;--4000
       
       after_state <= ClearScreen12;
       current_state <= Transition3; --Transition3 = The delay transition states
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 --set current_screen to constant clear_screen and update the screen. Go to state Wait2 afterwards
       when ClearScreen12 => 
               if(PB4 = '1') then score <= score +1; end if;
       current_screen <= clear_screen;
            after_update_state <= Wait212;
            current_state <= UpdateScreen;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 --Wait 1ms and go to DigilentScreen
        when Wait212 =>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
                  temp_delay_ms <= "000111110100"; --1000
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
                   after_state <= scorecard;
                  current_state <= Transition3;
	---------------------------------------------------------------------------------------------
	when scorecard => 
	 led <= "1111111111111110" ;
	if (score = 0) then 
    current_screen <= scorecard_screen0;
    
    	elsif (score = 1) then 
    current_screen <= scorecard_screen1;
    
    	elsif (score = 2) then 
    current_screen <= scorecard_screen2;
    
    	elsif (score = 3) then 
    current_screen <= scorecard_screen3;
    
    	elsif (score = 4) then 
    current_screen <= scorecard_screen4;
    
    	elsif (score = 5) then 
    current_screen <= scorecard_screen5;
    
    	elsif (score = 6) then 
    current_screen <= scorecard_screen6;
    
    	elsif (score = 7) then 
    current_screen <= scorecard_screen7;
    
    	elsif (score = 8) then 
    current_screen <= scorecard_screen8;
    
    	elsif (score = 9) then 
    current_screen <= scorecard_screen9;
    
    	elsif (score = 10) then 
    current_screen <= scorecard_screen10;
    
    	elsif (score = 11) then 
    current_screen <= scorecard_screen11;
    
    	elsif (score = 12) then 
    current_screen <= scorecard_screen12;
    
    end if;
    current_state <= UpdateScreen;
    after_update_state <= Wait113;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              --Wait 4ms and go to ClearScreen
    when Wait113 => 
    temp_delay_ms <= "111110100000"; --40000
        
    after_state <= ClearScreen13;
    current_state <= Transition3; --Transition3 = The delay transition states
--                                end if;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              --set current_screen to constant clear_screen and update the screen. Go to state Wait2 afterwards
    when ClearScreen13 => 
    current_screen <= clear_screen;
         after_update_state <= Wait213;
         current_state <= UpdateScreen;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              --Wait 1ms and go to DigilentScreen
     when Wait213 =>                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
               temp_delay_ms <= "000111110100"; --1000
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
                after_state <= DigilentScreen;
               current_state <= Transition3;
                        	  
	---------------------------------------------------------------------------------------------
				when DigilentScreen =>
					 led <= "1111111111111111" ;
					current_screen <= digilent_screen;
					after_update_state <= Done;
					current_state <= UpdateScreen;
				--Do nothing until EN is deassertted and then current_state is Idle
				when Done			=>
					if(EN = '0') then
						current_state <= Idle;
					end if;
					
				--UpdateScreen State
				--1. Gets ASCII value from current_screen at the current page and the current spot of the page
				--2. If on the last character of the page transition update the page number, if on the last page(3)
				--			then the updateScreen go to "after_update_state" after 
				when UpdateScreen =>
					temp_char <= current_screen(CONV_INTEGER(temp_page),temp_index);
					if(temp_index = 15) then	
						temp_index <= 0;
						temp_page <= temp_page + 1;
						after_char_state <= ClearDC;
						if(temp_page = "11") then
							after_page_state <= after_update_state;
						else	
							after_page_state <= UpdateScreen;
						end if;
					else
						temp_index <= temp_index + 1;
						after_char_state <= UpdateScreen;
					end if;
					current_state <= SendChar1;
				
				--Update Page states
				--1. Sets DC to command mode
				--2. Sends the SetPage Command
				--3. Sends the Page to be set to
				--4. Sets the start pixel to the left column
				--5. Sets DC to data mode
				when ClearDC =>
					temp_dc <= '0';
					current_state <= SetPage;
				when SetPage =>
					temp_spi_data <= "00100010";
					after_state <= PageNum;
					current_state <= Transition1;
				when PageNum =>
					temp_spi_data <= "000000" & temp_page;
					after_state <= LeftColumn1;
					current_state <= Transition1;
				when LeftColumn1 =>
					temp_spi_data <= "00000000";
					after_state <= LeftColumn2;
					current_state <= Transition1;
				when LeftColumn2 =>
					temp_spi_data <= "00010000";
					after_state <= SetDC;
					current_state <= Transition1;
				when SetDC =>
					temp_dc <= '1';
					current_state <= after_page_state;
				--End Update Page States

				--Send Character States
				--1. Sets the Address to ASCII value of char with the counter appended to the end
				--2. Waits a clock for the data to get ready by going to ReadMem and ReadMem2 states
				--3. Send the byte of data given by the block Ram
				--4. Repeat 7 more times for the rest of the character bytes
				when SendChar1 =>
					temp_addr <= temp_char & "000";
					after_state <= SendChar2;
					current_state <= ReadMem;
				when SendChar2 =>
					temp_addr <= temp_char & "001";
					after_state <= SendChar3;
					current_state <= ReadMem;
				when SendChar3 =>
					temp_addr <= temp_char & "010";
					after_state <= SendChar4;
					current_state <= ReadMem;
				when SendChar4 =>
					temp_addr <= temp_char & "011";
					after_state <= SendChar5;
					current_state <= ReadMem;
				when SendChar5 =>
					temp_addr <= temp_char & "100";
					after_state <= SendChar6;
					current_state <= ReadMem;
				when SendChar6 =>
					temp_addr <= temp_char & "101";
					after_state <= SendChar7;
					current_state <= ReadMem;
				when SendChar7 =>
					temp_addr <= temp_char & "110";
					after_state <= SendChar8;
					current_state <= ReadMem;
				when SendChar8 =>
					temp_addr <= temp_char & "111";
					after_state <= after_char_state;
					current_state <= ReadMem;
				when ReadMem =>
					current_state <= ReadMem2;
				when ReadMem2 =>
					temp_spi_data <= temp_dout;
					current_state <= Transition1;
				--End Send Character States
					
				--SPI transitions
				--1. Set SPI_EN to 1
				--2. Waits for SpiCtrl to finish
				--3. Goes to clear state (Transition5)
				when Transition1 =>
					temp_spi_en <= '1';
					current_state <= Transition2;
				when Transition2 =>
					if(temp_spi_fin = '1') then
						current_state <= Transition5;
					end if;
					
				--Delay Transitions
				--1. Set DELAY_EN to 1
				--2. Waits for Delay to finish
				--3. Goes to Clear state (Transition5)
				when Transition3 =>
					temp_delay_en <= '1';
					current_state <= Transition4;
				when Transition4 =>
					if(temp_delay_fin = '1') then
						current_state <= Transition5;
					end if;
				
				--Clear transition
				--1. Sets both DELAY_EN and SPI_EN to 0
				--2. Go to after state
				when Transition5 =>
					temp_spi_en <= '0';
					temp_delay_en <= '0';
					current_state <= after_state;
				--END SPI transitions
				--END Delay Transitions
				--END Clear transition
			
				when others 		=>
					current_state <= Idle;
			end case;
		end if;
	end process;
	
end Behavioral;
