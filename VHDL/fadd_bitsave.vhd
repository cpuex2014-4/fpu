-- itofの部品のためのfadd
-- tagだけではなくて、(tag, saved_sign)の組を受けとって返すというだけの違い
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.kakeudon_fpu.all;

entity FADD_BITSAVE is
  Port (
    clk:     in std_logic;
    refetch : in std_logic;
    fadd_in_available : in std_logic;
    fadd_in_tag  : in tomasulo_fpu_tag_t;
    fadd_in_saved_sign : in std_logic;
    fadd_in0 : in unsigned32;
    fadd_in1 : in unsigned32;
    fadd_out_available : out std_logic;
    fadd_out_tag  : out tomasulo_fpu_tag_t;
    fadd_out_saved_sign : out std_logic;
    fadd_out_value : out unsigned32;
    cdb_writable : in std_logic;
    cdb_writable_next : out std_logic;
    fadd_unit_available : out std_logic);
end entity FADD_BITSAVE;


architecture RTL of FADD_BITSAVE is
  type stage1_type is record
    tag    : tomasulo_fpu_tag_t;
    saved_sign   : std_logic;
    avail  : std_logic;
    a_1    : unsigned32;
    na     : unsigned32;
    nb     : unsigned32;
    sign_1 : std_logic;
    exp_1  : unsigned32;
    opFlg_1: unsigned( 1 downto 0);
    isAdd  : std_logic;
    ret_a_1: std_logic;
  end record;
  type stage2_type is record
    tag    : tomasulo_fpu_tag_t;
    saved_sign   : std_logic;
    avail  : std_logic;
    a_2    : unsigned32;
    sign_2 : std_logic;
    exp_2  : unsigned32;
    frac_2 : unsigned32;
    ret_a_2: std_logic;
    opFlg_2: unsigned ( 1 downto 0);
  end record;
  type stage3_type is record
    tag    : tomasulo_fpu_tag_t;
    saved_sign   : std_logic;
    avail  : std_logic;
    ans    : unsigned32;
  end record;

  type stall_flg is record
    s1: std_logic;
    s2: std_logic;
  end record;

  type reg_type is record
    s1 : stage1_type;
    s2 : stage2_type;
    cdb_use : std_logic;
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

  procedure STALL_CHECK(refetch : in std_logic;
                        writable: in std_logic;
                        s1_avl  : in std_logic;
                        s2_avl  : in std_logic;
                        stall_1 : out std_logic;
                        stall_2 : out std_logic) is
    variable s1, s2, s3 : std_logic;
  begin
    if refetch = '1' then
      s1 := '1';
      s2 := '1';
    else
      if writable /= '1' and s2_avl = '1' then
        s2 := '1';
      else
        s2 := '0';
      end if;

      if s2 = '1' and s1_avl = '1' then
        s1 := '1';
      else
        s1 := '0';
      end if;
    end if;
    stall_1 := s1;
    stall_2 := s2;
  end STALL_CHECK;



