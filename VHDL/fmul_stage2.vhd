library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.kakeudon_fpu.all;
entity FMUL_STAGE2 is
  Port (input1   : in  std_logic_vector (31 downto 0);
        input2   : in  std_logic_vector (31 downto 0);
        hh   : in  std_logic_vector (35 downto 0);
        hl1  : in  std_logic_vector (35 downto 0);
        hl2  : in  std_logic_vector (35 downto 0);
        sumExp : in std_logic_vector (31 downto 0);
        output : out std_logic_vector (31 downto 0));
end entity FMUL_STAGE2;

architecture RTL of FMUL_STAGE2 is
  subtype int32 is std_logic_vector(31 downto 0);

  constant nan32 : int32 := (others=>'1');
  constant zero32 : int32 := (others=>'0');
  constant minusZero : int32 := x"80000000";
  constant inf32 : int32 := x"7f800000";
  constant minusInf : int32 := x"ff800000";

  signal a, b : int32;
  signal aNaN, bNaN : std_logic;
  signal aZero, bZero : std_logic;
  signal underFlow : std_logic;
  signal aInf, bInf : std_logic;
  signal exp : int32;
  signal mulFrac: int32;
  signal signedInf, signedZero : int32;
  signal ansSign: std_logic;
  signal ansExp:  std_logic_vector (7 downto 0);
  signal ansFrac: std_logic_vector (22 downto 0);
begin

  a <= input1;
  b <= input2;

  aNaN <= '1' when a(30 downto 23) = x"ff" and
                   or_reduce(a(22 downto 0)) = '1' else
          '0';
  bNaN <= '1' when b(30 downto 23) = x"ff" and
                   or_reduce(b(22 downto 0)) = '1' else
          '0';
  aInf <= '1' when a(30 downto 23) = x"ff" and
                   or_reduce(a(22 downto 0)) = '0' else
          '0';
  bInf <= '1' when b(30 downto 23) = x"ff" and
                   or_reduce(b(22 downto 0)) = '0' else
          '0';

  aZero <= '1' when a(30 downto 23) = x"00" else '0';
  bZero <= '1' when b(30 downto 23) = x"00" else '0';





  mulFrac <= hh(31 downto 0) +
             ("00000000000"&hl1(31 downto 11)) +
             ("00000000000"&hl2(31 downto 11)) +
             x"2";


  ansSign <= a(31) xor b(31);

  signedInf  <= inf32  when ansSign='0' else
                minusInf;
  signedZero <= zero32 when ansSign='0' else
                minusZero;




  underFlow <= '1' when (((sumExp) <= x"0000007e") and (mulFrac(25) = '1')) or
                        (((sumExp) <= x"0000007f") and (mulFrac(25) = '0')) else
               '0';

  exp  <= sumExp - x"7e" when mulFrac(25) = '1' else
          sumExp - x"7f";

  ansExp <= exp(7 downto 0);

  ansFrac <= mulFrac(24 downto 2) when mulFrac(25) = '1' else
             mulFrac(23 downto 1);



  output <= nan32      when aNaN   = '1' or  bNaN  = '1'  or
                            (aZero = '1' and bInf  = '1') or
                            (aInf  = '1' and bZero = '1') else

            signedInf  when aInf = '1' or bInf = '1' or
                            (underFlow = '0' and exp >= x"ff") else

            signedZero when aZero  = '1' or  bZero = '1'  or
                            underFlow = '1' or
                            ansExp = x"00" else


            ansSign&ansExp&ansFrac;

end architecture RTL;
