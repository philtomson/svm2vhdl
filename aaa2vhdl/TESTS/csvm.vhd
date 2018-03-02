use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all;

entity csvm is
  generic(
    SV_ADDR_BITS     : natural := 9;
    SV_DATA_BITS     : natural := 16;
    SV_BINPT         : natural := 16; 

    XIN_ADDR_BITS    : natural := 1;
    XIN_DATA_BITS    : natural := 16;
    XIN_BINPT        : natural := 16;

    EXPLUT_ADDR_BITS : natural := 7;
    EXPLUT_DATA_BITS : natural := 16;
    EXPLUT_BINPT     : natural := 16;

    ALPHA_ADDR_BITS  : natural := 8;
    ALPHA_DATA_BITS  : natural := 17;
    ALPHA_BINPT      : natural := 16;

    RESULT_WIDTH     : natural := 33;

     

    DIFF_WIDTH       : natural := 17;
    
    DIFF_BINPT       : natural := 16;
    
    DIFF_SQUARED_WIDTH : natural := 35;
    
    DIFF_SQUARED_BINPT: natural := 32;
    
    --KWIDTH           : natural := 35;
    --KBINPT           : natural := 32;
    KWIDTH           : natural := 23;
    KBINPT           : natural := 16;
    
    EXPXALPHA_BITS   : natural := 33;
    EXPXALPHA_BINPT  : natural := 32;
    ACCUM_BITS       : natural := 20;
    ACCUM_BINPT      : natural := 16;

    NSV              : natural := 242;
    NI               : natural := 2  );
  port(
        clk         : in std_logic;
        rst         : in std_logic;
        ready       : out std_logic;

        result_sign : out std_logic
  );
end entity csvm;

use work.fixed_pt.all;

