library IEEE, STD;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity FINV is
  Port (input  : in  std_logic_vector(31 downto 0);
        clk    : in  std_logic;
        output : out std_logic_vector(31 downto 0));
end entity FINV;

architecture RTL of FINV is
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

  signal RAM : RamType := InitRamFromFile("finvTable.data");

  component FADD is
    port (
      input1 : in int32;
      input2 : in int32;
      clk: std_logic;
      output : out int32);
  end component;
  component FMUL is
    port (
      input1 : in int32;
      input2 : in int32;
      clk: std_logic;
      output : out int32);
  end component;
  signal a, reg, b, ax_in, ax_out, axb : int32;
  signal in1 : int32 := (31 downto 0 => '0');
  signal in2 : int32 := (31 downto 0 => '0');
  signal in3 : int32 := (31 downto 0 => '0');
  signal in4 : int32 := (31 downto 0 => '0');
  signal in5 : int32 := (31 downto 0 => '0');
  signal idx1, idx2, d: integer := 0;
  signal exp: std_logic_vector(22 downto 0);
begin
  ax: FMUL port map (
    input1 => a, input2 => reg, clk => clk, output => ax_out
  );
  ax_b: FADD port map (
    input1 => ax_in, input2 => b, clk => clk, output => axb
  );

  reg  <= "001111111"&input(22 downto 0);
  idx1 <= conv_integer(input(22 downto 12)) * 2;
  a <= to_stdlogicvector(RAM(idx1));

  idx2 <= conv_integer(in3(22 downto 12)) * 2 + 1;
  b <= to_stdlogicvector(RAM(idx2));

  d <= conv_integer(in5(30 downto 23)) - 127;
  exp <= axb(30 downto 23) - conv_std_logic_vector(d, 23);

  output <=
    -- 1/NaN = NaN
    x"ffffffff" when in5(30 downto 23)=x"ff" and in5(22 downto 0) /= (22 downto 0 => '0') else
    -- 1/Inf = 0
    in5(31)&(30 downto 0 => '0') when in5(30 downto 23) = x"ff" else
    -- 1/0   = Inf
    in5(31)&x"ff"&(22 downto 0 => '0') when in5(30 downto 23) = x"00" else
    -- underflow -> 0
    in5(31)&x"00"&axb(22 downto 0) when conv_integer(axb(30 downto 23)) < d else
    -- normal
    in5(31)&exp(7 downto 0)&axb(22 downto 0);

  finv_proc: process(input, clk)
  begin
    if rising_edge(clk) then -- work in 5 clocks
      in5 <= in4;
      in4 <= in3;
      in3 <= in2;
      in2 <= in1;
      in1 <= input;

      ax_in <= ax_out;

    end if;
  end process;
end architecture RTL;
