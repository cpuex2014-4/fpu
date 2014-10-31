library IEEE;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity top is
  Port ( MCLK1 : in  STD_LOGIC;
         RS_TX : out  STD_LOGIC);
end top;

architecture Behavior of top is
  subtype int32 is std_logic_vector(31 downto 0);
  component FDIV is
  Port (
    input1 : in  int32;
    input2 : in  int32;
    clk: in std_logic;
    output : out int32);
  end component;
  signal a:int32 := (others=>'0');
  signal b:int32 := (others=>'0');
  signal ans:int32 := (others=>'0');
  signal clk:std_logic := '0';
  file  read_file  : text open read_mode  is "test.in";
  file  write_file : text open write_mode is "fdivTest.out";
begin
  div_test: FDIV port map (input1=>a,input2=>b, clk=>clk, output=>ans);

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
      hread(lin, rb);
      a <= ra;
      b <= rb;
    end if;
    if falling_edge(clk) then
      hwrite(lout, ans);
      writeline(write_file, lout);
    end if;
  end process;

  clockgen: process
  begin
    clk<='0';
    wait for 2 ns;
    clk<='1';
    wait for 2 ns;
  end process;


end Behavior;
