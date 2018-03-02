use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_unsigned.all;

use work.std_logic_textio.all;
use work.external_comm_pkg.all;


---
entity test_comm  is
  generic(
      BIN_POINT : natural := 16;
      ADDR_BITS : natural := 7;
      DATA_BITS : natural := 16  );
end test_comm;

architecture behav of test_comm is

  component explut
  port(
      clk : in std_logic;
      en  : in std_logic;
      addr: in unsigned( ADDR_BITS -1  downto 0);
      data: out unsigned( DATA_BITS -1  downto 0)
  );
  end component explut ;
  
  type FSM_States is ( INITIAL, GET_ADDRESS,  SEND_RESULT);

  signal clk        : std_logic := '0';
  signal state      : FSM_States := INITIAL;
  signal expresult  : unsigned(DATA_BITS-1 downto 0);
  signal addr       : unsigned(ADDR_BITS-1 downto 0):= (others=>'0');
  signal current_addr : integer := 0;

begin

  --instantiate the explut
  EXP_FUNC: explut
  port map(
    clk  => clk,
    en   => '1',
    addr => addr,
    data => expresult
  );
 
 --generatge clock:
 clk <= NOT clk after 20 ns;

 STATE_COUNT: process(clk)
   variable OLine : Line;
   variable tmp   : integer;
 begin
   if(clk'event AND clk='1') then
     --addr <= addr + 1;
     if(state = INITIAL) then
       state <= GET_ADDRESS;
     elsif(state = GET_ADDRESS) then
       state <= SEND_RESULT;
     elsif(state = SEND_RESULT) then
       state <= GET_ADDRESS;
     end if;
   end if;
 end process STATE_COUNT;


 --still need this process to ensure that address and results are in 
 --sync
 PRINTOUT: process(state)
 --PRINTOUT: process(addr)
   variable OLine : Line;
   variable tmp   : integer;
   variable addr_int : integer := 0;
 begin
   if(state = GET_ADDRESS) then
     --get address
     addr_int := get_addr(0);
     write(OLine, (addr_int));
     writeline(output, OLine);
     addr <= to_unsigned(addr_int,ADDR_BITS);
   elsif( state = SEND_RESULT) then
     --send back result
     write(OLine, string'("sending expresult:"));
     writeline(output, OLine);
     write(OLine, to_integer(expresult));
     writeline(output, OLine);
     tmp := send_result(to_integer(expresult));
   end if;
 end process PRINTOUT;
 

end behav;


