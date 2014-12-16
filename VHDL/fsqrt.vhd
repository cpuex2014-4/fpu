library IEEE, STD;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.kakeudon_fpu.all;

entity FSQRT is
  Port (input  : in  unsigned(31 downto 0);
        clk    : in  std_logic;
        output : out unsigned(31 downto 0));
end entity FSQRT;

architecture RTL of FSQRT is
  subtype unsigned32 is unsigned(31 downto 0);
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
  attribute ram_style : string;
  attribute ram_style of RAM: signal is "block";

  signal a, reg, b, ax_in, ax_out, axb : unsigned32;
  signal in1 : unsigned32 := (31 downto 0 => '0');
  signal in2 : unsigned32 := (31 downto 0 => '0');
  signal in3 : unsigned32 := (31 downto 0 => '0');
  signal in4 : unsigned32 := (31 downto 0 => '0');
  signal exp, exp1: unsigned(22 downto 0);
begin

  ax: FMUL_OLD port map (
    input1 => a, input2 => reg, clk => clk, output => ax_out
  );
  ax_b: FADD port map (
    input1 => ax_in, input2 => b, clk => clk, output => axb
  );


  exp1 <= (others => 'X') when TO_01(in4, 'X')(0) = 'X' else
          to_unsigned(to_integer(in4(30 downto 23)) + 1, 23);
  exp <= (others => 'X') when TO_01(exp1, 'X')(0) = 'X' else
         to_unsigned(to_integer(exp1(8 downto 1)) + 63, 23);

  output <=
    (others => 'X') when TO_01(in4, 'X')(0) = 'X' else
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
        if TO_01(input, 'X')(0) = 'X' then
          a <= (others => 'X');
        else
          idx1 := to_integer(input(23 downto 13)) * 2;
          a <= unsigned(to_stdlogicvector(RAM(idx1)));
        end if;

        if TO_01(in2, 'X')(0) = 'X' then
          b <= (others => 'X');
        else
          idx2 := to_integer(in2(23 downto 13)) * 2 + 1;
          b <= unsigned(to_stdlogicvector(RAM(idx2)));
        end if;

        in4 <= in3;
        in3 <= in2;
        in2 <= in1;
        in1 <= input;

        ax_in <= ax_out;

    end if;
  end process;
end architecture RTL;
