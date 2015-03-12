library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
package kakeudon_fpu is
  subtype unsigned32 is unsigned(31 downto 0);
  subtype tomasulo_fpu_tag_t is unsigned(4 downto 0);

   component FADD is
    generic (
      last_unit : boolean);
    port (
      clk                 : in  std_logic;
      refetch             : in  std_logic;
      fadd_in_available   : in  std_logic;
      fadd_in_tag         : in  tomasulo_fpu_tag_t;
      fadd_in0            : in  unsigned (31 downto 0);
      fadd_in1            : in  unsigned (31 downto 0);
      fadd_out_available  : out std_logic;
      fadd_out_tag        : out tomasulo_fpu_tag_t;
      fadd_out_value      : out unsigned (31 downto 0);
      cdb_writable        : in  std_logic;
      cdb_writable_next   : out std_logic;
      fadd_unit_available : out std_logic);
  end component;

  component FADD_WITH_FLAG is
  port (
    clk                 : in  std_logic;
    refetch             : in  std_logic;
    fadd_in_available   : in  std_logic;
    fadd_in_tag         : in  tomasulo_fpu_tag_t;
    fadd_in_flag1       : in  unsigned32;
    fadd_in_flag2       : in  unsigned32;
    fadd_in0            : in  unsigned32;
    fadd_in1            : in  unsigned32;
    fadd_out_available  : out std_logic;
    fadd_out_tag        : out tomasulo_fpu_tag_t;
    fadd_out_flag1      : out unsigned32;
    fadd_out_flag2      : out unsigned32;
    fadd_out_value      : out unsigned32;
    cdb_writable        : in  std_logic;
    cdb_writable_next   : out std_logic;
    fadd_unit_available : out std_logic);
  end component;


  component FMUL is
    generic (
      last_unit : boolean);
    port (
      clk                 : in  std_logic;
      refetch             : in  std_logic;
      fmul_in_available   : in  std_logic;
      fmul_in_tag         : in  tomasulo_fpu_tag_t;
      fmul_in0            : in  unsigned32;
      fmul_in1            : in  unsigned32;
      fmul_out_available  : out std_logic;
      fmul_out_tag        : out tomasulo_fpu_tag_t;
      fmul_out_value      : out unsigned32;
      cdb_writable        : in  std_logic;
      cdb_writable_next   : out std_logic;
      fmul_unit_available : out std_logic);
  end component;


  component FMUL_WITH_FLAG is
    port (
      clk                 : in  std_logic;
      refetch             : in  std_logic;
      fmul_in_available   : in  std_logic;
      fmul_in_tag         : in  tomasulo_fpu_tag_t;
      fmul_in_flag1       : in  unsigned32;
      fmul_in_flag2       : in  unsigned32;
      fmul_in0            : in  unsigned32;
      fmul_in1            : in  unsigned32;
      fmul_out_available  : out std_logic;
      fmul_out_tag        : out tomasulo_fpu_tag_t;
      fmul_out_flag1      : out unsigned32;
      fmul_out_flag2      : out unsigned32;
      fmul_out_value      : out unsigned32;
      cdb_writable        : in  std_logic;
      cdb_writable_next   : out std_logic;
      fmul_unit_available : out std_logic);
  end component;


  component FMUL_STAGE1 is
  port (input1 : in  unsigned32;
        input2 : in  unsigned32;
        hh     : out unsigned (35 downto 0);
        hl1    : out unsigned (35 downto 0);
        hl2    : out unsigned (35 downto 0);
        sumExp : out unsigned32);
  end component;
  component FMUL_STAGE2 is
  port (input1 : in  unsigned32;
        input2 : in  unsigned32;
        hh     : in  unsigned (35 downto 0);
        hl1    : in  unsigned (35 downto 0);
        hl2    : in  unsigned (35 downto 0);
        sumExp : in  unsigned32;
        output : out unsigned32);
  end component;


  component ITOF is
  generic (
    last_unit : boolean);
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
  end component;

  component FTOI is
  generic (
    last_unit : boolean);
  port (
    clk                 : in  std_logic;
    refetch             : in  std_logic;
    ftoi_in_available   : in  std_logic;
    ftoi_in_tag         : in  tomasulo_fpu_tag_t;
    ftoi_in             : in  unsigned32;
    ftoi_out_available  : out std_logic;
    ftoi_out_tag        : out tomasulo_fpu_tag_t;
    ftoi_out_value      : out unsigned32;
    cdb_writable        : in  std_logic;
    cdb_writable_next   : out std_logic;
    ftoi_unit_available : out std_logic
  );
  end component;

  component FINV is
  port (
    clk                 : in std_logic;
    refetch             : in std_logic;
    finv_in_available  : in std_logic;
    finv_in_tag        : in tomasulo_fpu_tag_t;
    finv_in_flag       : in unsigned32;
    finv_in            : in unsigned32;
    finv_out_available : out std_logic;
    finv_out_tag       : out tomasulo_fpu_tag_t;
    finv_out_flag      : out unsigned32;
    finv_out_value     : out unsigned32;
    cdb_writable        : in std_logic;
    cdb_writable_next   : out std_logic;
    finv_unit_available: out std_logic
  );
  end component;

  component FDIV is
  generic (
    last_unit : boolean);
  port (
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
  end component;

  component FSQRT is
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
  end component;

end package kakeudon_fpu;
