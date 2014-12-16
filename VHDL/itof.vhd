library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.kakeudon_fpu.all;

entity ITOF is
  Port (input  : in  unsigned(31 downto 0);
        clk : in std_logic;
        output : out unsigned(31 downto 0));
end entity ITOF;

architecture RTL of ITOF is
  signal t: unsigned32;
  signal low0, high0, low, high, a, b, a1, b1, ans: unsigned32;
  signal sign1 : std_logic;
  signal sign2 : std_logic;
  signal sign3 : std_logic;
begin
  lowsub:  FADD port map (input1=> low,  input2=> x"cb000000", clk => clk, output=>a1);
  highsub: FADD port map (input1=> high, input2=> x"d6800000", clk => clk, output=>b1);
  lhadd:   FADD port map (input1=> a,    input2=> b, clk => clk, output=>ans);

  t <= input when input(31) = '0' else
       (not input) + 1;

  low0  <= "000000000" & t(22 downto 0);
  high0 <= x"000000" & t(30 downto 23);

  low  <= low0 + x"4b000000";
  high <= high0 + x"56800000";


  output <= sign3&ans(30 downto 0);

  itof_proc: process(input, clk)
    variable s1,s2: std_logic;
  begin
    if rising_edge(clk) then
      s1 := sign1;
      s2 := sign2;

      sign3 <= s2;
      sign2 <= s1;
      sign1 <= input(31);

      a <= a1;
      b <= b1;

    end if;
  end process;

end architecture RTL;
