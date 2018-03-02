library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use std.textio.all;

package fsm_stuff is
  type FSM_States is (START,INCRJ,KREADY,RESETK,INCRI,DONE);
end package fsm_stuff;

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use std.textio.all;

entity csvm_fsm is
  generic ( 
    NSV : natural := 242;
    NI  : natural := 2  );
  port (
          clk     : in std_logic;
          rst     : in std_logic;
          finished: in std_logic;   -- from the user of k
          i       : out natural range 0 to NSV ; --num support vectors
          j       : out natural range 0 to NI  ; --num features
          rstk    : out std_logic; --reset k reg
          calc    : out std_logic; --do calculations while '1'
          valid   : out std_logic; -- all done
          krdy    : out std_logic  --k is ready to be used
       );
end csvm_fsm; 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;
use std.textio.all;
use work.fsm_stuff.all;
architecture fsm_behav of csvm_fsm is


  signal i_count : natural range 0 to NSV := 0;
  signal j_count : natural range 0 to NI  := 0;
  signal reset_k : std_logic  := '1';
  signal calculate: std_logic := '0';
  signal k_ready : std_logic  := '0';
  signal alldone : std_logic  ;
  
  signal state : FSM_States := START;
  signal next_state : FSM_States := START;
begin

  rstk <= reset_k;
  krdy <= k_ready;
  valid <= alldone;
  j    <= j_count;
  i    <= i_count;
  calc <= calculate;

  transition_logic: process(state,finished,i_count,j_count)
  begin
    case state is
      when   START   =>
        next_state <= INCRJ;
      when   INCRJ   =>
        if(j_count = NI ) then --wait until count is NI
          if( i_count = NSV) then
            next_state <= DONE;
          else
            next_state <= KREADY;
          end if;
        end if;
      when   KREADY  =>
        if(finished = '1') then
          if(j_count = NI and i_count = NSV) then
            next_state <= DONE;
          else
            next_state <= RESETK;
          end if;
        end if; 
      when   RESETK  =>
        next_state <= INCRI;
      when   INCRI   =>
        next_state <= INCRJ;
      when   DONE    =>
        next_state <= DONE;
      when   OTHERS  =>
        next_state <= START;
    end case;
  end process transition_logic;

  state_mem:  process(clk)
  begin
    if(clk'event and clk = '1') then
      if( rst = '1') then
        state <= START;
      else
        state <= next_state;
      end if;
    end if;
  end process state_mem;

  count_j: process(clk,state)
  begin
    if(clk'event and clk = '1') then
        if( state = DONE or state = START) then
          j_count <= 0;
          i_count <= 0; 
        elsif(state = KREADY) then
          j_count <= 0; 
        elsif( state = RESETK) then
          j_count <= 0;
        elsif( state = INCRJ) then
          if(j_count = NI) then
            j_count <= 0;
          else
            j_count <= j_count + 1;
          end if;
        elsif (state = INCRI) then
            i_count <= i_count + 1;
        end if;
    end if;
  end process count_j;

  output_logic: process(state,finished,i_count,j_count)
    variable j_counter : natural range 0 to NI := 0;
    variable l : line ;
  begin
      case state is
          when START  =>
            reset_k    <= '1';
            k_ready    <= '0';
            calculate  <= '0';
            alldone    <= '0';
          when INCRJ  =>
            reset_k    <= '0';
            k_ready    <= '0';
            calculate  <= '1';
            alldone    <= '0';
          when KREADY =>
            --otherwise if not finished, hold in this state
            k_ready    <= '1';
            reset_k    <= '0';
            calculate  <= '0';
            alldone    <= '0';
          when RESETK =>
            k_ready    <= '0';
            reset_k    <= '1';
            calculate  <= '0';
            alldone    <= '0';
          when INCRI  =>
            reset_k    <= '0';
            k_ready    <= '0';
            calculate  <= '0';
            alldone    <= '0';
          when DONE   =>
            reset_k    <= '1';
            k_ready    <= '0';
            calculate  <= '0';
            alldone    <= '1';
          when others =>
            reset_k    <= '1';
            k_ready    <= '0';
            calculate  <= '0';
            alldone    <= '0';
      end case;
  end process;

end fsm_behav;
