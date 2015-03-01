library IEEE, STD;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;
use work.kakeudon_fpu.all;

entity FSQRT is
  generic (
    last_unit : boolean := true);
  port (
    clk                 : in std_logic;
    refetch             : in std_logic;
    fsqrt_in_available  : in std_logic;
    fsqrt_in_tag        : in tomasulo_fpu_tag_t;
    fsqrt_in            : in unsigned32;
    fsqrt_out_available : out std_logic;
    fsqrt_out_tag       : out tomasulo_fpu_tag_t;
    fsqrt_out_value     : out unsigned32;
    cdb_writable        : in std_logic;
    cdb_writable_next   : out std_logic;
    fsqrt_unit_available: out std_logic
  );
end entity fsqrt;


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
  signal in4                           : unsigned32 := (31 downto 0 => '0');
  signal exp, exp1                     : unsigned(22 downto 0);

  signal o_avail_ax : std_logic;
  signal o_tag_ax : tomasulo_fpu_tag_t;
  signal o_flag_ax: unsigned32;
  signal i_writable_1 : std_logic;
  signal unit_avail_ax : std_logic;
  signal i_avail_ax_b : std_logic;
  signal i_tag_ax_b : tomasulo_fpu_tag_t;
  signal i_flag_ax_b : unsigned32;
  signal unit_avail_ax_b : std_logic;

  signal temp_tag : tomasulo_fpu_tag_t;
  signal temp_ax : unsigned32;
  signal temp_flag : unsigned32;
  signal temp_avail : std_logic;
  signal i_avail_ax : std_logic;
  signal i_tag_ax : tomasulo_fpu_tag_t;
  signal i_flag_ax : unsigned32;

begin

  ax : FMUL_WITH_FLAG port map (
    clk                 => clk,
    refetch             => refetch,
    fmul_in_available   => i_avail_ax,
    fmul_in_tag         => i_tag_ax,
    fmul_in_flag        => i_flag_ax,
    fmul_in0            => a,
    fmul_in1            => reg,
    fmul_out_available  => o_avail_ax,
    fmul_out_tag        => o_tag_ax,
    fmul_out_flag       => o_flag_ax,
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
    fadd_in_flag        => i_flag_ax_b,
    fadd_in0            => ax_in,
    fadd_in1            => b,
    fadd_out_available  => fsqrt_out_available,
    fadd_out_tag        => fsqrt_out_tag,
    fadd_out_flag       => in4,
    fadd_out_value      => axb,
    cdb_writable        => cdb_writable,
    cdb_writable_next   => cdb_writable_next,
    fadd_unit_available => unit_avail_ax_b
  );

  exp1 <= (others => 'X') when TO_01(in4, 'X')(0) = 'X' else
          to_unsigned(to_integer(in4(30 downto 23)) + 1, 23);
  exp <= (others => 'X') when TO_01(exp1, 'X')(0) = 'X' else
         to_unsigned(to_integer(exp1(8 downto 1)) + 63, 23);

  fsqrt_unit_available <= unit_avail_ax or unit_avail_ax_b;
  i_writable_1         <= unit_avail_ax_b;

  fsqrt_out_value <=
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


  fsqrt_proc : process (clk,
                       refetch,
                       fsqrt_in_available,
                       fsqrt_in_tag,
                       fsqrt_in,
                       cdb_writable)

    variable idx1, idx2 : integer := 0;
  begin
    if rising_edge(clk) then

      reg <= "01000000"&fsqrt_in(23 downto 0);
      if TO_01(fsqrt_in, 'X')(0) = 'X' then
        a <= (others => 'X');
      else
        idx1 := to_integer(fsqrt_in(23 downto 13)) * 2;
        a    <= unsigned(to_stdlogicvector(RAM(idx1)));
      end if;

      i_avail_ax <= fsqrt_in_available;
      i_tag_ax   <= fsqrt_in_tag;
      i_flag_ax  <= fsqrt_in;

      temp_tag   <= o_tag_ax;
      temp_flag  <= o_flag_ax;
      temp_ax    <= ax_out;

      if refetch /= '1' then
        temp_avail <= o_avail_ax;
      else
        temp_avail <= '0';
      end if;

      if unit_avail_ax_b = '1' then

        if TO_01(temp_flag, 'X')(0) = 'X' then
          b <= (others => 'X');
        else
          idx2 := to_integer(temp_flag(23 downto 13)) * 2 + 1;
          b    <= unsigned(to_stdlogicvector(RAM(idx2)));
        end if;

        i_tag_ax_b  <= temp_tag;
        i_flag_ax_b <= temp_flag;
        ax_in       <= temp_ax;

        if refetch = '1' then
          i_avail_ax_b <= '0';
        else
          i_avail_ax_b <= temp_avail;
        end if;

      end if;

    end if;
  end process;
end architecture RTL;
