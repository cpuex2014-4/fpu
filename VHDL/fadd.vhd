library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.kakeudon_fpu.all;

-- FAdd
entity FADD is
  port (
    input1 : in  unsigned (31 downto 0);
    input2 : in  unsigned (31 downto 0);
    clk: in std_logic;
    output : out unsigned (31 downto 0)
    );
end FADD;

-- sign: 31
-- exp : 30 downto 23  ( 8bit)
-- frac: 22 downto 0
architecture RTL of FADD is
  constant ff32  : unsigned_word := (23 downto 0 => '0')&x"ff"; --256
  constant nan32 : unsigned_word := (others=>'1');
  constant zero32 : unsigned_word := (others=>'0');
  constant minusZero : unsigned_word := x"80000000";
  constant inf32 : unsigned_word := x"7f800000";
  constant minusInf : unsigned_word := x"ff800000";
  function getFrac (a : unsigned_word)
    return unsigned is
  begin
    return (8 downto 0 => '0')&a(22 downto 0);
  end getFrac;

  function getExp (a : unsigned_word)
    return unsigned is
  begin
    return (23 downto 0 => '0')&a(30 downto 23);
  end getExp;

  function getSign (a : unsigned_word)
    return std_logic is
  begin
    return a (31);
  end getSign;

  function isNaN (a : unsigned_word)
    return std_logic is
  begin
    if getExp(a) = ff32 and getFrac(a) /= zero32 then
      return '1';
    else
      return '0';
    end if;
  end isNan;

  function isZero (a : unsigned_word)
    return std_logic is
  begin
    if getExp(a) = zero32 and getFrac(a) = zero32 then
      return '1';
    else
      return '0';
    end if;
  end isZero;

  function isInf (a : unsigned_word)
    return std_logic is
  begin
    if getExp(a) = ff32 and getFrac(a) = zero32 then
      return '1';
    else
      return '0';
    end if;
  end isInf;

  function ops (a : unsigned_word;b : unsigned_word)
    return unsigned_word is
  begin
    if isNaN(a)='1' then
      return nan32;
    elsif (isInf(a)='1' and isInf(b)='1') and (getSign(a) /= getSign(b)) then
      return nan32;
    elsif isInf(a)='1' then
      if getSign(a)='1' then
        return minusInf;
      else
        return inf32;
      end if;
    elsif isInf(b)='1' then
      if getSign(b)='1' then
        return minusInf;
      else
        return inf32;
      end if;
    elsif (isZero(a)='1' and isZero(b)='1') then
      if getSign(a)='1' and getSign(b)='1' then
        return minusZero;
      else
        return zero32;
      end if;
    else
      if isZero(a)='1' then
        return b;
      elsif isZero(b)='1' then
        return a;
      end if;
    end if;
    return x"DEADBEEF";
  end ops;

  function log2 (frac : unsigned_word)
    return unsigned_word is
    variable i : integer := 31;
  begin
    while (frac(i) = '0' and i /= 0) loop
      i := i-1;
    end loop;
    return to_unsigned(i,32);
  end;

  function loadFrac (a: unsigned_word; b: unsigned_word)
    return unsigned is
    variable r : unsigned_word;
  begin
    r := a;
    r(22 downto 0) := b(22 downto 0);
    return r;
  end loadFrac;

  function loadExp (a: unsigned_word; b: unsigned_word)
    return unsigned is
    variable r : unsigned_word;
  begin
    r := a;
    r(30 downto 23) := b(7 downto 0);
    return r;
  end loadExp;

  function loadSign (a: unsigned_word; b: std_logic)
    return unsigned is
    variable r : unsigned_word;
  begin
    r := a;
    r(31) := b;
    return r;
  end loadSign;
  function faddMain1 (input1: unsigned_word; input2: unsigned_word)
    return unsigned is
    variable tmp1 : integer;
    variable d  : unsigned_word;
    variable a : unsigned_word := (others=>'0');
    variable b : unsigned_word := (others=>'0');
    variable na : unsigned_word;
    variable nb : unsigned_word;
    variable flg : std_logic := '0';
    variable frac: unsigned_word := (others=>'0');

  begin
    if TO_01(input1, 'X')(0) = 'X' or TO_01(input2, 'X')(0) = 'X' then
      return (31 downto 0 => 'X');
    end if;

    -- |a| >= |b|

    if input1(30 downto 0) >= input2(30 downto 0) then
      a := input1;
      b := input2;
    else
      a := input2;
      b := input1;
    end if;

    if getExp(b) = zero32 then
      if getSign(b) = '1' then
        b := minusZero;
      else
        b := zero32;
      end if;
    end if;
    -- 共通

    na:= shift_left(getFrac(a), 3);
    na(26) := '1';

    nb:= shift_left(getFrac(b), 3);
    nb(26) := '1';

    d := getExp(a) - getExp(b);

    if d >= x"20" then
      d := x"00000000";
    end if;

    -- (30 downto 0) is for ghdl
    if d = 0 then
      flg := '0';
    else
      tmp1 := to_integer(d(30 downto 0))-1;
      if nb(tmp1 downto 0) = 0 then
        flg := '0';
      else
        flg := '1';
      end if;
    end if;

    nb := shift_right(nb, to_integer(unsigned(d)));

    nb(0) := nb(0) or flg;

    if (getSign(a) = getSign(b)) then
      frac := na + nb;
    else
      frac := na - nb;
    end if;

    return frac;
  end faddMain1;

  function faddMain2 (input1: unsigned_word; input2: unsigned_word; frac1: unsigned_word)
    return unsigned is
    variable a : unsigned_word := (others=>'0');
    variable b : unsigned_word := (others=>'0');
    variable frac: unsigned_word := (others=>'0');
    variable exp:  unsigned_word := (others=>'0');
    variable d  : unsigned_word;
    variable ulp:   std_logic := '0';
    variable guard: std_logic := '0';
    variable round: std_logic := '0';
    variable stick: std_logic := '0';
    variable tmp:   std_logic := '0';
    variable ans : unsigned_word := (others=>'0');
    variable t:    unsigned_word := (others=>'0');
  begin
    if TO_01(input1, 'X')(0) = 'X' or TO_01(input2, 'X')(0) = 'X' or
       TO_01(frac1, 'X')(0) = 'X' then
      return (31 downto 0 => 'X');
    end if;

    -- 共通部分 --
    frac := frac1;
    if input1(30 downto 0) >= input2(30 downto 0) then
      a := input1;
      b := input2;
    else
      a := input2;
      b := input1;
    end if;

    if getExp(a) = zero32 then
      if getSign(a) = '1' then
        return minusZero;
      else
        return zero32;
      end if;
    end if;

    if getExp(b) = zero32 then
      if getSign(b) = '1' then
        b := minusZero;
      else
        b := zero32;
      end if;
    end if;

    if (getExp(a) = zero32 or getExp(a) = ff32 or getExp(b) = zero32 or getExp(b) = ff32) then
      -- NaN or INF
      return ops(a, b);
    end if;


    d := getExp(a) - getExp(b);

    if d >= x"20" then
      return a;
    end if;

    t := log2(frac);
    if frac = 0 then
      return zero32;
    elsif t < 26 then
      frac := shift_left(frac, 26-to_integer(signed(t)));
      if (getExp(a) <= (26-t)) then
        if getSign(a)='1' then
          return minusZero;
        else
          return zero32;
        end if;
      else
        exp := getExp(a);
        exp := exp + t;
        exp := exp -26;
        ans := loadExp(ans, exp);
      end if;
    elsif t > 26 then
      -- t==27
      tmp := frac(0) or frac(1);
      frac := "0"&frac(31 downto 1);
      frac(0) := tmp;
      ans := loadExp(ans, (x"000000"&a(30 downto 23))+1);
    else
      ans := loadExp(ans, (x"000000"&a(30 downto 23)));
    end if;


    ulp   := frac(3);
    guard := frac(2);
    round := frac(1);
    stick := frac(0);

    if guard='1' and (ulp='1' or round='1' or stick='1') then
      frac := frac + 8;
      if frac(27)='1' then
        ans := loadExp(ans, getExp(ans)+1);
      end if;
    end if;

    if getExp(ans) >= ff32 then

      if getSign(a) = '1' then
        return x"ff800000";
      else
        return x"7f800000";
      end if;
    end if;

    ans := loadFrac(ans, shift_right(frac, 3));
    ans := loadSign(ans, getSign(a));

    return ans;
  end faddMain2;
  signal input1_1, input2_1, frac1 : unsigned_word;
begin
  proc:process(clk)
  begin
    if rising_edge(clk) then
      input1_1 <= input1;
      input2_1 <= input2;
      frac1 <= faddMain1(input1, input2);
    end if;
  end process;
  output <= faddMain2(input1_1, input2_1, frac1);
end RTL;
