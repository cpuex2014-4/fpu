library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

package kakeudon_fpu is
  subtype int32 is std_logic_vector(31 downto 0);

  -- FADD --
  component FADD is
  Port (
    input1 : in int32;
    input2 : in int32;
    clk: std_logic;
    output : out int32);
  end component;

  -- FMUL --
  component FMUL is
  Port (
      input1 : in int32;
      input2 : in int32;
      clk: std_logic;
      output : out int32);
  end component;
  component FMUL_STAGE1 is
  Port (input1   : in  std_logic_vector (31 downto 0);
        input2   : in  std_logic_vector (31 downto 0);
        hh   : out  std_logic_vector (35 downto 0);
        hl1  : out  std_logic_vector (35 downto 0);
        hl2  : out  std_logic_vector (35 downto 0);
        sumExp : out std_logic_vector (31 downto 0));
  end component;
  component FMUL_STAGE2 is
  Port (input1   : in  std_logic_vector (31 downto 0);
        input2   : in  std_logic_vector (31 downto 0);
        hh   : in  std_logic_vector (35 downto 0);
        hl1  : in  std_logic_vector (35 downto 0);
        hl2  : in  std_logic_vector (35 downto 0);
        sumExp : in std_logic_vector (31 downto 0);
        output : out std_logic_vector (31 downto 0));
  end component;

  component ITOF is
  Port (input  : in  std_logic_vector(31 downto 0);
        clk : in std_logic;
        output : out std_logic_vector(31 downto 0));
  end component;

  component FTOI is
  Port (input  : in  std_logic_vector(31 downto 0);
        output : out std_logic_vector(31 downto 0));
  end component;


  component FINV is
  Port (input  : in  std_logic_vector(31 downto 0);
        clk    : in  std_logic;
        output : out std_logic_vector(31 downto 0));
  end component;

  component FSQRT is
  Port (input  : in  std_logic_vector(31 downto 0);
        clk    : in  std_logic;
        output : out std_logic_vector(31 downto 0));
  end component;

end package kakeudon_fpu;