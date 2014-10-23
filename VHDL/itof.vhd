library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity ITOF is
  Port (input  : in  std_logic_vector(31 downto 0);
        clk : in std_logic;
        output : out std_logic_vector(31 downto 0));
end entity ITOF;

architecture RTL of ITOF is
  subtype int32 is std_logic_vector(31 downto 0);
  component FADD is
    port (
      input1 : in int32;
      input2 : in int32;
      clk: std_logic;
      output : out int32);
  end component;
  signal t: int32;
  signal low0, high0, low, high, a, b, a1, b1, ans: int32;
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



  itof_proc: process(input, clk)
    variable sign1 : std_logic;
    variable sign2 : std_logic;
    variable sign3 : std_logic;
    variable sign4 : std_logic;
    variable sign5 : std_logic;
  begin
    if rising_edge(clk) then

      output <= sign5&ans(30 downto 0);

      sign5 := sign4;
      sign4 := sign3;
      sign3 := sign2;
      sign2 := sign1;
      sign1 := input(31);

      a <= a1;
      b <= b1;

    end if;
  end process;

end architecture RTL;
