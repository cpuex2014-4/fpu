library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
package kakeudon_fpu is
  subtype unsigned32 is unsigned(31 downto 0);
  subtype tomasulo_fpu_tag_t is unsigned(4 downto 0);
  component FADD_OLD is
  Port (
    input1 : in unsigned32;
    input2 : in unsigned32;
    clk: in std_logic;
    output : out unsigned32);
  end component;

   component FADD is
    generic (
      last_unit : boolean);
    Port (
      clk : in std_logic;
      refetch : in std_logic;
      fadd_in_available : in std_logic;
      fadd_in_tag : in tomasulo_fpu_tag_t;
      fadd_in0    : in  unsigned (31 downto 0);
      fadd_in1    : in  unsigned (31 downto 0);
      fadd_out_available : out std_logic;
      fadd_out_tag : out tomasulo_fpu_tag_t;
      fadd_out_value   : out  unsigned (31 downto 0);
      cdb_writable : in std_logic;
      cdb_writable_next : out std_logic;
      fadd_unit_available : out std_logic);
  end component;

  component FADD_WITH_FLAG is
  Port (
    clk:     in std_logic;
    refetch : in std_logic;
    fadd_in_available : in std_logic;
    fadd_in_tag  : in tomasulo_fpu_tag_t;
    fadd_in_flag : in unsigned(1 downto 0);
    fadd_in0 : in unsigned32;
    fadd_in1 : in unsigned32;
    fadd_out_available : out std_logic;
    fadd_out_tag  : out tomasulo_fpu_tag_t;
    fadd_out_flag : out unsigned(1 downto 0);
    fadd_out_value : out unsigned32;
    cdb_writable : in std_logic;
    cdb_writable_next : out std_logic;
    fadd_unit_available : out std_logic);
  end component;

  component FMUL_OLD is
  Port (input1   : in  unsigned (31 downto 0);
        input2   : in  unsigned (31 downto 0);
        clk: in std_logic;
        output : out unsigned (31 downto 0));
  end component;

  component FMUL is
    generic (
      last_unit : boolean);
    Port (
      clk : in std_logic;
      refetch : in std_logic;
      fmul_in_available : in std_logic;
      fmul_in_tag : in tomasulo_fpu_tag_t;
      fmul_in0    : in  unsigned (31 downto 0);
      fmul_in1    : in  unsigned (31 downto 0);
      fmul_out_available : out std_logic;
      fmul_out_tag : out tomasulo_fpu_tag_t;
      fmul_out_value   : out  unsigned (31 downto 0);
      cdb_writable : in std_logic;
      cdb_writable_next : out std_logic;
      fmul_unit_available : out std_logic);
  end component;


  component FMUL_WITH_FLAG is
    generic (
      last_unit : boolean);
    Port (
      clk : in std_logic;
      refetch : in std_logic;
      fmul_in_available : in std_logic;
      fmul_in_tag : in tomasulo_fpu_tag_t;
      fmul_in_flag: in unsigned(1 downto 0);
      fmul_in0    : in  unsigned (31 downto 0);
      fmul_in1    : in  unsigned (31 downto 0);
      fmul_out_available : out std_logic;
      fmul_out_tag  : out tomasulo_fpu_tag_t;
      fmul_out_flag : out unsigned(1 downto 0);
      fmul_out_value   : out  unsigned (31 downto 0);
      cdb_writable : in std_logic;
      cdb_writable_next : out std_logic;
      fmul_unit_available : out std_logic);
  end component;


  component FMUL_STAGE1 is
  Port (input1   : in  unsigned32;
        input2   : in  unsigned32;
        hh   : out  unsigned (35 downto 0);
        hl1  : out  unsigned (35 downto 0);
        hl2  : out  unsigned (35 downto 0);
        sumExp : out unsigned32);
  end component;
  component FMUL_STAGE2 is
  Port (input1   : in  unsigned32;
        input2   : in  unsigned32;
        hh   : in  unsigned (35 downto 0);
        hl1  : in  unsigned (35 downto 0);
        hl2  : in  unsigned (35 downto 0);
        sumExp : in unsigned32;
        output : out unsigned32);
  end component;


  component ITOF is
  generic (
    last_unit : boolean);
  port (
    clk                : in std_logic;
    refetch            : in std_logic;
    itof_in_available  : in std_logic;
    itof_in_tag        : in tomasulo_fpu_tag_t;
    itof_in            : in unsigned32;
    itof_out_available : out std_logic;
    itof_out_tag       : out tomasulo_fpu_tag_t;
    itof_out_value     : out unsigned32;
    cdb_writable       : in std_logic;
    cdb_writable_next  : out std_logic;
    itof_unit_available: out std_logic
  );
  end component;

  component ITOF_OLD is
  Port (input  : in  unsigned32;
        clk : in std_logic;
        output : out unsigned32);
  end component;

  component FTOI is
  Port (input  : in  unsigned32;
        output : out unsigned32);
  end component;


  component FINV is
  Port (input  : in  unsigned32;
        clk    : in  std_logic;
        output : out unsigned32);
  end component;

  component FDIV is
  Port (input1 : in  unsigned32;
        input2 : in  unsigned32;
        clk : in std_logic;
        output : out unsigned32);
  end component FDIV;

  component FSQRT is
  Port (input  : in  unsigned32;
        clk    : in  std_logic;
        output : out unsigned32);
  end component;

end package kakeudon_fpu;
