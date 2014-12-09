library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
package kakeudon_fpu is
  subtype unsigned_word is unsigned(31 downto 0);

  component FADD is
  Port (
    input1 : in unsigned_word;
    input2 : in unsigned_word;
    clk: in std_logic;
    output : out unsigned_word);
  end component;

  component FMUL is
  Port (
      input1 : in unsigned_word;
      input2 : in unsigned_word;
      clk: in std_logic;
      output : out unsigned_word);
  end component;
  component FMUL_STAGE1 is
  Port (input1   : in  unsigned_word;
        input2   : in  unsigned_word;
        hh   : out  unsigned (35 downto 0);
        hl1  : out  unsigned (35 downto 0);
        hl2  : out  unsigned (35 downto 0);
        sumExp : out unsigned_word);
  end component;
  component FMUL_STAGE2 is
  Port (input1   : in  unsigned_word;
        input2   : in  unsigned_word;
        hh   : in  unsigned (35 downto 0);
        hl1  : in  unsigned (35 downto 0);
        hl2  : in  unsigned (35 downto 0);
        sumExp : in unsigned_word;
        output : out unsigned_word);
  end component;

  component ITOF is
  Port (input  : in  unsigned_word;
        clk : in std_logic;
        output : out unsigned_word);
  end component;

  component FTOI is
  Port (input  : in  unsigned_word;
        output : out unsigned_word);
  end component;


  component FINV is
  Port (input  : in  unsigned_word;
        clk    : in  std_logic;
        output : out unsigned_word);
  end component;

  component FDIV is
  Port (input1 : in  unsigned_word;
        input2 : in  unsigned_word;
        clk : in std_logic;
        output : out unsigned_word);
  end component FDIV;

  component FSQRT is
  Port (input  : in  unsigned_word;
        clk    : in  std_logic;
        output : out unsigned_word);
  end component;

end package kakeudon_fpu;
