class Numeric
  def to_fp(wid,binpt)
    FixedPt.new(self,wid,binpt)
  end
end

class OverflowException < RangeError
end

begin 
  require 'ext/fixedpt'
rescue LoadError
  puts "It's gonna be SLOWER without the C extension..."
  class RawFixedPt #used only to make FixedPt constructor easier (see case statment below)
    attr_reader :rawval, :bits, :binpt, :sign
    def initialize(rawval,total_bits,binpt)#,sign)
      @rawval = rawval
      @bits   = total_bits
      @binpt  = binpt
      #@sign   = sign
      @sign  = if rawval < 0
               -1
	     else
               1
             end
      @rawval = rawval.abs

      puts "@rawval = #{rawval}, @bits = #{@bits}, @binpt = #{binpt}, @sign = #{@sign}" if $DEBUG
    end

  end

else
end
begin
  require 'ext/fixedpt'
rescue LoadError
  puts "Couldn't find fixed pt: thing's will run slow, but it'll work"
  class FixedPt
  def initialize(val,total_bits=nil,binpt=nil)
    #raise "binpt should be less than total_bits!" if binpt > total_bits
    case val
    when Fixnum
      #@fval = val
      #@bits = total_bits
      #@binpt= binpt
      #check_sign(val)
      #@ival = (val.abs << binpt)  
      #puts "@ival is: #{@ival}" if $DEBUG
      construct_from_fixnum(val,total_bits,binpt)
    when Float
      #@bits = total_bits
      #@binpt= binpt
      #@fval = val
      #check_sign(val)
      #puts "sign is: #{@sign}" if $DEBUG
      #@ival = (val*(2**@binpt)).round.abs #NOTE:do we want to round or not?
      construct_from_float(val,total_bits,binpt)
    when FixedPt #essentially a copy constructor
      @ival = val.ival
      @bits = total_bits || val.bits #so you can override total # of bits
      @binpt= val.binpt #but binpt should remain at same position(for now)
      @sign = val.sign
    when RawFixedPt
	    #puts "constrcut a FixedPt with a RawFixedPt"
      @ival = val.rawval
      @bits = val.bits
      @binpt= val.binpt
      @sign = val.sign
    else
    end
    #TODO: What about simulating 2's complement?
    #for 2's comp:  positive @maxint = (2**(@bits-@binpt-1)-1) 
    #               negative @minint = -(2**(@bits-@binpt)-1)
    #@maxint = (2**(@bits-@binpt-1) - 1) 
    @maxint = (2**(@bits-@binpt) - 1) 
    @minint = -(2**(@bits-@binpt-1) ) 
  end

  def check_sign(val)
    puts "check_sign(#{val})" if $DEBUG
    if val < 0
      @sign = -1
    else
      @sign = 1
    end
  end


  def check_sizes(other)
    raise "binary points don't match! (#{@binpt} != #{other.binpt})" if other.binpt != @binpt
  end

  def check_for_overflow(result)
    return result if @binpt == @bits
    #shift result right binpt times
    if (result >> @binpt ) > @maxint
     begin
      raise OverflowException, "OVERFLOW: @bits: #{@bits}, @binpt: #{@binpt}, 2**@bits-1: #{2**@bits-1} result is: #{result}"	      
     rescue OverflowException
      #puts $!
      #NOTE: result below is the maximal result for this number of bits
      result = (2**@bits - 1)
     end
    end
    result
  end




  end #FixedPt

else
end

