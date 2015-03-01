library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.kakeudon_fpu.all;

entity ITOF is
  generic (
    last_unit : boolean := true);
  port (
    clk                 : in  std_logic;
    refetch             : in  std_logic;
    itof_in_available   : in  std_logic;
    itof_in_tag         : in  tomasulo_fpu_tag_t;
    itof_in             : in  unsigned32;
    itof_out_available  : out std_logic;
    itof_out_tag        : out tomasulo_fpu_tag_t;
    itof_out_value      : out unsigned32;
    cdb_writable        : in  std_logic;
    cdb_writable_next   : out std_logic;
    itof_unit_available : out std_logic
  );
end entity itof;

architecture RTL of ITOF is

  type reg_type is record
    a     : unsigned32;
    b     : unsigned32;
    avail : std_logic;
    tag   : tomasulo_fpu_tag_t;
    sign  : std_logic;
  end record;

  signal low, high       : unsigned32;
  signal a1, b1          : unsigned32;
  signal a, b            : unsigned32;
  signal ans             : unsigned32;
  signal i_sign_1        : unsigned32;
  signal i_writable_1    : std_logic;
  signal unit_avail_low  : std_logic;
  signal unit_avail_high : std_logic;
  signal unit_avail_hl   : std_logic;
  signal i_avail_hl      : std_logic;
  signal i_tag_hl        : tomasulo_fpu_tag_t;
  signal i_sign_hl       : unsigned32;
  signal o_avail_low     : std_logic;
  signal o_avail_high    : std_logic;
  signal o_tag_low       : tomasulo_fpu_tag_t;
  signal o_tag_high      : tomasulo_fpu_tag_t;
  signal o_sign_low      : unsigned32;
  signal o_sign_high     : unsigned32;
  signal o_sign_hl       : unsigned32;

  signal t : unsigned32;

  signal r, rin : reg_type;

begin
  lowsub : FADD_WITH_FLAG port map (
    clk                 => clk,
    refetch             => refetch,
    fadd_in_available   => itof_in_available,
    fadd_in_tag         => itof_in_tag,
    fadd_in_flag        => i_sign_1,
    fadd_in0            => low,
    fadd_in1            => x"cb000000",
    fadd_out_available  => o_avail_low,
    fadd_out_tag        => o_tag_low,
    fadd_out_flag       => o_sign_low,
    fadd_out_value      => a1,
    cdb_writable        => i_writable_1,
    cdb_writable_next   => open,
    fadd_unit_available => unit_avail_low
  );
  highsub : FADD_WITH_FLAG port map (
    clk                 => clk,
    refetch             => refetch,
    fadd_in_available   => itof_in_available,
    fadd_in_tag         => itof_in_tag,
    fadd_in_flag        => i_sign_1,
    fadd_in0            => high,
    fadd_in1            => x"d6800000",
    fadd_out_available  => o_avail_high,
    fadd_out_tag        => o_tag_high,
    fadd_out_flag       => o_sign_high,
    fadd_out_value      => b1,
    cdb_writable        => i_writable_1,
    cdb_writable_next   => open,
    fadd_unit_available => unit_avail_high
  );
  hladd : FADD_WITH_FLAG port map (
    clk                 => clk,
    refetch             => refetch,
    fadd_in_available   => i_avail_hl,
    fadd_in_tag         => i_tag_hl,
    fadd_in_flag        => i_sign_hl,
    fadd_in0            => a,
    fadd_in1            => b,
    fadd_out_available  => itof_out_available,
    fadd_out_tag        => itof_out_tag,
    fadd_out_flag       => o_sign_hl,
    fadd_out_value      => ans,
    cdb_writable        => cdb_writable,
    cdb_writable_next   => cdb_writable_next,
    fadd_unit_available => unit_avail_hl
  );

  itof_unit_available <= unit_avail_low or unit_avail_hl;
  itof_out_value      <= o_sign_hl(0) & ans(30 downto 0);
  i_sign_1            <= (29 downto 0 => '0') & itof_in(31);
  i_writable_1        <= unit_avail_hl;

  t <= itof_in when itof_in(31) = '0' else
       (not itof_in) + 1;

  low  <= ("000000000" & t(22 downto 0)) + x"4b000000";
  high <= (x"000000" & t(30 downto 23)) + x"56800000";


  reg : process (clk,
                  refetch,
                  itof_in_available,
                  itof_in_tag,
                  itof_in,
                  cdb_writable)
  begin
    if rising_edge(clk) then
      if unit_avail_hl = '1' then
        a         <= a1;
        b         <= b1;
        i_tag_hl  <= o_tag_low;
        i_sign_hl <= o_sign_low;

        if refetch = '1' then
          i_avail_hl <= '0';
        else
          i_avail_hl <= o_avail_low;
        end if;

      end if;
    end if;
  end process;

end architecture;
