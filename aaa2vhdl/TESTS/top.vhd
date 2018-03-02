use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

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
		  explut_addr  : in unsigned( EXPLUT_ADDR_BITS-1 downto 0);
		  alpha_addr   : in unsigned( ALPHA_ADDR_BITS-1 downto 0);
		  xin_addr     : in unsigned( XIN_ADDR_BITS-1 downto 0);
		  sv_addr      : in unsigned( SV_ADDR_BITS-1 downto 0);
        -- ready       : out std_logic;
		  xout         : out unsigned( XIN_DATA_BITS-1 downto 0);
		  svout        : out unsigned( SV_DATA_BITS-1 downto 0);

        result     :  out unsigned( (ALPHA_DATA_BITS + EXPLUT_DATA_BITS)-1 downto 0)
        -- result_sign : out std_logic
  );
end entity csvm;

--use work.fixed_pt.all;

architecture synth_csvm of csvm is

    signal finished     : std_logic;
    signal exp_value    : unsigned( EXPLUT_DATA_BITS-1 downto 0);
    --signal explut_addr  : unsigned( EXPLUT_ADDR_BITS-1 downto 0);
    signal xin          : unsigned( XIN_DATA_BITS-1 downto 0);
    --signal xin_addr     : unsigned( XIN_ADDR_BITS-1 downto 0);
    --signal sv_addr      : unsigned( SV_ADDR_BITS-1 downto 0);
    signal svin         : unsigned( SV_DATA_BITS-1 downto 0);
    --signal alpha_addr   : unsigned( ALPHA_ADDR_BITS-1 downto 0);
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

  component alpha_lut 
    port(
      clk : in  std_logic;
      en  : in  std_logic;
      addr: in  unsigned(ALPHA_ADDR_BITS-1 downto 0);
      data: out unsigned(ALPHA_DATA_BITS-1 downto 0)
   );
  end component alpha_lut;
  
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
  
  begin
    result <=  alpha_in * exp_value;
  
    EXP_FUNC:explut 
  port map(														  
    clk  => clk,
    en   => '1',   
    addr => explut_addr,
    data => exp_value
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

     xout <= xin;

	  SV_ROM  : sv_lut
    port map (
      clk  => clk,
      en   => '1',
      addr => sv_addr,
      data => svin
    ); 

	 svout <= svin;
  
  end synth_csvm;

