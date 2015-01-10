library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.kakeudon_fpu.all;

-- FAdd
entity FADD is
  port (
    input1 : in  unsigned32;
    input2 : in  unsigned32;
    clk:     in std_logic;
    output : out unsigned32
  );
end FADD;

architecture RTL of FADD is
  type reg_type is record
    -- stage1 --
    a_1    : unsigned32;
    na     : unsigned32;
    nb     : unsigned32;
    sign_1 : std_logic;
    exp_1  : unsigned32;
    opFlg_1: unsigned( 1 downto 0);
    isAdd  : std_logic;
    ret_a_1: std_logic;
    -- stage2 --
    a_2    : unsigned32;
    sign_2 : std_logic;
    exp_2  : unsigned32;
    frac_2 : unsigned32;
    ret_a_2: std_logic;
    opFlg_2: unsigned ( 1 downto 0);
  end record;

  signal r, rin : reg_type;

  -- "00" - normal
  -- "01" - zero
  -- "10" - Inf
  -- "11" - NaN
  function ops (a : unsigned32; b : unsigned32)
    return unsigned is
  begin
    if a(30 downto 23) = x"ff" and
       a(22 downto 0) /= (22 downto 0 => '0') then
      return "11";  -- a is NaN
    elsif a(30 downto 23)=x"ff" and
          b(30 downto 23)=x"ff" and
          a(31)/=b(31) then
      return "11";  -- (+Inf) + (-Inf) = NaN
    elsif a(30 downto 23)=x"ff" then
      return "10";  -- a is Inf
    elsif a(30 downto 23)="0" then
      return "01";  -- a is zero
    else
      return "00";
    end if;
  end ops;

  function log2 (frac : unsigned (31 downto 0))
    return unsigned is
    variable x : integer := 0;
  begin
    for i in 0 to 31 loop
      if frac(i) = '1' then
        x := i;
      end if;
    end loop;
    return to_unsigned(x, 32);
  end log2;

begin

  comb : process (input1, input2, r)
    variable v : reg_type;
    -- stage 1 --
    variable a, b    : unsigned32;
    variable na, nb  : unsigned32;
    variable d       : unsigned32;
    variable flg     : std_logic;
    variable isAdd   : std_logic;
    variable tmp1    : integer;
    variable opFlg_1 : unsigned ( 1 downto 0);
    variable ret_a   : std_logic;
    -- stage 2 --
    variable sign_2  : std_logic;
    variable exp_2   : unsigned32;
    variable lg2     : unsigned32;
    variable fracSum : unsigned32;
    variable tmp2    : std_logic;
    variable opFlg_2 : unsigned ( 1 downto 0);
    variable ret_a_2 : std_logic;
    -- stage 3 --
    variable sign_3 : std_logic;
    variable exp_3  : unsigned32;
    variable frac_3 : unsigned32;
    variable opFlg_3: unsigned ( 1 downto 0);
    variable ans    : unsigned32;
    variable ulp    : std_logic;
    variable guard  : std_logic;
    variable round  : std_logic;
    variable stick  : std_logic;
  begin
    v := r;

    ----- stage 1 -----

    if input1(30 downto 0) >= input2(30 downto 0) then
      a := input1; b := input2;
    else
      a := input2; b := input1;
    end if;

    if b(30 downto 23) = x"00" then
      ret_a := '1';
    else
      ret_a := '0';
    end if;

    d := (x"000000"&a(30 downto 23)) - (x"000000"&b(30 downto 23));

    na  := "000001" & a(22 downto 0) & "000";
    nb  := "000001" & b(22 downto 0) & "000";

    if d = 0 then
      flg := '0';
    else
      if d>=x"20" then
        tmp1 := 31;
      else
        tmp1 := to_integer(d(30 downto 0))-1;
      end if;
      if nb(tmp1 downto 0) = 0 then
        flg := '0';
      else
        flg := '1';
      end if;
    end if;

    opFlg_1 := ops (a, b);

    nb  := shift_right(nb, to_integer(unsigned(d)));

    nb(0) := nb(0) or flg;

    if a(31) = b(31) then
      isAdd := '1';
    else
      isAdd := '0';
    end if;
    v.a_1    := a;
    v.na     := na;
    v.nb     := nb;
    v.sign_1 := a(31);
    v.exp_1  := x"000000" & a(30 downto 23);
    v.opFlg_1:= opFlg_1;
    v.isAdd  := isAdd;
    v.ret_a_1:= ret_a;


    ----- stage 2 -----

    sign_2  := r.sign_1;
    exp_2   := r.exp_1;
    opFlg_2 := r.opFlg_1;
    ret_a_2 := r.ret_a_1;

    if r.isAdd = '1' then
      fracSum := r.na + r.nb;
    else
      fracSum := r.na - r.nb;
    end if;

    lg2  := log2(fracSum);

    if lg2 < 26 then
      fracSum := shift_left(fracSum, 26-to_integer(signed(lg2)));
      if exp_2 <= 26-lg2 and opFlg_2 = "00" and ret_a_2 = '0' then
        opFlg_2 := "01";  -- UnderFlow
      else
        exp_2 := exp_2 + (lg2-26);
      end if;
    elsif lg2 > 26 then -- lg2 = 27
      tmp2 := fracSum(0) or fracSum(1);
      fracSum    := "0" & fracSum(31 downto 1);
      fracSum(0) := tmp2;
      exp_2      := exp_2 + 1;
    else
      exp_2 := r.exp_1;
    end if;

    v.sign_2 := sign_2;
    v.exp_2  := exp_2;
    v.frac_2 := fracSum;
    v.opFlg_2:= opFlg_2;
    v.a_2    := r.a_1;
    v.ret_a_2:= ret_a_2;


    ----- stage 3 -----

    sign_3 := r.sign_2;
    exp_3  := r.exp_2;
    frac_3 := r.frac_2;
    opFlg_3:= r.opFlg_2;
    ulp    := r.frac_2(3);
    guard  := r.frac_2(2);
    round  := r.frac_2(1);
    stick  := r.frac_2(0);

    if guard='1' and
      (ulp='1' or round='1' or stick='1') then
      frac_3 := frac_3 + 8;
      if frac_3(27)='1' then
        exp_3 := exp_3 + 1;
      end if;
    end if;

    if opFlg_3 = "11" then    -- NaN
      ans := (others => '1');
    elsif opFlg_3 = "10" then -- Inf
      ans := sign_3 & x"ff" & (22 downto 0 => '0');
    elsif opFlg_3 = "01" then -- Zero
      ans := sign_3 & (30 downto 0 => '0');
    elsif r.ret_a_2 = '1' then
      ans := r.a_2;
    elsif exp_3 >= x"ff" then -- OverFlow
      ans := sign_3 & x"ff" & (22 downto 0 => '0');
    else
      ans := sign_3 & exp_3(7 downto 0) & frac_3(25 downto 3);
    end if;

    --

    output <= ans;
    rin <= v;

  end process;


  reg : process (clk)
  begin
    if rising_edge(clk) then
      r <= rin;
    end if;
  end process;

end architecture;
