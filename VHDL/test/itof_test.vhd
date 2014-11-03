library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity top is
  Port ( MCLK1 : in  STD_LOGIC;
         RS_TX : out  STD_LOGIC);
end top;

architecture Behavior of top is
  subtype unsigned_word is unsigned(31 downto 0);
  subtype int32 is std_logic_vector(31 downto 0);
  component ITOF is
  Port (
    input : in  int32;
    clk : in std_logic;
    output : out int32);
  end component;

  signal a:int32 := (others=>'0');
  signal ans:int32 := (others=>'0');
  signal clk:std_logic := '0';
  file  read_file  : text open read_mode  is "i2f.in";
  file  write_file : text open write_mode is "i2f.out";
begin
  hoge: ITOF port map (input=>a, clk=>clk, output=>ans);

  readProc:process(clk)
    variable lin : line;
    variable ra : int32;
    variable wans : int32;
    variable lout : line;
  begin
    if rising_edge(clk) then
      readline(read_file, lin);
      hread(lin, ra);
      a <= ra;
    end if;
    if falling_edge(clk) then
      hwrite(lout, ans);
      writeline(write_file, lout);
    end if;
  end process;
  clkgen: process
  begin
    clk<='0';
    wait for 5 ns;
    clk<='1';
    wait for 5 ns;
  end process;
end Behavior;