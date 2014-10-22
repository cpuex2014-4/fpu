library IEEE;
use IEEE.std_logic_unsigned.all;
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

  signal fadd_out, fmul_out: int32;
  signal in1_std, in2_std : int32;
  signal feq_out, flt_out: std_logic;
begin
  add: FADD port map (
    input1=>in1_std, input2=> in2_std,
    clk=>clk, output=> fadd_out
  );
  mul: FMUL port map (
    input1=>in1_std, input2=> in2_std,
    clk=>clk, output=> fmul_out
  );

  equal: FEQ port map (
    input1=>in1_std, input2=> in2_std, output=> feq_out
  );
  lessthan: FLT port map (
    input1=>in1_std, input2=> in2_std, output=> flt_out
  );

  in1_std <= std_logic_vector(in_1);
  in2_std <= std_logic_vector(in_2);


  fpu: process(clk)
  begin
    if rising_edge(clk) then
      case op is
        when "000000" => --fadd
          out_1 <= unsigned(fadd_out);
          cond <= '0';
        when "000010" => --fmul
          out_1 <= unsigned(fmul_out);
          cond <= '0';
        when "110010" => --fequal
          out_1 <= x"00000000";
          cond <= feq_out;
        when "110100" => --flt
          out_1 <= x"00000000";
          cond <= flt_out;
        when others =>
          out_1 <= x"00000000";
          cond <= '0';
      end case;
    end if;
  end process;
end Behavior;
