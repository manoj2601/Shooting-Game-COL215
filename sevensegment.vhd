


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std;
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.std_logic_signed.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sevensegment is
  Port (
  clk : IN std_logic;
  print : in integer;
  en1 : in std_logic;
  an0 : OUT std_logic;
  an1 : OUT std_logic;
  an2 : OUT std_logic;
  an3 : OUT std_logic;
  seg : OUT std_logic_vector(6 downto 0)
   );
end sevensegment;

architecture Behavioral of sevensegment is

TYPE state_type is (s0, s1, s2, s3);

signal state : state_type := s0;
signal temp : integer := 0;
signal clk1 : std_logic;
signal arr : std_logic_vector(2 downto 0);
signal default1 :std_logic_vector(6 downto 0) := "0000111";
signal default2 : std_logic_vector(6 downto 0) := "0100011";
signal default3 : std_logic_vector(6 downto 0) := "0001011";
signal default4 : std_logic_vector(6 downto 0) := "0010010";
signal A : std_logic_vector(6 downto 0);
signal B : std_logic_vector(6 downto 0);
signal C : std_logic_vector(6 downto 0);
signal D : std_logic_vector(6 downto 0);
begin

process(clk)
    begin
        if(clk'event and clk = '1') then
        temp <= temp+1;
        if(temp = 5208) then
            clk1 <= not clk1;
            temp <= 0;
        end if;
      end if;
    end process;                                             

process(clk1, state, print, en1)
    begin
    
    
    if(clk1'event and clk1 = '1') then
    
    if(en1 = '0') then
        A <= default1;
        B<= default2;
        C <= default3;
        D <= default4;
        else
            C<= "1111111";
            D <= "1111111";
            if(print = 10) then B <= "1001111";
            else B <= "1111111";
            end if;
            if(print = 0) then A<= "1000000";
            elsif(print = 1) then A<="1111001";
            elsif(print = 2) then A<="0100100";
            elsif(print = 3) then A<="0110000";
            elsif(print = 4) then A<="0011001";
            elsif(print = 5) then A<="0010010";
            elsif(print = 6) then A<="0000010";
            elsif(print = 7) then A<="1111000";
            elsif(print = 8) then A<="0000000";
            elsif(print = 9) then A<="0010000";
            elsif(print = 10) then A<="1000000";
            elsif(print = 11) then A<="1111001";
            elsif(print = 12) then A<="0100100";
            end if;
    end if;
        case state is
            when s0 =>
                an0 <= '0';
                an1 <= '1';
                an2 <= '1';
                an3 <= '1';
                seg <= A;
                state<= s1;
           when s1 => 
                an0 <= '1';
                an1 <= '0';
                an2 <= '1';
                an3 <= '1';
                seg <= B;
                state<= s2;
           when s2 => 
                an0 <= '1';
                an1 <= '1';
                an2 <= '0';
                an3 <= '1';
                seg <= C;
                state<= s3;
        when s3 => 
                                an0 <= '1';
                                an1 <= '1';
                                an2 <= '1';
                                an3 <= '0';
                                seg <= D;
                           state<= s0;     
            end case;
            end if;
            end process;
end Behavioral;

