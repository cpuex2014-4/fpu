library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.kakeudon_fpu.all;

entity FTOI is
  generic (
    last_unit : boolean);
  port (
    clk                 : in  std_logic;
    refetch             : in  std_logic;
    ftoi_in_available   : in  std_logic;
    ftoi_in_tag         : in  tomasulo_fpu_tag_t;
    ftoi_in             : in  unsigned32;
    ftoi_out_available  : out std_logic;
    ftoi_out_tag        : out tomasulo_fpu_tag_t;
    ftoi_out_value      : out unsigned32;
    cdb_writable        : in  std_logic;
    cdb_writable_next   : out std_logic;
    ftoi_unit_available : out std_logic);
end entity FTOI;

architecture RTL of FTOI is
  constant zero32  : unsigned32 := (others => '0');
  signal aExp      : unsigned32;
  signal sign      : std_logic;
  signal cdb_use   : std_logic;
  signal value     : unsigned32;
  signal avail_reg : std_logic;
  signal tag_reg   : tomasulo_fpu_tag_t;
  signal value_reg   : unsigned32;
begin

  cdb_use             <= cdb_writable when last_unit else
                         cdb_writable and avail_reg;
  ftoi_out_available  <= avail_reg when cdb_use = '1' else
                         'Z';
  ftoi_out_value      <= value_reg when cdb_use = '1' else
                         (others => 'Z');
  ftoi_out_tag        <= tag_reg when cdb_use = '1' else
                         (others => 'Z');
  cdb_writable_next   <= cdb_writable and (not avail_reg);
  ftoi_unit_available <= cdb_writable or
                         (not avail_reg);

  ftoi_proc: process(clk)
    variable ans, frac: unsigned32;
    variable shift : unsigned32;
    variable shifti : integer;
  begin

    if TO_01(ftoi_in, 'X')(0) = 'X' then
      value <= (others => 'X');
    else
      shift := x"96" - (x"000000"&ftoi_in(30 downto 23));
      shifti := to_integer(signed(shift));
      frac  := "000000001"&ftoi_in(22 downto 0);

      if 31 < shifti or shifti < -31 then
        value <= zero32;
      elsif shifti = 0 then
        if ftoi_in(31) = '1' then
          value <= (not frac) + 1;
        else
          value <= frac;
        end if;
      else
        if 0 < shifti then
          ans := unsigned(shift_right(unsigned(frac), shifti-1));
          ans := ans+1;
          ans := '0'&ans(31 downto 1);
        else
          ans := unsigned(shift_left(unsigned(frac), -shifti));
        end if;

        if ftoi_in(31) = '1' then
          value <= (not ans) + 1;
        else
          value <= ans;
        end if;
      end if;
    end if;

    if rising_edge(clk) then

      if refetch = '1' then
        avail_reg <= '0';
      else

        if cdb_writable /= '1' then
          -- stall
        else
          avail_reg <= ftoi_in_available;
          tag_reg   <= ftoi_in_tag;
          value_reg   <= value;
        end if;

      end if;

    end if;

  end process ftoi_proc;
end architecture RTL;
