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
  component FMUL is
    port (
      input1 : in  std_logic_vector (31 downto 0);
      input2 : in  std_logic_vector (31 downto 0);
      clk: in std_logic;
      output : out std_logic_vector (31 downto 0)
      );
  end component;
  signal a:int32 := (others=>'0');
  signal b:int32 := (others=>'0');
  signal ans:int32 := (others=>'0');
  signal cnt: integer := 0;
  type rom_t is array(0 to 11) of int32;
  constant as: rom_t := (
    x"78d06b3d",
    x"42c14aba",
    x"eaa3a6b7",
    x"aa701cb3",
    x"e5e60820",
    x"02816df6",
    x"1d02209b",
    x"f6d769e0",
    x"3d480121",
    x"3e792d7d",
    x"6e1de388",
    x"00000000"
   );
  constant bs: rom_t := (
    x"b8952f5c",
    x"feb91718",
    x"eb67d051",
    x"9d0c9c4c",
    x"8c56009d",
    x"d272708b",
    x"88d27d89",
    x"af931679",
    x"df206da2",
    x"3187ef87",
    x"2b9a5157",
    x"00000000"
  );

  constant cs: rom_t := (
    x"f1f2e9f2",
    x"ff800000",
    x"7f800000",
    x"0803e24a",
    x"32c04b58",
    x"957525b2",
    x"80000000",
    x"66f78969",
    x"dcfaacb8",
    x"30845021",
    x"5a3e5a15",
    x"deadbeef" -- wrong answer
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

  hoge: FMUL port map (input1=>a,input2=>b,clk=>clk, output=>ans);

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
       if uart_busy='0' and uart_go='0' then
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
         uart_go <= '1';

         if cnt = 12 then
           cnt <= 0;
         else
           cnt <= cnt + 1;
         end if;
         a <= as(cnt);
         b <= bs(cnt);
       else
         uart_go <= '0';
       end if;
    end if;
  end process;

end Behavior;