architecture synth_csvm of csvm is

    signal finished     : std_logic;
    signal exp_value    : unsigned( EXPLUT_DATA_BITS-1 downto 0);
    signal explut_addr  : unsigned( EXPLUT_ADDR_BITS-1 downto 0);
    signal xin          : unsigned( XIN_DATA_BITS-1 downto 0);
    signal xin_addr     : unsigned( XIN_ADDR_BITS-1 downto 0);
    signal sv_addr      : unsigned( SV_ADDR_BITS-1 downto 0);
    signal svin         : unsigned( SV_DATA_BITS-1 downto 0);
    signal alpha_addr   : unsigned( ALPHA_ADDR_BITS-1 downto 0);
    signal alpha_in     : unsigned( ALPHA_DATA_BITS-1 downto 0);
    signal alpha        : unsigned( ALPHA_DATA_BITS-2 downto 0); --w/o sign bit
    signal alpha_sign   : std_logic; 
    signal done         : std_logic;
    signal pos_accum    : unsigned( ACCUM_BITS-1 downto 0);
    signal neg_accum    : unsigned( ACCUM_BITS-1 downto 0);
    signal exp_x_alpha  : unsigned( EXPXALPHA_BITS downto 0);

    constant shift_k    : integer := 10;
    signal k            : unsigned( KWIDTH - 1 downto 0);

    constant scaled_bias: integer := -7600;

    signal i            : natural range 0 to NSV-1;
    signal j            : natural range 0 to NI-1;
    signal resetk       : std_logic;
    signal calculate    : std_logic;
    signal kready       : std_logic;

  component explut 
  port(
    clk : in  std_logic;
    en  : in  std_logic;
    addr: in  unsigned( EXPLUT_ADDR_BITS -1  downto 0);
    data: out unsigned( EXPLUT_DATA_BITS -1  downto 0)
  );
  end component explut ;
  
  component xin_lut
  port( 
    clk : in  std_logic;
    en  : in  std_logic;
    addr: in  unsigned( XIN_ADDR_BITS -1  downto 0 );
    data: out unsigned( XIN_DATA_BITS -1  downto 0 )
  );
  end component xin_lut; 

  component sv_lut 
    port(
      clk : in  std_logic;
      en  : in  std_logic;
      addr: in  unsigned( SV_ADDR_BITS -1  downto 0);
      data: out unsigned( SV_DATA_BITS -1  downto 0)
    );
  end component sv_lut;

  component alpha_lut 
    port(
      clk : in  std_logic;
      en  : in  std_logic;
      addr: in  unsigned(ALPHA_ADDR_BITS-1 downto 0);
      data: out unsigned(ALPHA_DATA_BITS-1 downto 0)
   );
  end component alpha_lut;
      

  component  csvm_fsm
    port (
          clk     : in std_logic;
          rst     : in std_logic;
          finished: in std_logic;   -- from the user of k
          i       : out natural range 0 to NSV-1 ; --num support vectors
          j       : out natural range 0 to NI -1 ; --num features
          rstk    : out std_logic; --reset k reg
          calc    : out std_logic; --do calculations while '1'
          valid   : out std_logic; --all done
          krdy    : out std_logic  --k is ready to be used
    );
  end component csvm_fsm;

  begin
  alpha      <= alpha_in(ALPHA_DATA_BITS-2 downto 0);
  alpha_sign <= alpha_in(ALPHA_DATA_BITS-1);
  xin_addr   <= to_unsigned(i,1);
  --explut_addr<= k(KWIDTH-shift_k downto (KWIDTH-shift_k)-(EXPLUT_ADDR_BITS-1));

  SV_ROM  : sv_lut
    port map (
      clk  => clk,
      en   => '1',
      addr => sv_addr,
      data => svin
    ); 

  ALPHA_ROM : alpha_lut
    port map (
      clk  => clk,
      en   => '1',
      addr => alpha_addr,
      data => alpha_in
     );

  XIN_ROM : xin_lut
     port map (
        clk  => clk,
        en   => '1',
        addr => xin_addr,
        data => xin
     );

  EXP_FUNC:explut 
  port map(
    clk  => clk,
    en   => kready, --maybe should be '1'?
    addr => explut_addr,
    data => exp_value
  );

  FSM : csvm_fsm
    port map(
          clk     => clk,
          rst     => rst,
          finished=> finished,
          i       => i , --num support vectors
          j       => j , --out natural range 0 to NI  , --num features
          rstk    => resetk,
          calc    => calculate,
          valid   => done,
          krdy    => kready
    );
  
  sv_addr <= to_unsigned(((NSV-1)*NI)+j,SV_ADDR_BITS);
  ready   <= kready;

  CALC_EXPLUT_ADDR: process(k)
    variable overflow    : unsigned(shift_k-1 downto 0 );
  begin
    --if we shifted k left by shift_k would an overflow result?
    overflow :=   k(KWIDTH-1 downto (KWIDTH-shift_k));
    if(overflow > 0) then
      explut_addr <= (others=>'1'); --saturate
    else
      explut_addr<= k((KWIDTH-1)-shift_k downto (KWIDTH-shift_k)-(EXPLUT_ADDR_BITS));
    end if;
  end process CALC_EXPLUT_ADDR;


  CALC_DIFF_K: process(clk,calculate,resetk)
    variable diff         : unsigned( DIFF_WIDTH-1 downto 0);
    variable diff_squared : unsigned( DIFF_SQUARED_WIDTH-1 downto 0);
  begin
    if(clk'event and clk='1') then
      if(resetk = '1') then
        k            <= (others => '0');
        diff         := (others => '0');
        diff_squared := (others => '0');
      elsif(calculate = '1') then
        diff         := subtract_fp(xin,XIN_BINPT,svin,SV_BINPT); 
        diff_squared := mult_fp(diff,DIFF_BINPT,diff,DIFF_BINPT);
        --k            <= k + diff_squared;
        k            <= add_fp(k,KBINPT,diff_squared,DIFF_SQUARED_BINPT);
      end if;
    end if; 
  end process CALC_DIFF_K;

  USE_K : process(clk,kready)
  begin
    if(clk'event and clk='1') then
      if(kready = '1') then
        finished <= '1';
        --accum <= accum + (alpha * k);
        exp_x_alpha <= mult_fp(alpha,ALPHA_BINPT,exp_value,EXPLUT_BINPT);
        if(alpha_sign = '1') then --negative
          neg_accum <= neg_accum + exp_x_alpha;
        else
          pos_accum <= pos_accum + exp_x_alpha;
        end if;
      else
        finished <= '0';
      end if;
    end if;
  end process USE_K;

  FINAL_ANSWER: process(clk,done)
    variable accum : INTEGER;
    variable res   : INTEGER;
    --variable accum   : signed( ACCUM_BITS-1 downto 0);
  begin
    if(clk'event and clk = '1') then
      if(done = '1') then
        accum  := ( to_integer(pos_accum) - to_integer(neg_accum));
        res    := accum + scaled_bias;
        if(res < 0 ) then
          result_sign <= '1';
        else
          result_sign <= '0';
        end if;
        ready <= '1';
      else
        ready <= '0';
      end if;
    else
    end if;
  end process FINAL_ANSWER;

  
end synth_csvm;
