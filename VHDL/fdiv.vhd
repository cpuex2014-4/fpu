library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.kakeudon_fpu.all;

entity FDIV is
  generic (
    last_unit : boolean);
  Port (
    clk                 : in  std_logic;
    refetch             : in  std_logic;
    fdiv_in_available   : in  std_logic;
    fdiv_in_tag         : in  tomasulo_fpu_tag_t;
    fdiv_in0            : in  unsigned32;
    fdiv_in1            : in  unsigned32;
    fdiv_out_available  : out std_logic;
    fdiv_out_tag        : out tomasulo_fpu_tag_t;
    fdiv_out_value      : out unsigned32;
    cdb_writable        : in  std_logic;
    cdb_writable_next   : out std_logic;
    fdiv_unit_available : out std_logic);
end entity FDIV;

architecture RTL of FDIV is

  signal a, b                 : unsigned32 := (others => '0');
  signal a5                   : unsigned32 := (others => '0');
  signal inv_in, inv_out, ans : unsigned32;
  signal o_avail_inv          : std_logic;
  signal o_tag_inv            : tomasulo_fpu_tag_t;
  signal o_flag_inv           : unsigned32;
  signal o_value_inv          : unsigned32;
  signal i_writable_1         : std_logic;
  signal unit_avail_inv       : std_logic;
  signal i_avail_mul          : std_logic;
  signal i_tag_mul            : tomasulo_fpu_tag_t;
  signal i_flag_mul           : unsigned32;
  signal i_in1_mul            : unsigned32;
  signal unit_avail_mul       : std_logic;

begin

  inv : FINV port map (
    clk                 => clk,
    refetch             => refetch,
    finv_in_available   => fdiv_in_available,
    finv_in_tag         => fdiv_in_tag,
    finv_in_flag        => a,
    finv_in             => b,
    finv_out_available  => o_avail_inv,
    finv_out_tag        => o_tag_inv,
    finv_out_flag       => o_flag_inv,
    finv_out_value      => o_value_inv,
    cdb_writable        => i_writable_1,
    cdb_writable_next   => open,
    finv_unit_available => unit_avail_inv
  );

  mul : FMUL_WITH_FLAG port map (
    clk                 => clk,
    refetch             => refetch,
    fmul_in_available   => i_avail_mul,
    fmul_in_tag         => i_tag_mul,
    fmul_in_flag1       => (others => 'Z'),
    fmul_in_flag2       => (others => 'Z'),
    fmul_in0            => a5,
    fmul_in1            => i_in1_mul,
    fmul_out_available  => fdiv_out_available,
    fmul_out_tag        => fdiv_out_tag,
    fmul_out_flag1      => open,
    fmul_out_flag2      => open,
    fmul_out_value      => ans,
    cdb_writable        => cdb_writable,
    cdb_writable_next   => cdb_writable_next,
    fmul_unit_available => unit_avail_mul
  );

  fdiv_unit_available  <= unit_avail_inv or unit_avail_mul;
  i_writable_1         <= unit_avail_mul;

  a <= (others => 'X') when TO_01(fdiv_in0, 'X')(0) = 'X' else
       fdiv_in0(31)&(30 downto 0 => '0') when fdiv_in0(30 downto 23) = x"00" else
       fdiv_in0;
  b <= (others => 'X') when TO_01(fdiv_in1, 'X')(0) = 'X' else
       fdiv_in1(31)&(30 downto 0 => '0') when fdiv_in1(30 downto 23) = x"00" else
       fdiv_in1;

  fdiv_out_value <= ans;

  fdiv_proc: process(clk,
                     refetch,
                     fdiv_in_available,
                     fdiv_in_tag,
                     fdiv_in0,
                     fdiv_in1,
                     cdb_writable)
  begin
    if rising_edge(clk) then
      if unit_avail_mul = '1' then

        i_tag_mul <= o_tag_inv;
        a5 <= o_flag_inv;
        i_in1_mul <= o_value_inv;

        if refetch = '1' then
          i_avail_mul <= '0';
        else
          i_avail_mul <= o_avail_inv;
        end if;

      end if;
    end if;
  end process;

end architecture;
