use std.textio.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


package fixed_pt is

  attribute binary_point : INTEGER; 
  function resize (
    arg : unsigned;
    binpt: integer;
    integer_width : INTEGER;
    fraction_width : INTEGER
  ) return unsigned;

  function resize (
    arg : signed;
    binpt: integer;
    integer_width : INTEGER;
    fraction_width : INTEGER
  ) return signed;

  function maximum (
    L,R : INTEGER
  ) return INTEGER;
  
  function minimum (l, r : INTEGER)
    return INTEGER; 

  function mult_fp (
    l : unsigned;
    lbin_pt : natural;
    r : unsigned;
    rbin_pt : natural
    )    -- ufixed(a downto b) * ufixed(c downto d) =
    return unsigned;

  function mult_fp_signed (
    l : signed;
    lbin_pt : natural;
    r : signed;
    rbin_pt : natural
  ) return signed;


  function subtract_fp (
    l : unsigned;
    lbin_pt : natural;
    r : unsigned;
    rbin_pt : natural
  ) return unsigned;

  function subtract_fp_signed (
    l : signed;
    lbin_pt : natural;
    r : signed;
    rbin_pt : natural
  ) return signed;

  function add_fp (
    l : unsigned;
    lbin_pt : natural;
    r : unsigned;
    rbin_pt : natural
  ) return unsigned;

  function add_fp_signed (
    l : signed;
    lbin_pt : natural;
    r : signed;
    rbin_pt : natural
  ) return signed;
end package fixed_pt;

