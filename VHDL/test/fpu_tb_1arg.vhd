library IEEE;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use ieee.std_logic_textio.all;
use std.textio.all;
library work;
use work.kakeudon_fpu.all;

entity top is
  Port ( MCLK1 : in  STD_LOGIC;
         RS_TX : out  STD_LOGIC);
end top;

architecture Behavior of top is
  signal a:int32 := (others=>'0');
  signal b:int32 := (others=>'0');
  signal ans:int32 := (others=>'0');
  signal clk:std_logic := '0';
  file  read_file  : text open read_mode  is "test1.in";

  -- Please change file name
  file  write_file : text open write_mode is "test_finv.out";
begin

  -- Please change port map
  fpu_test: FINV port map (input=>a,clk=>clk,output=>ans);

  readProc:process(clk)
    variable lin : line;
    variable ra : int32;
    variable rb : int32;
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

  clockgen: process
  begin
    clk<='0';
    wait for 5 ns;
    clk<='1';
    wait for 5 ns;
  end process;

end Behavior;
