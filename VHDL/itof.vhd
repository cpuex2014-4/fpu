library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity ITOF is
  Port (input  : in  std_logic_vector(31 downto 0);
        output : out std_logic_vector(31 downto 0));
end entity ITOF;

architecture RTL of ITOF is
  subtype int32 is std_logic_vector(31 downto 0);
  component FADD is
    port (
      input1 : in int32;
      input2 : in int32;
      output : out int32);
  end component;
  signal t: int32;
  signal low0, high0, low, high, a, b, ans: int32;
begin
  lowsub:  FADD port map (input1=> low,  input2=> x"cb000000", output=>a);
  highsub: FADD port map (input1=> high, input2=> x"d6800000", output=>b);
  lhadd:   FADD port map (input1=> a,    input2=> b, output=>ans);

  t <= input when input(31) = '0' else
       (not input) + 1;

  low0  <= "000000000" & t(22 downto 0);
  high0 <= x"000000" & t(30 downto 23);

  low  <= low0 + x"4b000000";
  high <= high0 + x"56800000";

  output <= input(31)&ans(30 downto 0);

end architecture RTL;
