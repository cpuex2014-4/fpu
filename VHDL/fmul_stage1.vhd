library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity FMUL_STAGE1 is
  Port (input1   : in  std_logic_vector (31 downto 0);
        input2   : in  std_logic_vector (31 downto 0);
        hh   : out  std_logic_vector (35 downto 0);
        hl1  : out  std_logic_vector (35 downto 0);
        hl2  : out  std_logic_vector (35 downto 0);
        sumExp : out std_logic_vector (31 downto 0));
end entity FMUL_STAGE1;


architecture RTL of FMUL_STAGE1 is
  subtype int32 is std_logic_vector(31 downto 0);
  signal aHigh, aLow : std_logic_vector (17 downto 0);
  signal bHigh, bLow : std_logic_vector (17 downto 0);
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
