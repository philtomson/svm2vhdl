#########################################################################
# lutgen.rb - class to generate a lookuptable in VHDL
#########################################################################
require 'erb'
class LutGen

@@genport = <<ENDOFGENPORT
  generic(
    BIN_POINT : natural := <%= @binpt %>;
    ADDR_BITS : natural := <%= @addr_bits %>;
    DATA_BITS : natural := <%= @data_bits %>
  );
  port( 
    clk : in std_logic;
    en  : in std_logic;
    addr: in unsigned( ADDR_BITS -1  downto 0);
    data: out <%= @data_type %>( DATA_BITS -1  downto 0)
  );
ENDOFGENPORT

@@vhdl= <<ENDOFVHDL
--=============================================================!
--=                        module cSVM                        =!
--=            lookuptable
--=            this file is generated automatically           =!
--=           <%= Time.now %>   
--=============================================================!
--=  Author:
--=  Phil Tomson
--=============================================================!
library ieee;
use ieee.std_logic_1164.all;
--use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity <%= @entity_name %> is
<%= @gen_port %>
end <%= @entity_name %> ;

architecture <%= @entity_name%>_syn of <%= @entity_name%> is

  subtype t_ROM_DATA is <%= @data_type %>( DATA_BITS-1  downto 0);
  type ROM_TYPE is array(natural range <>) of t_ROM_DATA;
  --constant ROM : ROM_TYPE(0 TO <%= 2**@addr_bits-1 %> ) :=
  constant ROM : ROM_TYPE(0 TO <%= @data_length-1 %> ) :=
(
<%= @data %>
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
end <%= @entity_name%>_syn;
ENDOFVHDL


  attr_reader :data_bits, :data_length, :addr_bits, :binpt, :gen_port
  def initialize(entity_name,addr_bits,data_bits,data,binpt,datatype="unsigned",addsign=false)
    @addsign     = addsign
    @entity_name = entity_name
    @addr_bits   = addr_bits
    if @addsign
      puts "addsign is: #{addsign}"
      @data_bits  = data_bits+1
      puts "@data_bits is: #{@data_bits}"
    else
      puts "data_bits is: #{data_bits}"
      @data_bits  = data_bits
    end
    case data
    when Array
      @data         = create_table_data(data)
      @data_length  = data.length
    when String
      @data         = data
      @data_length  = @data.split(',').length
    end   
    @binpt       = binpt
    @data_type   = datatype
    genport      = ERB.new(@@genport,0,">")
    @gen_port    = genport.result binding
    vhdtemp      = ERB.new(@@vhdl,0,">")
    outStr       = vhdtemp.result binding
    hfile        = File.open("#{@entity_name.downcase}.vhd","w")
    hfile << outStr
    hfile.close
    puts "compiling #{@entity_name.downcase}.vhd..."
    res = system("ghdl -a --ieee=synopsys #{@entity_name.downcase}.vhd")
    if res
      puts "-->compilation passed ;-)"
    else
      puts "-->compilation FAILED! :-("
    end
  end

  def create_table_data(table)
    vhd_str = ""
    table.each_with_index {|val,i|
      if i < (table.size() -1)
         sep = ","
      else
         sep = ""
      end
      #was:binval = sprintf("%0#{@data_bits}b", val.raw );
      if !@addsign 
        vhd_str += "\"#{val.to_bin}\"#{sep} -- index: #{i} val: #{val.raw}\n"
      else
        if val.sign < 0
          sign = "1"
        else
          sign = "0"
        end
        vhd_str += "\"#{sign}#{val.to_bin}\"#{sep} -- index: #{i} val: #{val.raw}\n"
      end	        
    }
    vhd_str 
  end

end


