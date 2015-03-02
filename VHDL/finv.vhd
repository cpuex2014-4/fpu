library IEEE, STD;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.kakeudon_fpu.all;

entity FINV is
  port (
    clk                 : in  std_logic;
    refetch             : in  std_logic;
    finv_in_available   : in  std_logic;
    finv_in_tag         : in  tomasulo_fpu_tag_t;
    finv_in_flag        : in  unsigned32;
    finv_in             : in  unsigned32;
    finv_out_available  : out std_logic;
    finv_out_tag        : out tomasulo_fpu_tag_t;
    finv_out_flag       : out unsigned32;
    finv_out_value      : out unsigned32;
    cdb_writable        : in  std_logic;
    cdb_writable_next   : out std_logic;
    finv_unit_available : out std_logic
  );
end entity FINV;


architecture RTL of FINV is
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

  signal RAM                 : RamType    := InitRamFromFile("finvTable.data");
  attribute ram_style        : string;
  attribute ram_style of RAM : signal is "block";
  signal d                   : signed(8 downto 0);
  signal a, b, reg, ax_in    : unsigned32;
  signal ax_out, axb         : unsigned32;
  signal in4                 : unsigned32 := (31 downto 0 => '0');
  signal exp                 : unsigned(7 downto 0);

  signal o_avail_ax      : std_logic;
  signal o_tag_ax        : tomasulo_fpu_tag_t;
  signal o_flag1_ax      : unsigned32;
  signal o_flag2_ax      : unsigned32;
  signal i_writable_1    : std_logic := '1';
  signal unit_avail_ax   : std_logic;

  signal i_avail_ax    : std_logic;
  signal i_tag_ax      : tomasulo_fpu_tag_t;
  signal i_flag1_ax    : unsigned32;
  signal i_flag2_ax    : unsigned32;


  signal i_avail_ax_b    : std_logic;
  signal i_tag_ax_b      : tomasulo_fpu_tag_t;
  signal i_flag1_ax_b    : unsigned32;
  signal i_flag2_ax_b    : unsigned32;
  signal unit_avail_ax_b : std_logic;

  signal temp_tag   : tomasulo_fpu_tag_t;
  signal temp_ax    : unsigned32;
  signal temp_flag1 : unsigned32;
  signal temp_flag2 : unsigned32;
  signal temp_avail : std_logic;


begin



  ax : FMUL_WITH_FLAG port map (
    clk                 => clk,
    refetch             => refetch,
    fmul_in_available   => i_avail_ax,
    fmul_in_tag         => i_tag_ax,
    fmul_in_flag1       => i_flag1_ax,
    fmul_in_flag2       => i_flag2_ax,
    fmul_in0            => a,
    fmul_in1            => reg,
    fmul_out_available  => o_avail_ax,
    fmul_out_tag        => o_tag_ax,
    fmul_out_flag1      => o_flag1_ax,
    fmul_out_flag2      => o_flag2_ax,
    fmul_out_value      => ax_out,
    cdb_writable        => i_writable_1,
    cdb_writable_next   => open,
    fmul_unit_available => unit_avail_ax
  );

  ax_b : FADD_WITH_FLAG port map (
    clk                 => clk,
    refetch             => refetch,
    fadd_in_available   => i_avail_ax_b,
    fadd_in_tag         => i_tag_ax_b,
    fadd_in_flag1       => i_flag1_ax_b,
    fadd_in_flag2       => i_flag2_ax_b,
    fadd_in0            => ax_in,
    fadd_in1            => b,
    fadd_out_available  => finv_out_available,
    fadd_out_tag        => finv_out_tag,
    fadd_out_flag1      => in4,
    fadd_out_flag2      => finv_out_flag,
    fadd_out_value      => axb,
    cdb_writable        => cdb_writable,
    cdb_writable_next   => cdb_writable_next,
    fadd_unit_available => unit_avail_ax_b
  );


  d   <= signed('0'&(in4(30 downto 23))) - 127;
  exp <= axb(30 downto 23) - unsigned(d(7 downto 0));

  finv_out_value <=
    (others => 'X') when TO_01(in4, 'X')(0) = 'X' or TO_01(d, 'X')(0) = 'X' else
    -- 1/NaN = NaN
    x"ffffffff" when in4(30 downto 23)=x"ff" and in4(22 downto 0) /= (22 downto 0 => '0') else
    -- 1/Inf = 0
    in4(31)&(30 downto 0 => '0') when in4(30 downto 23) = x"ff" else
    -- 1/0   = Inf
    in4(31)&x"ff"&(22 downto 0 => '0') when in4(30 downto 23) = x"00" else
    -- underflow -> 0
    in4(31)&x"00"&axb(22 downto 0) when signed(axb(30 downto 23)) < d else
    -- normal
    in4(31)&exp&axb(22 downto 0);

  i_writable_1         <= unit_avail_ax_b;

  finv_proc: process (clk,
                      refetch,
                      finv_in_available,
                      finv_in_tag,
                      finv_in,
                      cdb_writable)

      variable idx1, idx2: integer := 0;
  begin
    if rising_edge(clk) then -- work in 5 clocks

      reg  <= "001111111"&finv_in(22 downto 0);
      if TO_01(finv_in, 'X')(0) = 'X' then
        a <= (others => 'X');
      else
        idx1 := to_integer(finv_in(22 downto 12)) * 2;
        a <= unsigned(to_stdlogicvector(RAM(idx1)));
      end if;

      i_avail_ax  <= finv_in_available;
      i_tag_ax  <= finv_in_tag;
      i_flag1_ax <= finv_in;
      i_flag2_ax   <= finv_in_flag;


      temp_tag    <= o_tag_ax;
      temp_flag1  <= o_flag1_ax;
      temp_flag2  <= o_flag2_ax;
      temp_ax     <= ax_out;


      if refetch /= '1' then
        temp_avail <= o_avail_ax;
      else
        temp_avail <= '0';
      end if;

      if unit_avail_ax_b = '1' then

        if TO_01(temp_flag1, 'X')(0) = 'X' then
          b <= (others => 'X');
        else
          idx2 := to_integer(temp_flag1(22 downto 12)) * 2 + 1;
          b <= unsigned(to_stdlogicvector(RAM(idx2)));
        end if;

        i_tag_ax_b   <= temp_tag;
        i_flag1_ax_b <= temp_flag1;
        i_flag2_ax_b <= temp_flag2;
        ax_in        <= temp_ax;

        if refetch = '1' then
          i_avail_ax_b <= '0';
        else
          i_avail_ax_b <= temp_avail;
        end if;

      end if;

    end if;
  end process;
end architecture RTL;
