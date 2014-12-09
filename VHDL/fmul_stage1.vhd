library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.kakeudon_fpu.all;
entity FMUL_STAGE1 is
  Port (input1   : in  unsigned (31 downto 0);
        input2   : in  unsigned (31 downto 0);
        hh   : out  unsigned (35 downto 0);
        hl1  : out  unsigned (35 downto 0);
        hl2  : out  unsigned (35 downto 0);
        sumExp : out unsigned (31 downto 0));
end entity FMUL_STAGE1;


architecture RTL of FMUL_STAGE1 is
  subtype int32 is unsigned(31 downto 0);
  signal a, b: int32;
  signal aHigh, aLow : unsigned (17 downto 0);
  signal bHigh, bLow : unsigned (17 downto 0);
  signal aExp, bExp: int32;
begin
  a <= input1;
  b <= input2;
  aLow  <= "0000000"&a(10 downto 0);
  aHigh <= "000001" &a(22 downto 11);

  bLow  <= "0000000"&b(10 downto 0);
  bHigh <= "000001" &b(22 downto 11);

  hh  <= aHigh * bHigh;
  hl1 <= aHigh * bLow;
  hl2 <= aLow  * bHigh;

  aExp <= x"000000"&a(30 downto 23);
  bExp <= x"000000"&b(30 downto 23);
  sumExp <= aExp + bExp;
end architecture RTL;
