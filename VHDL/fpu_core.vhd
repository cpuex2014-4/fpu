library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package kakeudon_fpu is
  component FPUCORE is
    Port(
      clk: in std_logic;
      op : in unsigned(5 downto 0);
      in_1 : in  unsigned(31 downto 0);
      in_2 : in  unsigned(31 downto 0);
      out_1 : out unsigned(31 downto 0);
      cond   : out std_logic
    );
  end component FPUCORE;
end package kakeudon_fpu;

library IEEE;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity FPUCORE is
  Port(
    clk: in std_logic;
    op : in unsigned(5 downto 0);
    in_1 : in  unsigned(31 downto 0);
    in_2 : in  unsigned(31 downto 0);
    out_1 : out unsigned(31 downto 0);
    cond   : out std_logic
  );
end FPUCORE;

architecture Behavior of FPUCORE is
  subtype int32 is std_logic_vector(31 downto 0);
  subtype unsigned32 is unsigned(31 downto 0);

  component FADD is
  port (
    input1 : in  std_logic_vector (31 downto 0);
    input2 : in  std_logic_vector (31 downto 0);
    clk : in std_logic;
    output : out std_logic_vector (31 downto 0)
  );
  end component;

  component FMUL is
  port (
    input1 : in  std_logic_vector (31 downto 0);
    input2 : in  std_logic_vector (31 downto 0);
    clk: in std_logic;
    output : out std_logic_vector (31 downto 0)
  );
  end component;

  component FDIV is
  port (
    input1 : in  std_logic_vector (31 downto 0);
    input2 : in  std_logic_vector (31 downto 0);
    clk: in std_logic;
    output : out std_logic_vector (31 downto 0)
  );
  end component;

  component ITOF is
  Port (input  : in  std_logic_vector(31 downto 0);
        clk    : in std_logic;
        output : out std_logic_vector(31 downto 0));
  end component;

  component FSQRT is
  Port (input  : in  std_logic_vector(31 downto 0);
        clk    : in std_logic;
        output : out std_logic_vector(31 downto 0));
  end component;

  component FTOI is
  Port (input  : in  std_logic_vector(31 downto 0);
        output : out std_logic_vector(31 downto 0));
  end component;

  component FEQ is
  port (input1 : in  std_logic_vector(31 downto 0);
        input2 : in  std_logic_vector(31 downto 0);
        output : out std_logic);
  end component;

  component FLT is
  port (input1 : in  std_logic_vector(31 downto 0);
        input2 : in  std_logic_vector(31 downto 0);
        output : out std_logic);
  end component;

  component FLE is
  port (input1 : in  std_logic_vector(31 downto 0);
        input2 : in  std_logic_vector(31 downto 0);
        output : out std_logic);
  end component;

  signal in1_std, in2_std, neg_in2: int32;
  signal fadd_out, fsub_out, fmul_out, fdiv_out: int32;
  signal itof_out, ftoi_out, fsqrt_out: int32;
  signal feq_out,  flt_out, fle_out: std_logic;
begin
  add: FADD port map (
    input1=>in1_std, input2=> in2_std,
    clk=>clk, output=> fadd_out
  );

  sub: FADD port map (
    input1=>in1_std, input2=> neg_in2,
    clk=>clk, output=> fsub_out
  );

  mul: FMUL port map (
    input1=>in1_std, input2=> in2_std,
    clk=>clk, output=> fmul_out
  );

  div: FDIV port map (
    input1=>in1_std, input2=> in2_std,
    clk=>clk, output=> fdiv_out
  );

  i2f: ITOF port map (
    input=>in1_std, clk => clk, output => itof_out
  );

  f2i: FTOI port map (
    input=>in1_std, output => ftoi_out
  );

  sqrt: FSQRT port map (
    input=>in1_std, output => fsqrt_out
  );

  equal: FEQ port map (
    input1=>in1_std, input2=> in2_std, output=> feq_out
  );

  lessthan: FLT port map (
    input1=>in1_std, input2=> in2_std, output=> flt_out
  );

  lte: FLE port map (
    input1=>in1_std, input2=> in2_std, output=> fle_out
  );


  in1_std <= std_logic_vector(in_1);
  in2_std <= std_logic_vector(in_2);
  neg_in2 <= (not in2_std(31))&in2_std(30 downto 0);


  out_1 <= unsigned(fadd_out)  when op = "000000" else -- fadd  (2 clock)
           unsigned(fsub_out)  when op = "000001" else -- fsub  (2 clock)
           unsigned(fmul_out)  when op = "000010" else -- fmul  (2 clock)
           unsigned(fdiv_out)  when op = "000011" else -- fdiv  (8 clock)
           unsigned(itof_out)  when op = "100000" else -- itof  (5 clock)
           unsigned(ftoi_out)  when op = "100100" else -- ftoi  (1 clock)
           unsigned(fsqrt_out) when op = "000100" else -- fsqrt (5 clock)
           x"00000000";

  cond <= feq_out when op = "110010" else -- feq
          flt_out when op = "110100" else -- flt
          fle_out when op = "110101" else -- fle
          '0';

end Behavior;
