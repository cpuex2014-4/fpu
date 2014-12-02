library IEEE;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use work.kakeudon_fpu.all;

-- FAdd
entity FADD is
  port (
    input1 : in  std_logic_vector (31 downto 0);
    input2 : in  std_logic_vector (31 downto 0);
    clk: in std_logic;
    output : out std_logic_vector (31 downto 0)
    );
end FADD;

-- sign: 31
-- exp : 30 downto 23  ( 8bit)
-- frac: 22 downto 0
architecture RTL of FADD is
  constant ff32  : int32 := (23 downto 0 => '0')&x"ff"; --256
  constant nan32 : int32 := (others=>'1');
  constant zero32 : int32 := (others=>'0');
  constant minusZero : int32 := x"80000000";
  constant inf32 : int32 := x"7f800000";
  constant minusInf : int32 := x"ff800000";
  function getFrac (a : int32)
    return std_logic_vector is
  begin
    return (8 downto 0 => '0')&a(22 downto 0);
  end getFrac;

  function getExp (a : int32)
    return std_logic_vector is
  begin
    return (23 downto 0 => '0')&a(30 downto 23);
  end getExp;

  function getSign (a : int32)
    return std_logic is
  begin
    return a (31);
  end getSign;

  function isNaN (a : int32)
    return std_logic is
  begin
    if getExp(a) = ff32 and getFrac(a) /= zero32 then
      return '1';
    else
      return '0';
    end if;
  end isNan;

  function isZero (a : int32)
    return std_logic is
  begin
    if getExp(a) = zero32 and getFrac(a) = zero32 then
      return '1';
    else
      return '0';
    end if;
  end isZero;

  function isInf (a : int32)
    return std_logic is
  begin
    if getExp(a) = ff32 and getFrac(a) = zero32 then
      return '1';
    else
      return '0';
    end if;
  end isInf;

  function ops (a : int32;b : int32)
    return int32 is
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

  function log2 (frac : int32)
    return int32 is
    variable i : integer := 31;
  begin
    while (frac(i) = '0' and i /= 0) loop
      i := i-1;
    end loop;
    return conv_std_logic_vector(i,32);
  end;

  function loadFrac (a: int32; b: int32)
    return std_logic_vector is
    variable r : int32;
  begin
    r := a;
    r(22 downto 0) := b(22 downto 0);
    return r;
  end loadFrac;

  function loadExp (a: int32; b: int32)
    return std_logic_vector is
    variable r : int32;
  begin
    r := a;
    r(30 downto 23) := b(7 downto 0);
    return r;
  end loadExp;

  function loadSign (a: int32; b: std_logic)
    return std_logic_vector is
    variable r : int32;
  begin
    r := a;
    r(31) := b;
    return r;
  end loadSign;
  function faddMain1 (input1: int32; input2: int32)
    return std_logic_vector is
    variable tmp1 : integer;
    variable d  : int32;
    variable a : int32 := (others=>'0');
    variable b : int32 := (others=>'0');
    variable na : int32;
    variable nb : int32;
    variable flg : std_logic := '0';
    variable frac: int32 := (others=>'0');

  begin
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

    na:= shl(getFrac(a),x"3");
    na(26) := '1';

    nb:= shl(getFrac(b),x"3");
    nb(26) := '1';

    d := getExp(a) - getExp(b);

    if d >= x"20" then
      d := x"00000000";
    end if;

    -- (30 downto 0) is for ghdl
    tmp1 := conv_integer(d(30 downto 0)) -1;
    flg := or_reduce(nb(tmp1 downto 0));

    nb := shr(nb, d);

    nb(0) := nb(0) or flg;

    if (getSign(a) = getSign(b)) then
      frac := na + nb;
    else
      frac := na - nb;
    end if;

    return frac;
  end faddMain1;

  function faddMain2 (input1: int32; input2: int32; frac1: int32)
    return std_logic_vector is
    variable a : int32 := (others=>'0');
    variable b : int32 := (others=>'0');
    variable frac: int32 := (others=>'0');
    variable exp:  int32 := (others=>'0');
    variable d  : int32;
    variable ulp:   std_logic := '0';
    variable guard: std_logic := '0';
    variable round: std_logic := '0';
    variable stick: std_logic := '0';
    variable tmp:   std_logic := '0';
    variable ans : int32 := (others=>'0');
        variable t:    int32 := (others=>'0');
  begin

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
      frac := shl(frac, 26-t);
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

    ans := loadFrac(ans, shr(frac, x"3"));
    ans := loadSign(ans, getSign(a));

    return ans;
  end faddMain2;
  signal input1_1, input2_1, frac1 : int32;
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