package body fixed_pt is
  --attribute binary_point : INTEGER;
  function resize (
    arg : unsigned;
    binpt: integer;
    integer_width : INTEGER;
    fraction_width : INTEGER
  ) return unsigned is
    variable result : UNSIGNED ( (integer_width+fraction_width) downto 0) := (others => '0');
    constant result_bp : integer := fraction_width;
    variable j : INTEGER := integer_width+binpt; 
  begin
    floop: for i in arg'range loop
      result(j) := to_X01(arg(i));
      j  := j-1;
    end loop floop;
    --    result(( integer_width + binpt) downto 0) := arg;
    return result;
  end function resize;

  function resize (
    arg : signed;
    binpt: integer;
    integer_width : INTEGER;
    fraction_width : INTEGER
  ) return signed is
    variable result : SIGNED( (integer_width+fraction_width)+1 downto 0) := (others => '0');
    constant result_bp : integer := fraction_width;
    variable j : INTEGER := integer_width+binpt; 
  begin
       result(( integer_width + binpt) downto 0) := arg;
    return result;
  end function resize;

  function maximum (
    L,R : INTEGER
  ) return INTEGER is
    begin  -- function maximum
      if L > R then return L;
      else return R;
      end if;
  end function maximum;

  function minimum (l, r : INTEGER)
    return INTEGER is
  begin  -- function maximum
    if L > R then return R;
    else return L;
    end if;
  end function minimum; 
  

  function mult_fp (
    l : unsigned;
    lbin_pt : natural;
    r : unsigned;
    rbin_pt : natural
    )    -- ufixed(a downto b) * ufixed(c downto d) =
    return unsigned is                    -- ufixed(a+c+1 downto b+d)

    constant integer_width  : INTEGER := maximum((l'high-lbin_pt), (r'high-rbin_pt));

    constant fraction_width : INTEGER := maximum((lbin_pt), (rbin_pt));

    
    --variable lresize, rresize : unsigned(integer_width+FixP downto fraction_width+FixP);
    variable lslv, rslv : UNSIGNED ( (integer_width+fraction_width)
                                    downto 0);
    variable result_slv : UNSIGNED (2*(integer_width+fraction_width)+1
                                    downto 0);
    --variable mresult : ufixed ((2*integer_width+1)+FixP
     --                          downto (2*fraction_width)+FixP);
    --variable result : ufixed ((l'high + r'high)+1
     --                         downto (l'low + r'low));
	    
    attribute binary_point of result_slv:variable is fraction_width;
  begin
    --if (l'length < 1 or r'length < 1) then
    --  return NAUF;
    --end if;
    lslv  := resize (l, lbin_pt,integer_width, fraction_width);
    rslv  := resize (r, rbin_pt,integer_width, fraction_width);
 
    result_slv := lslv * rslv;
    --mresult    := to_fixed (result_slv, 2*integer_width+1, 2*fraction_width);
    --result     := resize(mresult, result'high, result'low);
    --attribute binary_point of result_slv:variable is fraction_width;
    return result_slv;
  end function mult_fp;

  function mult_fp_signed (
    l : signed;
    lbin_pt : natural;
    r : signed;
    rbin_pt : natural
  ) return signed is
    constant integer_width  : INTEGER := maximum((l'high-lbin_pt), (r'high-rbin_pt));
    constant fraction_width : INTEGER := maximum((lbin_pt), (rbin_pt));
    
    --variable lresize, rresize : unsigned(integer_width+FixP downto fraction_width+FixP);
    variable lslv, rslv : SIGNED ( (integer_width+fraction_width)
                                    downto 0);
    variable result_slv : SIGNED (2*(integer_width+fraction_width)+1
                                    downto 0);
  begin
    lslv  := resize (l, lbin_pt,integer_width, fraction_width);
    rslv  := resize (r, rbin_pt,integer_width, fraction_width);
 
    result_slv := lslv * rslv;
    return result_slv;
  end function mult_fp_signed;

  function subtract_fp (
    l : unsigned;
    lbin_pt : natural;
    r : unsigned;
    rbin_pt : natural
  ) return unsigned is
    constant integer_width  : INTEGER := maximum((l'high-lbin_pt), (r'high-rbin_pt));
    constant fraction_width : INTEGER := maximum((lbin_pt), (rbin_pt));
    
    variable lslv, rslv : UNSIGNED ( (integer_width+fraction_width)+1
                                    downto 0);
    variable result_slv : UNSIGNED ((integer_width+fraction_width)+1
                                    downto 0);
  begin
    lslv  := resize (l, lbin_pt,integer_width, fraction_width);
    rslv  := resize (r, rbin_pt,integer_width, fraction_width);
 
    result_slv := lslv - rslv;
    return result_slv;

  end function subtract_fp;

  function add_fp (
    l : unsigned;
    lbin_pt : natural;
    r : unsigned;
    rbin_pt : natural
  ) return unsigned is
    constant integer_width  : INTEGER := maximum((l'high-lbin_pt), (r'high-rbin_pt));
    constant fraction_width : INTEGER := maximum((lbin_pt), (rbin_pt));

    variable lslv, rslv : UNSIGNED ( (integer_width+fraction_width)
                                    downto 0);
    variable result_slv : UNSIGNED ((integer_width+fraction_width)+1
                                    downto 0);
  begin
    lslv  := resize (l, lbin_pt,integer_width, fraction_width);
    rslv  := resize (r, rbin_pt,integer_width, fraction_width);

    result_slv := lslv + rslv;
    return result_slv;

  end function add_fp;

  function subtract_fp_signed (
    l : signed;
    lbin_pt : natural;
    r : signed;
    rbin_pt : natural
  ) return signed is
    constant integer_width  : INTEGER := maximum((l'high-lbin_pt), (r'high-rbin_pt));
    constant fraction_width : INTEGER := maximum((lbin_pt), (rbin_pt));
    
    variable lslv, rslv : SIGNED ( (integer_width+fraction_width)
                                    downto 0);
    variable result_slv : SIGNED ((integer_width+fraction_width)+1
                                    downto 0);
  begin
    lslv  := resize (l, lbin_pt,integer_width, fraction_width);
    rslv  := resize (r, rbin_pt,integer_width, fraction_width);
 
    result_slv := lslv - rslv;
    return result_slv;
  end function subtract_fp_signed;

  function add_fp_signed (
    l : signed;
    lbin_pt : natural;
    r : signed;
    rbin_pt : natural
  ) return signed is
    constant integer_width  : INTEGER := maximum((l'high-lbin_pt), (r'high-rbin_pt));
    constant fraction_width : INTEGER := maximum((lbin_pt), (rbin_pt));

    variable lslv, rslv : SIGNED ( (integer_width+fraction_width)
                                    downto 0);
    variable result_slv : SIGNED ((integer_width+fraction_width)+1
                                    downto 0);
  begin
    lslv  := resize (l, lbin_pt,integer_width, fraction_width);
    rslv  := resize (r, rbin_pt,integer_width, fraction_width);

    result_slv := lslv + rslv;
    return result_slv;
  end function add_fp_signed;

end package body fixed_pt;