class FixedPt
  attr_accessor :fval, :ival, :bits, :maxint, :minint, :binpt, :sign
  def check_binpt
    raise "binpt should be less than total_bits!" if @binpt >= @total_bits
  end
  def value
    #puts "#{@ival}, sign is: #{@sign}"  if $DEBUG
    @ival*@sign
  end


  def construct_from_fixnum(val,total_bits,binpt)
      #puts "from fixnum"
      @fval = val
      @bits = total_bits
      @binpt= binpt
      check_sign(val)
      @ival = (val.abs << binpt)  
      puts "@ival is: #{@ival}" if $DEBUG
  end

  def construct_from_float(val,total_bits,binpt)
    @bits = total_bits
    @binpt= binpt
    @fval = val
    check_sign(val)
    #puts "sign is: #{@sign} for #{val}" #if $DEBUG
    @ival = (val*(2**@binpt)).round.abs #NOTE:do we want to round or not?
  end

  def from_float(val)
    (val*(2**@binpt)).round.abs #NOTE:do we want to round or not?
  end

  def assign(val)
    case val
    when Float
      @ival = from_float(val)
      @fval = val
      check_sign(val)
    when Fixnum
      @ival = (val << @binpt )
      @fval = val
      check_sign(val)
    when FixedPt
      from_FixedPt(val)
    else
    end
  end

  def from_FixedPt(other)
    check_sizes(other)
    @ival = other.ival
    @sign = other.sign
  end

  def raw
    @ival
  end

  def to_bin
    #str = sprintf("%0#{@bits}b",@ival)
    str = if @sign < 0
      sprintf("%0#{@bits}b",2**@bits-@ival)
    else
      sprintf("%0#{@bits}b",@ival)
    end
    return str
  end

  def to_binary
    str = self.to_bin
    values = str.split('')
    values.insert(@bits-@binpt,".")
    values.join('')
  end

  def to_int
    (@ival >> @binpt)
  end

  def to_i
    to_int
  end

  def to_s
    to_int.to_s 
  end

  #convert our limited representation back to float
  def to_f
    f = self.to_int.to_f
    puts " Initial f is: #{f}" if $DEBUG
    puts " self.raw is: #{self.raw}" if $DEBUG
    x = self.raw
    (0 .. (@binpt -1)).each {|i|
       puts "... is is: #{i} " if $DEBUG
       delta = x[i]*(1.0/(2**(@binpt-i)))
       puts "... delta is: #{delta} x[#{i}] is #{x[i]}" if $DEBUG
       f += delta
    }
    puts "@sign is #{@sign}" if $DEBUG
    f *@sign
  end

  def delta
    (self.to_f.abs - self.fval.abs).abs
  end


  def check_sizes(other)
    raise "binary points don't match! (#{@binpt} != #{other.binpt})" if other.binpt != @binpt
  end

  def to_fp(wid=@bits,binpt=@binpt)
    self
  end

  def /(other)
    #implement in terms of multiplication
    #case other
    #when FixedPt
      #check_sizes(other)
      result = ((self) * (FixedPt.new((1.0/other.to_f),@bits,@binpt)))  
      return result
    #when Fixnum
    #  result = ((self) / (other))  << (@binpt)
    #  return FixedPt.new(RawFixedPt.new(result,(@bits),@binpt),nil,nil)
    #end
  end

  def *(other)
    #case other
    #when FixedPt
      check_sizes(other)
      result = ((self.value) * (other.value))  >> (@binpt)
      #puts "result is #{sprintf("%x",result)}" if $DEBUG
      result = check_for_overflow(result)
      return FixedPt.new(RawFixedPt.new(result,(@bits),@binpt),nil,nil)
    #end
  end

  def mult(other)
    case other
    when FixedPt
      check_sizes(other)
      result = ((self.value) * (other.value))  >> (@binpt)
      puts "result is #{sprintf("%x",result)}" if $DEBUG
      return FixedPt.new(RawFixedPt.new(result,(@bits*2),@binpt),nil,nil)
    end
  end

  #perhaps this could be called 'increase_resolution'
  #effect: it preserves the integer portion of the number and
  #increases the number of positions to the right of the binary point
  #this increasing resolution
  def shift_left(num) #for conversion purposes
    #maintain same integer range, add fractional bits
    result = FixedPt.new(RawFixedPt.new(((self.raw) << num),(@bits+num),(@binpt+num)),nil,nil)
  end

  def shift_right(num) #for conversion purposes, integer portion should
	               #be preserved
    if num > @binpt
      raise "can't shift right #{num} positions: only #{@binpt} positions"
    end
    return FixedPt.new(RawFixedPt.new((self.raw>>num),(@bits-num),(@binpt-num)),nil,nil) 
  end


  def <<(num)
    result = FixedPt.new(RawFixedPt.new(((self.raw)<<num),@bits,@binpt),@bits,@binpt)
  end

  def ranged_int_part
    @ival = (@ival & 2**@bits-1)
  end

  def +(other) #assume result size is self size
    #case other
    #when FixedPt
      check_sizes(other)
      result = (self.value ) + (other.value ) 
      #puts "self.value is: #{self.value}" if $DEBUG
      #puts "other.value is: #{other.value}" if $DEBUG
      #puts "result is: #{result}" if $DEBUG
      result = check_for_overflow(result)
      return FixedPt.new(RawFixedPt.new(result, @bits, @binpt),nil,nil )#,sign))
    #when Fixnum
    #when Float
    #else
    #end
  end

  def -(other) #assume result size is self size
    #case other
    #when FixedPt
      check_sizes(other)
      result = (self.value ) - (other.value ) 
      #puts "self.value is: #{self.value}" if $DEBUG
      #puts "other.value is: #{other.value}" if $DEBUG
      #puts "result is: #{result}" if $DEBUG

      #TODO:result = check_for_overflow(result)
      return FixedPt.new(RawFixedPt.new(result, @bits, @binpt),nil,nil )#,sign))
    #when Fixnum
    #when Float
    #else
    #end
  end

end




if $0 == __FILE__
  
  FRAC_PART = 3 
  INT_PART  = 3
  WIDTH = FRAC_PART + INT_PART
  fixed = FixedPt.new(3,4,2) 
  puts "fixed is: #{fixed}"
  fixedfloat = FixedPt.new(-(1/3.0),WIDTH,FRAC_PART)
  puts "fixedfloat is: #{fixedfloat}"
  puts "fixedfloat.raw is: 0x#{sprintf("%x",fixedfloat.raw)}"
 
  puts "binary: "+fixedfloat.to_binary+ " = #{fixedfloat.to_f}"
  

  multiplicand = FixedPt.new(6,WIDTH,FRAC_PART)
  results = fixedfloat * multiplicand
  puts "binary: "+results.to_binary+ " = #{results.to_f}"

  foo =  FixedPt.new(-(9/16.0),4,4)
  puts "#{foo.to_binary}  #{foo.to_f}"
  foo =  FixedPt.new(-(1.0),4,1)
  puts "#{foo.to_binary}  #{foo.to_f}"
  foo =  FixedPt.new(-(2.0),4,1)
  puts "#{foo.to_binary}  #{foo.to_f}"
  foo =  FixedPt.new(-(4.0),4,1)
  puts "#{foo.to_binary}  #{foo.to_f}"
  foo =  FixedPt.new(-(5.0),4,1)
  puts "#{foo.to_binary}  #{foo.to_f} minint:#{foo.minint} maxint:#{foo.maxint}"

  foo = FixedPt.new((1/3.0),11,3)
  puts "#{foo.to_binary}  #{foo.to_f}"

end
