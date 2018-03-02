class OverflowException < RangeError
end
begin 
  require 'ext/fixedpt'
rescue LoadError
  puts "It's gonna be SLOWWWWWWW!!!!!!!!!!!!!!!"
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

      puts "@rawval = #{rawval}, @bits = #{@bits}, @binpt = #{binpt}, @sign = #{@sing}" if $DEBUG
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
    @maxint = (2**(@bits-@binpt) - 1) 
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
  attr_accessor :fval, :ival, :bits, :maxint, :binpt, :sign
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
    sprintf("%0#{@bits}b",@ival)
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




class RangeInt
  attr_accessor :value
  def initialize(value,n)
    case n
    when Fixnum
      #in this case range is the number of bits of representation
      @range = (0 .. (2**n-1))
    when Range
      @range = n
    else
      
    end
    @value = value
  end 

  def +(val)
    RangeInt.new((@value+val)% (@range.max+1),@range)
  end

  def -(val)
    RangeInt.new((@value-val)% ( @range.max+1),@range)
  end

  def *(val)
    RangeInt.new((@value*val)% ( @range.max+1),@range)
  end

  def >>(val)
    RangeInte.new((@value>>val),@range)
  end

  def <<(val)
    RangeInt.new((@value << val)% (@range.max+1),@range)
  end

  def shift_left
    (@value<<= 1)% ( @range.max+1)
  end

  def shift_right
    (@value>>= 1)
  end

  def to_i
    @value
  end

  def to_s
    @value.to_s
  end

  def coerce(other)
    case other
    when Fixnum
      [other,@value]
    when Float
      [other,Float(@value)]
    end
  end

  #math ops on BitVectors (+-*/)
  def math_ops(op,other)
    case other
    when Fixnum
      RangeInt.new(self.to_i.send(op,other),@range)
    when RangeInt
      RangeInt.new(self.to_i.send(op,other.to_i),@range)
    when Float
      RangeInt.new(self.to_i.send(op,other.round),@range)
    else
      #TODO: raise exception
      raise TypeError, "Can't do  RangeInt #{op.to_s} #{other.class}"
    end
  end

  def method_missing(oper,*args)
    puts "args.length #{args.length} args.class #{args.class}" if $DEBUG
    if args.length ==0
      #self_op(oper)
    elsif args.length == 1
      #TODO: ^, & shouldn't be mathops, should be bin_arg_ops
      if oper.to_s =~ /[+-\/\*\^\&]/
        math_ops(oper,*args)
      else
        raise "No matching op found: #{oper} #{args}"
      end
    else
      #TODO: raise exception
      raise "No matching op found: #{oper} #{args}"
    end
  end
end

#provided so you don't have to type '.new' to create a RangeInt obj
def RangeInt(val,n)
  return RangeInt.new(val,n)
end

if $0 == __FILE__

  fixed = FixedPt.new(3,4,2) 
  puts "fixed is: #{fixed}"
  fixedfloat = FixedPt.new(3.15,5,3)
  puts "fixedfloat is: #{fixedfloat}"
  puts "fixedfloat.raw is: 0x#{sprintf("%x",fixedfloat.raw)}"
  exit
  x = RangeInt(255,(0..255))
  puts x+1 #should be 0

  puts 6 + x

  y = RangeInt(0,(0..3))
  puts "#{y} - 4 = #{y - 4} #should be 0"
  puts "#{y} - 3 = #{y - 3} #should be 1"
  puts "#{y} - 2 = #{y - 2} #should be 2"
  puts "#{y} - 1 = #{y - 1} #should be 3"

  z = RangeInt(1,(0..3))

  puts "#{y} * 4 = #{y * 4} #should be 0"
  puts "#{y} * 5 = #{y * 5} #should be 1"

  y1 = RangeInt(5,(0..15))

  puts "#{y1}.shift_left = #{y1.shift_left }" 
  puts "#{y1}.shift_left = #{y1.shift_left }" 
  puts "#{y1}.shift_left = #{y1.shift_left }" 
  puts "#{y1}.shift_left = #{y1.shift_left }" 

  y2 = RangeInt(5,(0..15))

  puts "#{y2}.shift_right = #{y2.shift_right }" 
  puts "#{y2}.shift_right = #{y2.shift_right }" 
  puts "#{y2}.shift_right = #{y2.shift_right }" 
  puts "#{y2}.shift_right = #{y2.shift_right }" 

  foo = RangeInt(3,3)

  puts "#{foo}*3 = #{foo*3}"

end
