--=============================================================!
--=                        module cSVM                        =!
--=            lookuptable
--=            this file is generated automatically           =!
--=           2018-03-01 20:08:12 -0800   
--=============================================================!
--=  Author:
--=  Phil Tomson
--=============================================================!
library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity xin_lut is
  generic(
    BIN_POINT : natural := 16;
    ADDR_BITS : natural := 1;
    DATA_BITS : natural := 16  );
  port( 
    clk : in std_logic;
    en  : in std_logic;
    addr: in unsigned( ADDR_BITS -1  downto 0);
    data: out unsigned( DATA_BITS -1  downto 0)
  );
end xin_lut ;

architecture xin_lut_syn of xin_lut is

  subtype t_ROM_DATA is unsigned( DATA_BITS-1  downto 0);
  type ROM_TYPE is array(natural range <>) of t_ROM_DATA;
  --constant ROM : ROM_TYPE(0 TO 1 ) :=
  constant ROM : ROM_TYPE(0 TO 1 ) :=
(
"1011011100110110", -- index: 0 val: 46902
"0010011110001111" -- index: 1 val: 10127
);
  begin
  process(clk)
    begin
      if (clk'event and clk = '1') then
        if(en='1') then
           data <= ROM(to_integer(addr));
        end if;
      end if;
  end process;
end xin_lut_syn;
