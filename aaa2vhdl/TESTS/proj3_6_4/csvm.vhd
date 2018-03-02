use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_unsigned.all;
--use ieee.std_logic_arith.all;

entity csvm is
  generic(
    SV_ADDR_BITS     : natural := 9;
    SV_DATA_BITS     : natural := 18; --added extra bit for signed rep
    SV_BINPT         : natural := 16; 

    XIN_ADDR_BITS    : natural := 1;
    XIN_DATA_BITS    : natural := 18; --added extra bit for signed rep
    XIN_BINPT        : natural := 16;

    EXPLUT_ADDR_BITS : natural := 7;
    EXPLUT_DATA_BITS : natural := 16;
    EXPLUT_BINPT     : natural := 16;

    ALPHA_ADDR_BITS  : natural := 8;
    ALPHA_DATA_BITS  : natural := 17;
    ALPHA_BINPT      : natural := 16;

    RESULT_WIDTH     : natural := 33;

     

    DIFF_WIDTH       : natural :=  18; --same as KWIDTH
    
    DIFF_BINPT       : natural := 16;
    
    DIFF_SQUARED_WIDTH : natural := 36; --2*DIFF_WIDTH
    
    DIFF_SQUARED_BINPT: natural := 32; --2*DIFF_SQUARED_BINPT
    
    KWIDTH           : natural := 18; --same as DIFF_WIDTH
    KBINPT           : natural := 16;
    
    EXPXALPHA_BITS   : natural := 32;
    EXPXALPHA_BINPT  : natural := 32;
    ACCUM_BITS       : natural := 40;  --same as EXPXALPHA_BITS
    --ACCUM_BINPT      : natural := 16; --not used

    NSV              : natural := 242;
    NI               : natural := 2  );
  port(
        clk         : in std_logic;
        rst         : in std_logic;
	xin         : in signed(XIN_DATA_BITS -1 downto 0);
	xin_addr    : out unsigned(XIN_ADDR_BITS-1 downto 0);
        ready       : out std_logic;
	valid_answer: out std_logic;

        result_sign : out std_logic
  );
end entity csvm;

--use work.fixed_pt.all;

