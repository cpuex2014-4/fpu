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
  component FTOI is
  Port (
    input : in  int32;
    output : out int32);
end component;
  signal a:int32 := (others=>'0');
  signal ans:int32 := (others=>'0');
  -- signal clk:std_logic := '0';
  file  read_file  : text open read_mode  is "f2i.in";
  file  write_file : text open write_mode is "f2i.out";
begin
  hoge: FTOI port map (input=>a,output=>ans);

  readProc:process
    variable lin : line;
    variable ra : int32;
    variable wans : int32;
    variable lout : line;
  begin
    while not(endfile(read_file)) loop
      readline(read_file, lin);
      hread(lin, ra);
      a <= ra;
      wait for 2 ns;
      wans:=ans;
      hwrite(lout, wans);
      writeline(write_file, lout);
    end loop;
    wait;
  end process;

end Behavior;
