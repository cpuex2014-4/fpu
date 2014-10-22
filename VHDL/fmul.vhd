library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

entity FMUL is
  Port (input1   : in  std_logic_vector (31 downto 0);
        input2   : in  std_logic_vector (31 downto 0);
        clk: in std_logic;
        output : out std_logic_vector (31 downto 0));
end entity FMUL;
architecture RTL of FMUL is
  subtype int32 is std_logic_vector(31 downto 0);
  component FMUL_STAGE1 is
  Port (input1   : in  std_logic_vector (31 downto 0);
        input2   : in  std_logic_vector (31 downto 0);
        hh   : out  std_logic_vector (35 downto 0);
        hl1  : out  std_logic_vector (35 downto 0);
        hl2  : out  std_logic_vector (35 downto 0);
        sumExp : out std_logic_vector (31 downto 0));
  end component;
  component FMUL_STAGE2 is
  Port (input1   : in  std_logic_vector (31 downto 0);
        input2   : in  std_logic_vector (31 downto 0);
        hh   : in  std_logic_vector (35 downto 0);
        hl1  : in  std_logic_vector (35 downto 0);
        hl2  : in  std_logic_vector (35 downto 0);
        sumExp : in std_logic_vector (31 downto 0);
        output : out std_logic_vector (31 downto 0));
  end component;
  signal input1_1, input2_1, input1_2, input2_2: int32;
  signal hh_1, hl1_1, hl2_1, hh_2, hl1_2, hl2_2: std_logic_vector(35 downto 0);
  signal sumExp_1, sumExp_2: int32;
begin
     stage1: FMUL_STAGE1 port map(
        input1=>input1_1,
        input2=>input2_1,
        hh => hh_1,
        hl1 => hl1_1,
        hl2 => hl2_1,
        sumExp => sumExp_1);
    stage2: FMUL_STAGE2 port map(
        input1=>input1_2,
        input2=>input2_2,
        hh => hh_2,
        hl1 => hl1_2,
        hl2 => hl2_2,
        sumExp => sumExp_2,
        output => output);

  fmul_proc:process(input1, input2, clk)
    variable in_1, in_2: int32;
  begin
    if rising_edge(clk) then
      in_1 := input1_1;
      in_2 := input2_1;
      input1_1 <= input1;
      input2_1 <= input2;
      input1_2 <= in_1;
      input2_2 <= in_2;
      hh_2  <= hh_1;
      hl1_2 <= hl1_1;
      hl2_2 <= hl2_1;
      sumExp_2 <= sumExp_1;
    end if;
  end process;
end architecture RTL;
