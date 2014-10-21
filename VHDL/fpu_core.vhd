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

architecture Behavior of top is
  subtype int32 is std_logic_vector(31 downto 0);
  subtype unsigned32 is unsigned(31 downto 0);

  component FADD is
  port (
    input1 : in  std_logic_vector (31 downto 0);
    input2 : in  std_logic_vector (31 downto 0);
    output : out std_logic_vector (31 downto 0)
  );
  end component;

  component FMUL is
  port (
    input1 : in  std_logic_vector (31 downto 0);
    input2 : in  std_logic_vector (31 downto 0);
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
  signal feq_out, flt_out: std_logic;
begin
  fadd: FADD port map (
    input1=>in_1, input2=> in_2, output=> fadd_out
  );
  fmul: FMUL port map (
    input1=>in_1, input2=> in_2, output=> fmul_out
  );

  feq: FEQ port map (
    input1=>in_1, input2=> in_2, output=> feq_out
  );
  flt: FLT port map (
    input1=>in_1, input2=> in_2, output=> flt_out
  );



  fpu: process(clk)
  begin
    if rising_edge(clk) then
      case op is
        when "000000" => --fadd
          out_1 <= unsigned(fadd_out);
          cond <= '0';
        when "000010" => --fmul
          out_1 <= unsigned(fmil_out);
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
