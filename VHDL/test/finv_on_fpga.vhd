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
  component FINV is
    port (
      input : in  std_logic_vector (31 downto 0);
      clk: in std_logic;
      output : out std_logic_vector (31 downto 0)
      );
  end component;
  signal a:int32 := (others=>'0');
  signal ans:int32 := (others=>'0');
  signal cnt: integer := 0;
  type rom_t is array(0 to 11) of int32;
  constant as: rom_t := (
    x"78d06b3d",
    x"b8952f5c",
    x"42c14aba",
    x"feb91718",
    x"eaa3a6b7",
    x"eb67d051",
    x"aa701cb3",
    x"9d0c9c4c",
    x"e5e60820",
    x"8c56009d",
    x"02816df6",
    x"00000000"
   );
  constant bs: rom_t := (
    x"061d38ca",
    x"c65ba591",
    x"3c2986a6",
    x"803109bc",
    x"94483b0f",
    x"938d5ad8",
    x"d4887837",
    x"e1e90a77",
    x"990e732d",
    x"f2991ea9",
    x"7c7d2c2a",
    x"deadbeef" --wrong answer
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

  hoge: FINV port map (input=>a,clk=>clk, output=>ans);

  rs232c: u232c generic map (wtime=>x"1ADB")
    port map (
      clk=>clk,
      data=>result,
      go=>uart_go,
      busy=>uart_busy,
      tx=>rs_tx);

  calc: process(clk)
  begin
    a <= as(cnt);
    if rising_edge(clk) then
       if uart_busy='0' and uart_go='0' then
         if ans = bs(cnt) then
           result <= x"01";
         else
           result <= ans(7 downto 0);
         end if;
         uart_go <= '1';

         if cnt = 11 then
           cnt <= 0;
         else
           cnt <= cnt + 1;
         end if;
         a <= as(cnt);
       else
         uart_go <= '0';
       end if;
    end if;
  end process;

end Behavior;
