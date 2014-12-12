library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;
library work;
use work.kakeudon_fpu.all;

entity fpu_tb_2args is
  Port ( MCLK1 : in  STD_LOGIC;
         RS_TX : out  STD_LOGIC);
end fpu_tb_2args;

architecture Behavior of fpu_tb_2args is
  subtype int32 is std_logic_vector(31 downto 0);
  signal a:unsigned_word := (others=>'0');
  signal b:unsigned_word := (others=>'0');
  signal ans:unsigned_word := (others=>'0');
  signal clk:std_logic := '0';
  file  read_file  : text open read_mode  is "test.in";

  -- Please change file name
  file  write_file : text open write_mode is "test_fdiv.out";
begin

  -- Please change port map
  fpu_test: FDIV port map (input1=>a, input2=>b, clk=>clk,output=>ans);

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
      a <= unsigned(ra);
      hread(lin, rb);
      b <= unsigned(rb);
    end if;
    if falling_edge(clk) then
      hwrite(lout, std_logic_vector(ans));
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