architecture synth_csvm of csvm is

  --tosigned converts unsigned to signed by doing a straight bit-copy.  It isn't very safe if
  --the MSB of your argument is 1 and no checks are performed for that case.  However it works
  --fine for our purposes.
  function tosigned (
    arg : unsigned
  ) return signed is
    variable result : SIGNED ( arg'range );
  begin
    floop: for i in arg'range loop
      result(i) := to_X01(arg(i));
    end loop floop;
  
    return result;
  end function tosigned;


  function tounsigned (
    arg : signed
  ) return unsigned is
    variable result : unSIGNED ( arg'range );
  begin
    floop: for i in arg'range loop
      result(i) := to_X01(arg(i));
    end loop floop;
  
    return result;
  end function tounsigned;


    signal finished     : std_logic; --finished with k
    signal exp_value    : unsigned( EXPLUT_DATA_BITS-1 downto 0);
    signal explut_addr  : unsigned( EXPLUT_ADDR_BITS-1 downto 0):=(others=>'1');
    --signal xin          : signed( XIN_DATA_BITS-1 downto 0); --changed to signd 
    --signal xin_addr     : unsigned( XIN_ADDR_BITS-1 downto 0);
    signal sv_addr      : unsigned( SV_ADDR_BITS-1 downto 0):= (others=>'0');
    signal svin         : signed( SV_DATA_BITS-1 downto 0); --changed to signed!!!!!
    signal alpha_addr   : unsigned( ALPHA_ADDR_BITS-1 downto 0);
    signal alpha_in     : unsigned( ALPHA_DATA_BITS-1 downto 0);
    signal alpha        : unsigned( ALPHA_DATA_BITS-2 downto 0); --w/o sign bit
    signal alpha_sign   : std_logic; 
    signal done         : std_logic := '0';
    signal pos_accum    : signed( ACCUM_BITS-1 downto 0):= (others=>'0');
    signal neg_accum    : signed( ACCUM_BITS-1 downto 0):= (others=>'0');
    --signal exp_x_alpha  : unsigned( EXPXALPHA_BITS-1 downto 0);--changed to variable
    constant shift_k    : integer := 4;
    signal k            : unsigned( KWIDTH - 1 downto 0) := (others=>'0');

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
    data: out signed( XIN_DATA_BITS -1  downto 0 ) --changed to signed
  );
  end component xin_lut; 

  component sv_lut 
    port(
      clk : in  std_logic;
      en  : in  std_logic;
      addr: in  unsigned( SV_ADDR_BITS -1  downto 0);
      data: out signed( SV_DATA_BITS -1  downto 0) 
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
 
  
  xin_addr   <= to_unsigned(j,1);
  
  
  alpha_addr <= to_unsigned(i,8);

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

  --XIN_ROM : xin_lut
   --  port map (
   --     clk  => clk,
   --     en   => '1',
   --     addr => xin_addr,
   --     data => xin
   --  );

  EXP_FUNC:explut 
  port map(
    clk  => clk,
    en   => '1', --kready?
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
  --valid_answer <= done; 
  --was: sv_addr <= to_unsigned(((NSV-1)*NI)+j,SV_ADDR_BITS);
  process(i,j)
  begin
    if(j < NI) then
      sv_addr <= to_unsigned( ((i*NI)+j), SV_ADDR_BITS);
    end if;
  end process;
  
  ready   <= kready;

  process(k)
    variable overflow    : unsigned(shift_k-1 downto 0 );
  begin
    overflow :=   k(KWIDTH-1 downto (KWIDTH-shift_k));
    if(overflow > 0) then
      --explut_addr <= (others=>'1'); --saturate
      explut_addr<= k((KWIDTH-1)-shift_k downto (KWIDTH-shift_k)-(EXPLUT_ADDR_BITS));
    else
      explut_addr<= k((KWIDTH-1)-shift_k downto (KWIDTH-shift_k)-(EXPLUT_ADDR_BITS));
    end if;

  end process;

  CALC_DIFF_K: process(clk,calculate,resetk)
    variable diff         : signed( DIFF_WIDTH-1 downto 0) := (others=>'0');
    variable diff_squared : unsigned( DIFF_SQUARED_WIDTH-1 downto 0) := (others=>'0');
    variable diff_sq_trunc: unsigned( KWIDTH-1 downto 0);
    variable kvar         : unsigned( KWIDTH-1 downto 0);
   -- variable ssvin        : signed(DIFF_WIDTH-1 downto 0) := (others=>'0');
  begin
    if(clk'event and clk='1') then
      if(resetk = '1' or rst = '1') then
        k            <= (others => '0');
        diff         := (others => '0');
        diff_squared := (others => '0');
      elsif(calculate = '1'  ) then
        --diff         := subtract_fp(xin,XIN_BINPT,svin,SV_BINPT); 
        --diff  := xin - svin; 
        --ssvin := to_signed(to_stdlogicvector(svin));
        diff  := xin - svin; 
        --diff_squared := to_unsigned(to_stdlogicvector(diff*diff));
        diff_squared := tounsigned((diff*diff));
	--k  <= k + diff_squared(DIFF_SQUARED_WIDTH-2 downto DIFF_BINPT );
	--k  <= k + diff_squared((DIFF_BINPT*2)+1 downto ((DIFF_BINPT*2)+1)-KWIDTH );
	--diff_sq_trunc := diff_squared((DIFF_BINPT*2)+1 downto ((DIFF_BINPT*2)+1)-(KWIDTH-1) );
	diff_sq_trunc := diff_squared((DIFF_BINPT+KWIDTH)-1 downto DIFF_BINPT );
	kvar := ( k + diff_sq_trunc);
	k  <= (k + diff_sq_trunc);
      end if;
    end if; 
  end process CALC_DIFF_K;

  USE_K : process(clk,kready)
    variable  exp_x_alpha  : unsigned( EXPXALPHA_BITS-1 downto 0);

  begin
    if(clk'event and clk='1') then
      if(rst = '1') then
        finished <= '0';
        exp_x_alpha := (others=>'0');
        pos_accum   <= (others=>'0');
        neg_accum   <= (others=>'0');
      elsif(kready = '1' ) then
        finished <= '1';
        --exp_x_alpha <= mult_fp(alpha,ALPHA_BINPT,exp_value,EXPLUT_BINPT);
	exp_x_alpha := alpha * exp_value;
        if(alpha_sign = '1') then --negative
          --neg_accum <= neg_accum + to_signed(to_stdlogicvector(exp_x_alpha));
          neg_accum <= neg_accum + tosigned((exp_x_alpha));
        else
          --pos_accum <= pos_accum + to_signed(to_stdlogicvector(exp_x_alpha));
          pos_accum <= pos_accum + tosigned((exp_x_alpha));
        end if;
      else
        finished <= '0';
      end if;
    end if;
  end process USE_K;

  FINAL_ANSWER: process(clk,done)
    --variable accum : INTEGER;
    
    --variable res   : INTEGER;
    variable res     : signed( ACCUM_BITS-1 downto 0);
    variable accum   : signed( ACCUM_BITS-1 downto 0);
  begin
    if(clk'event and clk = '1') then
      if(done = '1') then
        accum  := (pos_accum) - (neg_accum);
        --old: res    := accum + to_signed(scaled_bias,ACCUM_BITS);
        --res    := accum + to_signed("1111111111100010010100000101001100010110");
        res    := accum + tosigned("1111111111100010010100000101001100010110");
        if(res < 0 ) then
          result_sign <= '1';
        else
          result_sign <= '0';
        end if;
        --ready <= '1';  Why was this here?
        valid_answer <= '1';
      else
        valid_answer <= '0';
        --ready <= '0';  Why was this here?
      end if;
    else
    end if;
  end process FINAL_ANSWER;

  
end synth_csvm;









