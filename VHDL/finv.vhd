library IEEE, STD;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.kakeudon_fpu.all;

entity FINV is
  Port (input  : in  unsigned(31 downto 0);
        clk    : in  std_logic;
        output : out unsigned(31 downto 0));
end entity FINV;

architecture RTL of FINV is
  subtype unsigned_word is unsigned(31 downto 0);
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

  signal RAM : RamType := InitRamFromFile("finvTable.data");
  attribute ram_style : string;
  attribute ram_style of RAM: signal is "block";
  signal d:integer;
  signal a, reg, b, ax_in, ax_out, axb : unsigned_word;
  signal in1 : unsigned_word := (31 downto 0 => '0');
  signal in2 : unsigned_word := (31 downto 0 => '0');
  signal in3 : unsigned_word := (31 downto 0 => '0');
  signal in4 : unsigned_word := (31 downto 0 => '0');
  signal exp: unsigned(22 downto 0);
begin
  ax: FMUL port map (
    input1 => a, input2 => reg, clk => clk, output => ax_out
  );
  ax_b: FADD port map (
    input1 => ax_in, input2 => b, clk => clk, output => axb
  );


  d <= to_integer('0'&(in4(30 downto 23))) - 127;
  exp <= axb(30 downto 23) - unsigned(to_signed(d, 23));

  output <=
    -- 1/NaN = NaN
    x"ffffffff" when in4(30 downto 23)=x"ff" and in4(22 downto 0) /= (22 downto 0 => '0') else
    -- 1/Inf = 0
    in4(31)&(30 downto 0 => '0') when in4(30 downto 23) = x"ff" else
    -- 1/0   = Inf
    in4(31)&x"ff"&(22 downto 0 => '0') when in4(30 downto 23) = x"00" else
    -- underflow -> 0
    in4(31)&x"00"&axb(22 downto 0) when to_integer(axb(30 downto 23)) < d else
    -- normal
    in4(31)&exp(7 downto 0)&axb(22 downto 0);

  finv_proc: process(input, clk)
      variable idx1, idx2: integer := 0;
  begin
    if rising_edge(clk) then -- work in 5 clocks

      reg  <= "001111111"&input(22 downto 0);
      idx1 := to_integer(input(22 downto 12)) * 2;
      a <= unsigned(to_stdlogicvector(RAM(idx1)));

      idx2 := to_integer(in2(22 downto 12)) * 2 + 1;
      b <= unsigned(to_stdlogicvector(RAM(idx2)));

      in4 <= in3;
      in3 <= in2;
      in2 <= in1;
      in1 <= input;

      ax_in <= ax_out;

    end if;
  end process;
end architecture RTL;
