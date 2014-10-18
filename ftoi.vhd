library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_misc.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity FTOI is
  Port (input  : in  std_logic_vector(31 downto 0);
        output : out std_logic_vector(31 downto 0));
end entity FTOI;

architecture RTL of FTOI is
  subtype int32 is std_logic_vector(31 downto 0);
  constant zero32 : int32 := (others=>'0');
  signal aExp: int32;
  signal sign: std_logic;
begin
  fuga: process(input)
      variable ans, frac: int32;
      variable shift : int32;
      variable shifti : integer;
    begin
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
          ans := std_logic_vector(shift_right(unsigned(frac), shifti-1));
          ans := ans+1;
          ans := '0'&ans(31 downto 1);
        else
          ans := std_logic_vector(shift_left(unsigned(frac), -shifti));
        end if;

        if input(31) = '1' then
          output <= (not ans) + 1;
        else
          output <= ans;
        end if;
      end if;
    end process fuga;
end architecture RTL;
