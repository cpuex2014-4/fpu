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
  component FADD is
  port (
    input1 : in  std_logic_vector (31 downto 0);
    input2 : in  std_logic_vector (31 downto 0);
    output : out std_logic_vector (31 downto 0)
  );
  end component;
  signal a:int32 := (others=>'0');
  signal b:int32 := (others=>'0');
  signal ans:int32 := (others=>'0');
  -- signal clk:std_logic := '0';
  file  read_file  : text open read_mode  is "test.in";
  file  write_file : text open write_mode is "test.out";
begin
  hoge: FADD port map (input1=>a,input2=>b,output=>ans);

  readProc:process
    variable lin : line;
    variable ra : int32;
    variable rb : int32;
    variable wans : int32;
    variable lout : line;
  begin
    while not(endfile(read_file)) loop
      readline(read_file, lin);
      hread(lin, ra);
      hread(lin, rb);
      a <= ra;
      b <= rb;
      wait for 2 ns;
      wans:=ans;
      hwrite(lout, wans);
      writeline(write_file, lout);
    end loop;
    wait;
  end process;

end Behavior;