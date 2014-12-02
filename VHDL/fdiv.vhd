library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_arith.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.kakeudon_fpu.all;

entity FDIV is
  Port (input1 : in  std_logic_vector(31 downto 0);
        input2  : in  std_logic_vector(31 downto 0);
        clk : in std_logic;
        output : out std_logic_vector(31 downto 0));
end entity FDIV;

architecture RTL of FDIV is
  subtype int32 is std_logic_vector(31 downto 0);
  signal a, b: int32 := (others => '0');
  signal a1, a2, a3, a4, a5: int32 := (others => '0');
  signal inv_in, inv_out, ans: int32;
begin
  inv: FINV port map (
    input => b, clk => clk, output => inv_out
  );
  mul: FMUL port map (
    input1 => a5, input2 => inv_in, clk => clk, output => ans
  );
  a <= input1(31)&(30 downto 0 => '0') when input1(30 downto 23) = x"00" else
       input1;
  b <= input2(31)&(30 downto 0 => '0') when input2(30 downto 23) = x"00" else
       input2;
  output <= ans;

  fdiv_proc: process(input1, input2, clk)
  begin
    if rising_edge(clk) then
      a5 <= a4;
      a4 <= a3;
      a3 <= a2;
      a2 <= a1;
      a1 <= a;
      inv_in <= inv_out;
    end if;
  end process;
end architecture RTL;