begin

  comb : process ( clk,
                   refetch,
                   fadd_in_available,
                   fadd_in_tag,
                   fadd_in_saved_sign,
                   fadd_in0,
                   fadd_in1,
                   cdb_writable)

    variable v : reg_type;

    variable input1  : unsigned32;
    variable input2  : unsigned32;


    variable s1      : stage1_type;
    variable s2      : stage2_type;
    variable s3      : stage3_type;


    -- stage 1 --
    variable tag_1   : tomasulo_fpu_tag_t;
    variable saved_sign_1  : std_logic;
    variable avail_1 : std_logic;
    variable a, b    : unsigned32;
    variable na, nb  : unsigned32;
    variable d       : unsigned32;
    variable flg     : std_logic;
    variable isAdd   : std_logic;
    variable tmp1    : integer;
    variable opFlg_1 : unsigned ( 1 downto 0);
    variable ret_a   : std_logic;
    -- stage 2 --
    variable tag_2   : tomasulo_fpu_tag_t;
    variable saved_sign_2  : std_logic;
    variable avail_2 : std_logic;
    variable sign_2  : std_logic;
    variable exp_2   : unsigned32;
    variable lg2     : unsigned32;
    variable fracSum : unsigned32;
    variable tmp2    : std_logic;
    variable opFlg_2 : unsigned ( 1 downto 0);
    variable ret_a_2 : std_logic;
    -- stage 3 --
    variable tag_3  : tomasulo_fpu_tag_t;
    variable saved_sign_3 : std_logic;
    variable avail_3: std_logic;
    variable sign_3 : std_logic;
    variable exp_3  : unsigned32;
    variable frac_3 : unsigned32;
    variable opFlg_3: unsigned ( 1 downto 0);
    variable ans    : unsigned32;
    variable ulp    : std_logic;
    variable guard  : std_logic;
    variable round  : std_logic;
    variable stick  : std_logic;

    variable cdb_use : std_logic := '0';

    variable stall_1, stall_2 : std_logic := '0';

  begin

    v := r;

    STALL_CHECK(refetch, cdb_writable,
                v.s1.avail, v.s2.avail,
                stall_1, stall_2);

    ----- stage 1 -----

    input1 := fadd_in0;
    input2 := fadd_in1;
    tag_1  := fadd_in_tag;
    saved_sign_1 := fadd_in_saved_sign;
    avail_1 := fadd_in_available;

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
    s1.tag    := tag_1;
    s1.saved_sign   := saved_sign_1;
    s1.avail  := avail_1;
    s1.a_1    := a;
    s1.na     := na;
    s1.nb     := nb;
    s1.sign_1 := a(31);
    s1.exp_1  := x"000000" & a(30 downto 23);
    s1.opFlg_1:= opFlg_1;
    s1.isAdd  := isAdd;
    s1.ret_a_1:= ret_a;
    ------------------

    if stall_1 = '1' then
      -- stall
      v.s1 := r.s1;
    else
      v.s1 := s1;
    end if;

    if refetch = '1' then
      v.s1.avail := '0';
    end if;


    ----- stage 2 -----

    tag_2   := r.s1.tag;
    saved_sign_2  := r.s1.saved_sign;
    avail_2 := r.s1.avail;
    sign_2  := r.s1.sign_1;
    exp_2   := r.s1.exp_1;
    opFlg_2 := r.s1.opFlg_1;
    ret_a_2 := r.s1.ret_a_1;

    if r.s1.isAdd = '1' then
      fracSum := r.s1.na + r.s1.nb;
    else
      fracSum := r.s1.na - r.s1.nb;
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
      exp_2 := r.s1.exp_1;
    end if;

    s2.tag    := tag_2;
    s2.saved_sign := saved_sign_2;
    s2.avail  := avail_2;
    s2.sign_2 := sign_2;
    s2.exp_2  := exp_2;
    s2.frac_2 := fracSum;
    s2.opFlg_2:= opFlg_2;
    s2.a_2    := r.s1.a_1;
    s2.ret_a_2:= ret_a_2;
    ---------------------

    if stall_2 = '1' then
      -- stall
      v.s2 := r.s2;
    else
      v.s2 := s2;
    end if;

    if refetch = '1' then
      v.s2.avail := '0';
    end if;

    ----- stage 3 -----
    tag_3  := r.s2.tag;
    saved_sign_3 := r.s2.saved_sign;
    avail_3:= r.s2.avail;
    sign_3 := r.s2.sign_2;
    exp_3  := r.s2.exp_2;
    frac_3 := r.s2.frac_2;
    opFlg_3:= r.s2.opFlg_2;
    ulp    := r.s2.frac_2(3);
    guard  := r.s2.frac_2(2);
    round  := r.s2.frac_2(1);
    stick  := r.s2.frac_2(0);

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
    elsif r.s2.ret_a_2 = '1' then
      ans := r.s2.a_2;
    elsif exp_3 >= x"ff" then -- OverFlow
      ans := sign_3 & x"ff" & (22 downto 0 => '0');
    else
      ans := sign_3 & exp_3(7 downto 0) & frac_3(25 downto 3);
    end if;


    -----------------


    cdb_use := cdb_writable and avail_3;

    v.cdb_use := cdb_use;

    if cdb_use = '1' then
      fadd_out_available <= avail_3;
      fadd_out_tag       <= tag_3;
      fadd_out_saved_sign<= saved_sign_3;
      fadd_out_value     <= ans;
    else
      fadd_out_available <= '0';
      fadd_out_tag       <= (others => 'Z');
      fadd_out_saved_sign<= 'Z';
      fadd_out_value     <= (others => 'Z');
    end if;

    if cdb_writable = '1' and avail_3 = '0' then
      cdb_writable_next <= '1';
    else
      cdb_writable_next <= '0';
    end if;

    if (cdb_writable = '1' or
        r.s1.avail /= '1' or
        r.s2.avail /= '1' or
        fadd_in_available /= '1' )then
      fadd_unit_available <= '1';
    else
      fadd_unit_available <= '0';
    end if;

    rin <= v;

  end process;


  reg : process (clk)
  begin
    if rising_edge(clk) then
      r <= rin;
    end if;
  end process;

end architecture;
