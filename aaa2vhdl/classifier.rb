##################################################################3
# Classifier - build a classifier (kind of like a lookup table)
# that given an input value will give an output value
# Details: create a case statement based on 
##################################################################3
#require 'mathn'
#require 'inline'
class Classifier #AKA lookup table
  attr_reader :buckets, :less_than_threshold
  def initialize(min,resolution,scale=1.0,multiplier=1.0)
    @min      = min
    @resolution = resolution
    @scale = scale
    @num_cases,@remainder= (@min.abs).divmod @resolution
    @buckets = Array.new(@num_cases+2,0)
    @less_than_threshold = 0
    @multiplier = multiplier
    #create 
    puts "Classifier@min = #{@min}, @resolution = #{@resolution}, @scale =#{@scale}"
  end

  def create
    func_str = "def lookup(x)\n " 
    func_str << "  return 0.0 if x < #{@min}\n"
    func_str << "  raise 'positive x not allowed' if x > 0.0\n" 
    func_str << "  case x\n"
    @num_cases,@remainder= (@min.abs).divmod @resolution
    puts "num_cases is: #{@num_cases}, num_cases.to_i is: #{@num_cases.to_i}"
    puts "@remainder is: #{@remainder}"
    start = @min
    i = 0
    (@num_cases).to_i.abs.times {|i|
	    #puts "start+resolution is: #{start+@resolution}"
      func_str << "  when #{start}..#{start+@resolution} then #{Math.exp(start*@scale)} #start*@scale is: #{start*@scale}\n"
      start += @resolution
    }
    if @remainder > 0.0

      #was: func_str << "  when #{start}..#{start+remainder} then #{Math.exp(start*@scale+remainder)}\n #start/@scale+remainder is: #{start*@scale+remainder}"
      func_str << "  when #{start}..#{start+@remainder} then #{Math.exp(start*@scale)} #remainder: start*@scale is: #{start*@scale}\n"
    end
    func_str << "  else \n   1.0\n  end\nend"
    #puts func_str
    instance_eval(func_str)
    func_str
  end

  def create_with_tracking
    func_str = "def lookup(x)\n " 
    func_str << "  if x < #{@min}\n"
    func_str << "    @less_than_threshold += 1  \n"
    func_str << "    return 0.0 \n"
    func_str << "  end \n"
    func_str << "  raise 'positive x not allowed' if x > 0.0\n" 
    #func_str << "  @buckets = Array.new(#{@num_cases+2},0)\n"

    func_str << "  case x\n"
    puts "@num_cases is: #{@num_cases}, @num_cases.to_i is: #{@num_cases.to_i}"
    puts "@remainder is: #{@remainder}"
    start = @min
    i = 0
    (@num_cases).to_i.abs.times {|i|
	    #puts "start+resolution is: #{start+@resolution}"
      func_str << "  when #{start}..#{start+@resolution} \n "
      func_str << "    @buckets[#{i}]+= 1 \n"
      func_str << "    #{Math.exp(start*@scale)} #start*@scale is: #{start*@scale}\n"
      
      start += @resolution
    }
    if @remainder > 0.0
      i+=1
      #was: func_str << "  when #{start}..#{start+@remainder} then #{Math.exp(start*@scale+@remainder)}\n #start/@scale+@remainder is: #{start*@scale+@remainder}"
      func_str << "  when #{start}..#{start+@remainder} \n"
      func_str << "    @buckets[#{i}]+= 1\n"
      func_str << "    #{Math.exp(start*@scale)} #remainder: start*@scale is: #{start*@scale}\n"
    end
    i+=1
    func_str << "  else \n"
    func_str << "    @buckets[#{i}]+= 1\n"
    func_str << "    1.0\n  end\nend"
    #puts func_str
    instance_eval(func_str)
    func_str
  end

  def create_c #the most up_to_date of the create methods
    #first clear out the ruby_inline cache:
    `rm /cygdrive/c/phil/.ruby_inline/*.so`
    func_str = "double lookup(double x){\n " 
    func_str << "  if(x < #{@min}){\n"
    func_str << "    return 0.0; \n"
    func_str << "  } \n"
    func_str << "  //raise 'positive x not allowed' if x > 0.0\n" 
    #func_str << "  @buckets = Array.new(#{@num_cases+2},0)\n"

    #func_str << "  case x\n"
    puts "@num_cases is: #{@num_cases}, @num_cases.to_i is: #{@num_cases.to_i}"
    puts "@remainder is: #{@remainder}"
    start = @min
    i = 0
    conditional = "if"
    (@num_cases).to_i.abs.times {|i|
      if( i == @num_cases-1)
        conditional = "if"
      elsif( i > 0 )
        conditional = "else if" 
      end
      func_str << "  #{conditional}(( x >= #{start})&&(x<=#{start+@resolution})){ \n "

      exp_val=(Math.exp(start*@scale))*@multiplier
      exp_val=exp_val.round if @multiplier > 1.0

      func_str << "     return #{exp_val}; //start*@scale is: #{start*@scale}\n"
      func_str << "  }\n"
      
      start += @resolution
    }
    if @remainder > 0.0
      i+=1
      func_str << "  else if(( x >= #{start})&&(x<=#{start+@resolution})){ \n "

      exp_val=(Math.exp(start*@scale))*@multiplier
      exp_val=exp_val.round if @multiplier > 1.0

      func_str << "     return #{exp_val}; //start*@scale is: #{start*@scale}\n"
      func_str << "  }\n"
    end
    i+=1
    func_str << "  else {\n"
    func_str << "    return #{1.0*@multiplier};\n "
    func_str << "  }\n"
    func_str << "}\n"
    puts func_str
    @@func_str = func_str
    class << self
      inline do |builder|
        builder.c  @@func_str
      end
    end
    func_str
  end

end


if $0 == __FILE__
  c = Classifier.new(-10.0,0.1,(9.9999/184.0),2**8-1)
  function = c.create_c
  puts function
  puts c.lookup(-5.0) 
end
