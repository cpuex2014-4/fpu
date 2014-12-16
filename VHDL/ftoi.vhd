library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity FTOI is
  Port (input  : in  unsigned(31 downto 0);
        output : out unsigned(31 downto 0));
end entity FTOI;

architecture RTL of FTOI is
  subtype unsigned32 is unsigned(31 downto 0);
  constant zero32 : unsigned32 := (others=>'0');
  signal aExp: unsigned32;
  signal sign: std_logic;
begin
  ftoi_proc: process(input)
    variable ans, frac: unsigned32;
    variable shift : unsigned32;
    variable shifti : integer;
  begin
    if TO_01(input, 'X')(0) = 'X' then
      output <= (others => 'X');
    else
      shift := x"96" - (x"000000"&input(30 downto 23));
      shifti := to_integer(signed(shift));
      frac  := "000000001"&input(22 downto 0);

      if 31 < shifti or shifti < -31 then
        output <= zero32;
      elsif shifti = 0 then
        if input(31) = '1' then
          output <= (not frac) + 1;
        else
          output <= frac;
        end if;
      else
        if 0 < shifti then
          ans := unsigned(shift_right(unsigned(frac), shifti-1));
          ans := ans+1;
          ans := '0'&ans(31 downto 1);
        else
          ans := unsigned(shift_left(unsigned(frac), -shifti));
        end if;

        if input(31) = '1' then
          output <= (not ans) + 1;
        else
          output <= ans;
        end if;
      end if;
    end if;
  end process ftoi_proc;
end architecture RTL;
