-- test case --
-- input(hex) available(1bit) writable(1bit) tag(5bit)

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.std_logic_textio.all;
library work;
use std.textio.all;
use work.kakeudon_fpu.all;

entity fpu_stall_tb1 is
  Port ( MCLK1 : in  STD_LOGIC;
         RS_TX : out  STD_LOGIC);
end fpu_stall_tb1;

architecture Behavior of fpu_stall_tb1 is
  subtype int32 is std_logic_vector(31 downto 0);
  signal a:unsigned32 := (others=>'0');
  signal ans:unsigned32 := (others=>'0');
  signal clk:std_logic := '0';
  signal o_ava, o_wnx, u_ava : std_logic;
  signal o_tag : tomasulo_fpu_tag_t;
  signal i_tag : tomasulo_fpu_tag_t;
  signal i_writable: std_logic;
  signal i_avail : std_logic;

  file  read_file  : text open read_mode  is "/home/udon/cpuex/fpu/VHDL/test/stall_test1.in";

  -- Please change file name
  file  write_file : text open write_mode is "/home/udon/cpuex/fpu/VHDL/test/log/test_stall_fsqrt.out";
begin

  -- Please change port map
  fpu_test: FSQRT
    generic map (last_unit => true)
    port map (
      clk,    -- clk
      '0',    -- refetch
      i_avail,-- in_available
      i_tag,  -- in_tag
      a,      -- in0
      o_ava,  -- out_available
      o_tag,  -- out_tag
      ans,    -- out_value,
      i_writable,    -- cdb_writable
      o_wnx,  -- cdb_writable_next
      u_ava   -- unit_available
    );
  readProc:process(clk)
    variable lin : line;
    variable ra : int32;
    variable rb : int32;
    variable wans : int32;
    variable lout : line;
    variable available : std_logic;
    variable writable  : std_logic;
    variable tag       : int32;
  begin
    if rising_edge(clk) then
      hwrite(lout, std_logic_vector(ans));
      writeline(write_file, lout);
      readline(read_file, lin);
      hread(lin, ra);
      read(lin, available);
      read(lin, writable);
      hread(lin, tag);
      a <= unsigned(ra);
      i_avail <= available;
      i_writable <= writable;
      i_tag <= tomasulo_fpu_tag_t(tag(4 downto 0));
    end if;
    if falling_edge(clk) then

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
