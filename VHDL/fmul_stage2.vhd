library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.kakeudon_fpu.all;
entity FMUL_STAGE2 is
  Port (input1   : in  unsigned (31 downto 0);
        input2   : in  unsigned (31 downto 0);
        hh   : in  unsigned (35 downto 0);
        hl1  : in  unsigned (35 downto 0);
        hl2  : in  unsigned (35 downto 0);
        sumExp : in unsigned (31 downto 0);
        output : out unsigned (31 downto 0));
end entity FMUL_STAGE2;

architecture RTL of FMUL_STAGE2 is
  subtype unsigned_word is unsigned(31 downto 0);

  constant nan32 : unsigned_word := (others=>'1');
  constant zero32 : unsigned_word := (others=>'0');
  constant minusZero : unsigned_word := x"80000000";
  constant inf32 : unsigned_word := x"7f800000";
  constant minusInf : unsigned_word := x"ff800000";

  signal a, b : unsigned_word;
  signal aNaN, bNaN : std_logic;
  signal aZero, bZero : std_logic;
  signal underFlow : std_logic;
  signal aInf, bInf : std_logic;
  signal exp : unsigned_word;
  signal mulFrac: unsigned_word;
  signal signedInf, signedZero : unsigned_word;
  signal ansSign: std_logic;
  signal ansExp:  unsigned (7 downto 0);
  signal ansFrac: unsigned (22 downto 0);
begin

  a <= input1;
  b <= input2;

  aNaN <= 'X' when TO_01(a, 'X')(0) = 'X' else
          '1' when a(30 downto 23) = x"ff" and
                   a(22 downto 0) /= 0 else
          '0';
  bNaN <= 'X' when TO_01(b, 'X')(0) = 'X' else
          '1' when b(30 downto 23) = x"ff" and
                   b(22 downto 0) /= 0 else
          '0';
  aInf <= 'X' when TO_01(a, 'X')(0) = 'X' else
          '1' when a(30 downto 23) = x"ff" and
                   a(22 downto 0) = 0 else
          '0';
  bInf <= 'X' when TO_01(b, 'X')(0) = 'X' else
          '1' when b(30 downto 23) = x"ff" and
                   b(22 downto 0) = 0 else
          '0';

  aZero <= 'X' when TO_01(a, 'X')(0) = 'X' else
           '1' when a(30 downto 23) = x"00" else '0';
  bZero <= 'X' when TO_01(b, 'X')(0) = 'X' else
           '1' when b(30 downto 23) = x"00" else '0';





  mulFrac <= hh(31 downto 0) +
             ("00000000000"&hl1(31 downto 11)) +
             ("00000000000"&hl2(31 downto 11)) +
             x"2";


  ansSign <= a(31) xor b(31);

  signedInf  <= (others => 'X') when TO_X01(ansSign)='X' else
                inf32  when ansSign='0' else
                minusInf;
  signedZero <= (others => 'X') when TO_X01(ansSign)='X' else
                zero32 when ansSign='0' else
                minusZero;




  underFlow <= 'X' when TO_01(sumExp, 'X')(0) = 'X' or
                        TO_X01(mulFrac(25)) = 'X' else
               '1' when (((sumExp) <= x"0000007e") and (mulFrac(25) = '1')) or
                        (((sumExp) <= x"0000007f") and (mulFrac(25) = '0')) else
               '0';

  exp  <= (others => 'X') when TO_X01(mulFrac(25)) = 'X' else
          sumExp - x"7e" when mulFrac(25) = '1' else
          sumExp - x"7f";

  ansExp <= exp(7 downto 0);

  ansFrac <= (others => 'X') when TO_X01(mulFrac(25)) = 'X' else
             mulFrac(24 downto 2) when mulFrac(25) = '1' else
             mulFrac(23 downto 1);



  output <= (others => 'X') when TO_X01(aNaN) = 'X' or TO_X01(bNaN) = 'X' or
                                 TO_X01(aZero) = 'X' or TO_X01(bZero) = 'X' or
                                 TO_X01(aInf) = 'X' or TO_X01(bInf) = 'X' or
                                 TO_X01(underFlow) = 'X' or
                                 TO_01(exp, 'X')(0) = 'X' or
                                 TO_01(ansExp, 'X')(0) = 'X' else

            nan32      when aNaN   = '1' or  bNaN  = '1'  or
                            (aZero = '1' and bInf  = '1') or
                            (aInf  = '1' and bZero = '1') else

            signedInf  when aInf = '1' or bInf = '1' or
                            (underFlow = '0' and exp >= x"ff") else

            signedZero when aZero  = '1' or  bZero = '1'  or
                            underFlow = '1' or
                            ansExp = x"00" else


            ansSign&ansExp&ansFrac;

end architecture RTL;
