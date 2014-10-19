library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity FLT is
  Port (input1 : in  std_logic_vector(31 downto 0);
        input2 : in  std_logic_vector(31 downto 0);
        output : out std_logic);
end entity FLT;

architecture RTL of FLT is
  subtype int32 is std_logic_vector(31 downto 0);
  signal a, b : int32;
  signal isNaN : std_logic;
begin

  a <= x"00000000" when input1(30 downto 23) = x"00" else
       input1;
  b <= x"00000000" when input2(30 downto 23) = x"00" else
       input2;

  isNaN  <= '1' when (a(30 downto 23) = x"ff" and a(22 downto 0) /= x"00") or
                     (b(30 downto 23) = x"ff" and b(22 downto 0) /= x"00") else
            '0';

  output <= '1' when isNaN = '0' and (to_integer(signed(a)) < to_integer(signed(b))) else
            '0';

end architecture RTL;
