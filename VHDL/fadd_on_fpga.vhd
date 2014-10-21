library IEEE;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library UNISIM;
use UNISIM.VComponents.all;
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
  signal cnt: integer := 0;
  type rom_t is array(0 to 11) of int32;
  constant as: rom_t := (
    x"40400000",
    x"3f800000",
    x"40400000",
    x"3f800000",
    x"80000000",
    x"00800001",
    x"80800001",
    x"7f7fffff",
    x"7f7fffff",
    x"7f800000",
    x"7f800000",
    x"7fffffff"
    );
  constant bs: rom_t := (
    x"40400000",
    x"40000000",
    x"bf800000",
    x"bf800000",
    x"80000000",
    x"80800000",
    x"00800000",
    x"00800000",
    x"7f7fffff",
    x"7f800000",
    x"ff800000",
    x"3f800000"
    );

  constant cs: rom_t := (
    x"40c00000",
    x"40400000",
    x"40000000",
    x"00000000",
    x"80000000",
    x"00000000",
    x"80000000",
    x"7f7fffff",
    x"7f800000",
    x"7f800000",
    x"ffffffff",
    x"ffffffff"
    );
  component u232c
    generic (wtime: std_logic_vector(15 downto 0) := x"1ADB");
    port ( clk  : in  STD_LOGIC;
           data : in  STD_LOGIC_VECTOR (7 downto 0);
           go   : in  STD_LOGIC;
           busy : out STD_LOGIC;
           tx   : out STD_LOGIC);
  end component;
  signal clk,iclk: STD_LOGIC;
  signal uart_go: std_logic;
  signal uart_busy: std_logic := '0';
  signal result : std_logic_vector(7 downto 0);
  signal state  : std_logic_vector(1 downto 0);
  signal counter : std_logic_vector(7 downto 0) := x"00";
begin
  ib: IBUFG port map (
    i=>MCLK1,
    o=>iclk);
  bg: BUFG port map (
    i=>iclk,
    o=>clk);

  hoge: FADD port map (input1=>a,input2=>b,output=>ans);

  rs232c: u232c generic map (wtime=>x"1ADB")
    port map (
      clk=>clk,
      data=>result,
      go=>uart_go,
      busy=>uart_busy,
      tx=>rs_tx);

  calc: process(clk)
    variable cm: integer;
  begin
    a <= as(cnt);
    b <= bs(cnt);
    if rising_edge(clk) then
      if cnt = 0 then
        cm := 11;
      else
        cm := cnt-1;
      end if;
      if ans = cs(cm) then
        result <= x"01";
      else
        result <= x"00";
      end if;
      if cnt = 12 then
        cnt <= 0;
      else
        cnt <= cnt + 1;
      end if;
      a <= as(cnt);
      b <= bs(cnt);
    end if;
  end process;

end Behavior;
