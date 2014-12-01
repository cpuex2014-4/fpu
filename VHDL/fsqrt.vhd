library IEEE, STD;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.kakeudon_fpu.all;

entity FSQRT is
  Port (input  : in  std_logic_vector(31 downto 0);
        clk    : in  std_logic;
        output : out std_logic_vector(31 downto 0));
end entity FSQRT;

architecture RTL of FSQRT is
  subtype int32 is std_logic_vector(31 downto 0);
  type RamType is array(0 to 4095) of bit_vector(31 downto 0);
  impure function InitRamFromFile (RamFileName : in string) return RamType is
    FILE RamFile : text open read_mode is RamFileName;
    variable RamFileLine : line;
    variable RAM : RamType;
  begin
    for I in RamType'range loop
        readline (RamFile, RamFileLine);
        read (RamFileLine, RAM(I));
    end loop;
    return RAM;
  end function;

  signal RAM : RamType := InitRamFromFile("fsqrtTable.data");

  signal a, reg, b, ax_in, ax_out, axb : int32;
  signal in1 : int32 := (31 downto 0 => '0');
  signal in2 : int32 := (31 downto 0 => '0');
  signal in3 : int32 := (31 downto 0 => '0');
  signal in4 : int32 := (31 downto 0 => '0');
  signal iexp1, iexp2: integer := 0;
  signal exp, exp1: std_logic_vector(22 downto 0);
begin

  ax: FMUL port map (
    input1 => a, input2 => reg, clk => clk, output => ax_out
  );
  ax_b: FADD port map (
    input1 => ax_in, input2 => b, clk => clk, output => axb
  );


  iexp1 <= conv_integer(in4(30 downto 23)) + 1;
  exp1 <= conv_std_logic_vector(iexp1, 23);
  iexp2 <= conv_integer(exp1(8 downto 1)) + 63;
  exp <= conv_std_logic_vector(iexp2, 23);

  output <=
    -- sqrt(+|- 0) = +|-0
    in4(31)&(30 downto 0 => '0') when in4(30 downto 23) = x"00" else
    -- sqrt(negative) = NaN
    x"ffffffff" when in4(31) = '1' else
    -- sqrt(NaN) = NaN
    x"ffffffff" when in4(30 downto 23)=x"ff" and in4(22 downto 0) /= (22 downto 0 => '0') else
    -- sqrt(Inf) = Inf
    x"7f800000" when in4(30 downto 23) = x"ff" else
    -- normal
    '0'&exp(7 downto 0)&axb(22 downto 0);

  fsqrt_proc: process(input, clk)
    variable idx1, idx2 : integer := 0;
  begin
    if rising_edge(clk) then -- work in 5 clocks
        reg  <= "01000000"&input(23 downto 0);
        idx1 := conv_integer(input(23 downto 13)) * 2;
        a <= to_stdlogicvector(RAM(idx1));

        idx2 := conv_integer(in2(23 downto 13)) * 2 + 1;
        b <= to_stdlogicvector(RAM(idx2));

        in4 <= in3;
        in3 <= in2;
        in2 <= in1;
        in1 <= input;

        ax_in <= ax_out;

    end if;
  end process;
end architecture RTL;
