library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.kakeudon_fpu.all;

entity FMUL_WITH_FLAG is
  generic (
    last_unit : boolean);
  Port (
    clk                 : in  std_logic;
    refetch             : in  std_logic;
    fmul_in_available   : in  std_logic;
    fmul_in_tag         : in  tomasulo_fpu_tag_t;
    fmul_in_flag        : in  unsigned (1 downto 0);
    fmul_in0            : in  unsigned (31 downto 0);
    fmul_in1            : in  unsigned (31 downto 0);
    fmul_out_available  : out std_logic;
    fmul_out_tag        : out tomasulo_fpu_tag_t;
    fmul_out_flag       : out unsigned (1 downto 0);
    fmul_out_value      : out unsigned (31 downto 0);
    cdb_writable        : in  std_logic;
    cdb_writable_next   : out std_logic;
    fmul_unit_available : out std_logic);
end entity FMUL_WITH_FLAG;

architecture RTL of FMUL_WITH_FLAG is
  signal stage1_available, stage2_available : std_logic := '0';
  signal stage1_tag, stage2_tag             : tomasulo_fpu_tag_t;
  signal stage1_flag, stage2_flag           : unsigned(1 downto 0);
  signal cdb_use                            : std_logic;
  signal stage2_in1, stage2_in2             : unsigned32;
  signal hh_1, hl1_1, hl2_1                 : unsigned(35 downto 0);
  signal sumExp_1                           : unsigned32;
  signal hh_2, hl1_2, hl2_2                 : unsigned(35 downto 0);
  signal sumExp_2                           : unsigned32;
  signal stage2_output                      : unsigned32;
  signal stage2_output_combinational        : unsigned32;
begin
  stage1 : FMUL_STAGE1 port map(
    input1 => fmul_in0,
    input2 => fmul_in1,
    hh     => hh_1,
    hl1    => hl1_1,
    hl2    => hl2_1,
    sumExp => sumExp_1);
  stage2 : FMUL_STAGE2 port map(
.@ input1  => stage2_in1,
    input2 => stage2_in2,
    hh     => hh_2,
    hl1    => hl1_2,
    hl2    => hl2_2,
    sumExp => sumExp_2,
    output => stage2_output_combinational);

  cdb_use             <= cdb_writable when last_unit else
                         cdb_writable and stage2_available;
  fmul_out_available  <= stage2_available when cdb_use = '1' else
                         'Z';
  fmul_out_value      <= stage2_output when cdb_use = '1' else
                         (others => 'Z');
  fmul_out_tag        <= stage2_tag when cdb_use = '1' else
                         (others => 'Z');
  fmul_out_flag       <= stage2_flag when cdb_use = '1' else
                         (others => 'Z');
  cdb_writable_next   <= cdb_writable and (not stage2_available);
  fmul_unit_available <= cdb_writable or
                         (not stage1_available) or
                         (not stage2_available) or
                         (not fmul_in_available);

  fmul_proc : process (clk)
  begin
    if rising_edge(clk) then
      if refetch = '1' then
        stage1_available <= '0';
        stage2_available <= '0';
      else

        if stage2_available = '1' and cdb_writable /= '1' then
        -- stage2_stall
        else
          stage2_tag       <= stage1_tag;
          stage2_flag      <= stage1_flag;
          stage2_output    <= stage2_output_combinational;
          stage2_available <= stage1_available;
        end if;


        if stage1_available = '1' and
           stage2_available = '1' and
           cdb_writable    /= '1' then
        -- stage1_stall
        else
          stage1_tag       <= fmul_in_tag;
          stage1_flag      <= fmul_in_flag;
          stage1_available <= fmul_in_available;

          stage2_in1 <= fmul_in0;
          stage2_in2 <= fmul_in1;
          hh_2       <= hh_1;
          hl1_2      <= hl1_1;
          hl2_2      <= hl2_1;
          sumExp_2   <= sumExp_1;
        end if;

      end if;
    end if;
  end process;
end architecture RTL;
