library IEEE;
use IEEE.std_logic_1164.all;
use work.kakeudon_fpu.all;

entity FMUL is
  Port (input1   : in  std_logic_vector (31 downto 0);
        input2   : in  std_logic_vector (31 downto 0);
        clk: in std_logic;
        output : out std_logic_vector (31 downto 0));
end entity FMUL;

architecture RTL of FMUL is
  signal input1_1, input2_1, input1_2, input2_2: int32;
  signal hh_1, hl1_1, hl2_1, hh_2, hl1_2, hl2_2: std_logic_vector(35 downto 0);
  signal sumExp_1, sumExp_2: int32;
begin
     stage1: FMUL_STAGE1 port map(
        input1=>input1,
        input2=>input2,
        hh => hh_1,
        hl1 => hl1_1,
        hl2 => hl2_1,
        sumExp => sumExp_1);
    stage2: FMUL_STAGE2 port map(
        input1=>input1_1,
        input2=>input2_1,
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
      hh_2  <= hh_1;
      hl1_2 <= hl1_1;
      hl2_2 <= hl2_1;
      sumExp_2 <= sumExp_1;
    end if;
  end process;
end architecture RTL;
