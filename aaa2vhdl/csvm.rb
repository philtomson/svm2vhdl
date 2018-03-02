####################################################################
# csvm.rb                                                        
# A Ruby backend for cSVM
####################################################################

require 'matrix'
require 'aaaparser'
require 'classifier'
#require 'rangeint'
require 'fixedpt'
#require 'RomComm.so'

module Math
  def Math.log2(x)
    (Math.log(x)/Math.log(2)).ceil
  end
end
module Normalized_cSVM
  def linear_kernel(x)
    x=normalize(x) 
    f = 0
    for i in 0 .. @nsv 
      d = 0.0
      for j in 0 .. @ni
	#d += @x_norm[j]*@cSVM_sv[i][j]
        d += x[j]*@cSVM_sv[i][j]
      end
      f += f+d*@cSVM_alpha[i]
    end
    return f += @bias
  end

  def normalize_to_fixedpt(x)
    x = normalize(x)
    to_fixed_pt(x)
  end

  def gaussian_kernel_gold(x)
    accum = 0
    x=normalize(x)
    for i in 0 .. (@nsv -1)
      k = 0.0
      for j in 0 .. (@ni-1)
        k+=(x[j]-@cSVM_sv[i][j])*(x[j]-@cSVM_sv[i][j])
      end
      alpha = @cSVM_alpha[i]
      expval = Math.exp(-(k)*@fKparam)
      accum += (alpha*expval) 
    end
    return (accum += @bias)
  end

  #gaussian_kernel_fixedint - this is our level 2 meta-model
  def gaussian_kernel_fixedint(x)
    #For Banana: ###################
    #binpt = 16
    #regbits = 16
    #accum_bits = regbits + 2
    ################################
    binpt = @binpt 
    regbits = @bits
    #+2 works fine for banana
    accum_bits = regbits + 2 #TODO:make this configurable (was 4)
    puts "gaussian_kernel_fixedint..."
    accum = FixedPt.new(0,accum_bits,binpt) 


    scaled_bias = FixedPt.new(@bias,accum_bits,binpt)
    xfloat=normalize(x)
    x=to_fixed_pt(xfloat,regbits,regbits)
    multval = @multval
    puts "multval is: #{multval}"
    multiplier = FixedPt.new(multval,regbits+@lut.addr_bits,regbits)
    puts "multiplier is: #{multiplier.to_f} #{multiplier.to_bin}"
    f = 0
    for i in 0 .. (@nsv -1)
      k = FixedPt.new(0,regbits+@lut.addr_bits,regbits)
      for j in 0 .. (@ni-1)
        puts "j is: #{j}:"
        puts "xin  is: #{x[j].to_binary} #{x[j].to_f}"
        puts "svin is: #{@sv_fixed_pt[i][j].to_binary} #{@sv_fixed_pt[i][j].to_f}"
        diff = (x[j]-@sv_fixed_pt[i][j])
        puts "diff is: #{diff.to_f} #{diff.raw} #{diff.to_binary}"
        if diff.to_i > 0
          puts "diff GREATER THAN 0! #{diff.to_f}"
        end
        diff_squared = (diff*diff)
        puts "diff_squared is: #{diff_squared.to_binary}"
        k+=(diff * diff)
        puts "k is: #{k.to_binary}"
        if k.to_i > 0
          puts "K GREATER THAN 0! #{k.to_f}"
        end
      end
      alpha = @alpha_fp[i]
      puts "alpha is: #{alpha.to_binary} #{alpha.to_f} #{alpha.raw}"
      puts "alpha.sign is: #{alpha.sign}" #if $DEBUG
      #was:expval= FixedPt.new(@exp_table.lookup(-k),regbits,binpt)
      #expval= FixedPt.new(@lut[k.to_i].to_f,regbits,binpt)

      #mathexpval = Math.exp(-(k.to_f)*@fKparam)

      #puts "kfull is: #{kfull} class is: #{kfull.class}"

      puts "before: k is: #{k.to_i} k.to_f: #{k.to_f} k.bits is: #{k.bits} k.binpt is: #{k.binpt} k.maxint is: #{k.maxint}, k.raw is: #{k.raw} k.to_bin #{k.to_bin}"

      #was:k = k*multiplier #NOTE: to scale k to index lookup table(anyway around this?)
      #NOW TRY:
      k = k << 9 #TODO: figure out what constant should be

      if (k.to_i+1) > @lut.table.size
        #raise "index is out of range!!! k.to_i is: #{k.to_i}"
        puts "index is out of range!!! k.to_i is: #{k.to_i}"
	k.assign(@lut.table.size-1)
	#k.ranged_int_part
	puts "now k.to_i is: #{k.to_i}"
      end
      puts "after k is: #{k.to_i} k.to_f: #{k.to_f} k.bits is: #{k.bits} k.binpt is: #{k.binpt} k.maxint is: #{k.maxint}, k.to_bin is: #{k.to_bin}, k.to_f is: #{k.to_f}"
      expval_ = @lut[k.to_i]
      #puts "@bits is: #{@bits}"
      #puts "@binpt is: #{@binpt}"
      #expval_ = FixedPt.new(RawFixedPt.new(@rc.get_expval(k.to_i),@bits,@binpt),@bits,@binpt)
      #puts "k.to_i is: #{k.to_i}"
      puts "expval_ is: #{expval_.to_binary} expval_.to_f is: #{expval_.to_f}"

      #NOTE: now we'll replace expval with the val from Math.exp:
      #expval = FixedPt.new(mathexpval,18,18)

      #was: ftmp = ((@cSVM_alpha[i]*@multiplier).round)*((@exp_table.lookup(-k).to_i))
      expvalxalpha = (expval_ * alpha)
      puts "expvalxalpha is: #{expvalxalpha.to_binary} #{expvalxalpha.to_f}"
      accum.assign(accum +(alpha * expval_))
      puts "accum is: #{accum.to_binary} #{accum.to_f}"


 
      #accum.assign(accum +(alpha * expval))
      #puts "accum is: #{accum.to_i} alpha=#{alpha} expval=#{expval}" if $DEBUG
      #puts "raw vals: accum is: #{accum.raw} alpha=#{alpha.raw} expval=#{expval.raw}" if $DEBUG
	
    end
    accum += scaled_bias
    puts "accum is: #{accum.to_f}"
    exit #TODO: remove this line later
    return accum.to_f
  end

  def gaussian_kernel_hybrid(x)
    #For Banana: ###################
    #binpt = 16
    #regbits = 16
    #accum_bits = regbits + 2
    ################################
    binpt = @binpt 
    regbits = @bits
    #+2 works fine for banana
    accum_bits = regbits + 2 #TODO:make this configurable (was 4)
    puts "gaussian_kernel_fixedint..."
    accum = FixedPt.new(0,accum_bits,binpt) 


    scaled_bias = FixedPt.new(@bias,accum_bits,binpt)
    xfloat=normalize(x)
    x=to_fixed_pt(xfloat,regbits,regbits)
    multval = @multval
    puts "multval is: #{multval}"
    multiplier = FixedPt.new(multval,regbits+@lut.addr_bits,regbits)
    f = 0
    for i in 0 .. (@nsv -1)
      k = FixedPt.new(0,regbits+@lut.addr_bits,regbits)
      for j in 0 .. (@ni-1)
        diff = (x[j]-@sv_fixed_pt[i][j])
        k+=(diff * diff)
      end
      alpha = @alpha_fp[i]
      puts "alpha is: #{alpha.to_binary}"
      #puts "alpha.sign is: #{alpha.sign}" if $DEBUG
      #was:expval= FixedPt.new(@exp_table.lookup(-k),regbits,binpt)
      #expval= FixedPt.new(@lut[k.to_i].to_f,regbits,binpt)

      #mathexpval = Math.exp(-(k.to_f)*@fKparam)

      #puts "kfull is: #{kfull} class is: #{kfull.class}"
      #puts "before: k is: #{k.to_i} k.bits is: #{k.bits} k.binpt is: #{k.binpt} k.maxint is: #{k.maxint}, k.raw is: #{k.raw} k.to_bin #{k.to_bin}"

      k = k*multiplier #NOTE: to scale k to index lookup table(anyway around this?)
      if (k.to_i+1) > @lut.table.size
        #raise "index is out of range!!! k.to_i is: #{k.to_i}"
        puts "index is out of range!!! k.to_i is: #{k.to_i}"
	k.assign(@lut.table.size-1)
      end
      #puts "after k is: #{k.to_i} k.bits is: #{k.bits} k.binpt is: #{k.binpt} k.maxint is: #{k.maxint}, k.to_bin is: #{k.to_bin}, k.to_f is: #{k.to_f}"
      #NOTE: One of the next two lines should be uncommented:
      #expval_ = @lut[k.to_i]
      puts "@bits is: #{@bits}"
      puts "@binpt is: #{@binpt}"
      expval_ = FixedPt.new(RawFixedPt.new(@rc.get_expval(k.to_i),@bits,@binpt),@bits,@binpt)
      puts "k.to_i is: #{k.to_i}"
      puts "expval_ is: #{expval_} expval_.to_f is: #{expval_.to_f}"

      #NOTE: now we'll replace expval with the val from Math.exp:
      #expval = FixedPt.new(mathexpval,18,18)

      #was: ftmp = ((@cSVM_alpha[i]*@multiplier).round)*((@exp_table.lookup(-k).to_i))
      accum.assign(accum +(alpha * expval_))


 
      #accum.assign(accum +(alpha * expval))
      #puts "accum is: #{accum.to_i} alpha=#{alpha} expval=#{expval}" if $DEBUG
      #puts "raw vals: accum is: #{accum.raw} alpha=#{alpha.raw} expval=#{expval.raw}" if $DEBUG
    end
    accum += scaled_bias
    puts "accum is: #{accum.to_f}"
    return accum.to_f
  end

  def gaussian_kernel(x)
    puts "gaussian_kernel, at your service..."
    x=normalize(x)
    f = 0
    for i in 0 .. (@nsv -1)
      k = 0.0
      for j in 0 .. (@ni-1)
        k+=(x[j]-@cSVM_sv[i][j])*(x[j]-@cSVM_sv[i][j])
	#puts "k is: #{k}"
      end
      #puts "k is: #{k} cSVM_kRpar is: #{@cSVM_kRpar} cSVM_alpha[i] is #{@cSVM_alpha[i]}"
      #puts "@cSVM_alpha[i] is: #{@cSVM_alpha[i]}"

      #WAS:
      #f += @cSVM_alpha[i]*Math.exp(-k*@cSVM_kRpar/@ni)

      #NOTE: reinterpreting to make hardware implemention easier:
      #fKparam can be calculated up front by the translation software
      #since it is a 'fixed' value it can be included into the 
      #lookup table for exp, so fKparam essentially 'scales' the 

      #using lookup table
      #if block_given?
      #  f += yield(k,i)
      #else
        #f += @cSVM_alpha[i]*(@exp_table.lookup(-k*@fKparam))

	######################################################
	#latest lookup with fKparam mult in the lookup table #
	#ftmp = ((@cSVM_alpha[i]*@multiplier).round)*((@exp_table.lookup(-k)))
	#ftmp = ftmp/(@multiplier*@multiplier)

	ftmp = ((@cSVM_alpha[i]*@multiplier).round)*((@exp_table.lookup(-k).to_i))
	if( (ftmp >> (2*@bits)) != ftmp/(@multiplier*@multiplier))
          puts " ftmp is: #{ftmp}"
	  puts " ftmp >> (2*@bits) is: #{ftmp >> (2*@bits)}"
	  puts " ftmp/(@multiplier*@multiplier) is: #{ ftmp/(@multiplier*@multiplier) }"
        end
	#make sure ftmp is positive (abs) and save sign for after shift
        if ftmp < 0
          ftmp = ftmp.abs
	  sign = -1
	else
          sign = 1
	end

	#now divide ftmp by 
	ftmp = (ftmp >> (2*@bits-@binpt))*sign #works
	#ftmp = (ftmp >> (2*(@bits-@binpt)))*sign #what about this?
	if ftmp != 0
	  puts "ftmp is: #{ftmp}"
        end
	#ftmp = ftmp/(@multiplier*@multiplier)
	f += ftmp
        if f > (2**(20-@binpt)-1)
          puts "OUT OF RANGE: f is: #{f}"
        end
	######################################################
      #end
      

      #what if:
      #f += @cSVM_alpha[i]*2**(-k*fKparam) #1 failure with this approach
      #f += @cSVM_alpha[i]*3**(-k*fKparam)  #0 failures with this approach

      #TODO: replace the exp expression in the formula above with a
      #generated lookup table solution (first in Ruby) to see if it
      #will work.  Then create a VHDL generator.

    end
    #if f < 0
    #  f = f.abs
    #  sign = -1
    #else
    #  sign = 1
    #end
    #f = (f )*sign
    puts "f is: #{f}" 
    #scaled_bias = (@bias << @binpt).round * sign
    #return f += (@bias*(2**@binpt)).round
    return f += @scaled_bias

    #NOTE: can the @bias be considered when generating the exp lookup
    # table? Probably not, since it doesn't come into play until after
    # the MAC is complete
  end

  def polynomial_kernel(x)
    puts "using polynomial_kernel"
    x=normalize(x)
    f = 0
    for i in 0 .. (@nsv-1 )
    end
    return f += (@bias -1)
  end

   def normalize(x)
    x_temp = []
    for i in 0 .. (@ni - 1 )
      x_temp <<  @cSVM_cNorm[i][0]*x[i]+@cSVM_cNorm[i][1]      
    end
    puts "x_temp is: #{x_temp.join(",")}" if $DEBUG
    return x_temp
  end

  def to_fixed_pt(x,bits=@bits,binpt=@binpt)
    puts "to_fixed_pt: bits = #{bits}"
    puts "to_fixed_pt: binpt = #{binpt}"
    x_temp = []
    x.each_with_index {|val,i|
      x_temp << FixedPt.new(x[i],bits,binpt)
    }
    x_temp
  end

end

module UnNormalized_cSVM
  include Normalized_cSVM
  def normalize(x)
    x  #does nothing but return x unNormalized
  end
end


class C_SVM
  include LookupTableParams #must be defined in your testcase
  def get_results
    return @exp_table.buckets,@exp_table.less_than_threshold
  end

  attr_reader :ni, :nsv, :bits, :binpt, :multval, :scaled_bias
  def initialize(aaaFile,bits=nil,binpt=nil, kernel=:gaussian_kernel_fixedint)
    @model = kernel
    if(kernel == :gaussian_kernel_hybrid)
      @rc = RomComm.new
    end
    @binpt= binpt 
    @bits = bits 
    @expbits = @binpt #8 #for scaling lookup table values
    if @bits
      @multiplier = (2**@bits )
    else
      @multiplier = 1
    end
    puts "number of bits is: #{bits}"
    puts "@multiplier is: #{@multiplier}"
    if aaaFile.class == String
      @parser  = AAAParser.new("#{aaaFile}.aaa")
    elsif aaaFile.class == AAAParser
      @parser  = aaaFile
    end
    @ni        = @parser.num_features     
    puts "@ni (num_features) is: #{@ni}"
    @nsv       = @parser.num_support_vectors
    
    @bias      = @parser.b
    @scaled_bias = (@bias*(2**@binpt)).round 
    @cSVM_sv   = @parser.x_vector
    sv_to_fixedpt
    @cSVM_alpha= @parser.y_vector
    #@alpha_fp  = to_fixed_pt(@cSVM_alpha)
    @cSVM_cNorm= @parser.norm_params
    @cSVM_kRpar= @parser.gamma
    puts "@cSVM_kRpar (gamma) is: #{@SVM_kRpar}"
    @fKparam   = @cSVM_kRpar/@ni
    puts "@fKparam is: #{@fKparam}"
    #create lookup table 
    #NOTE: now moved to the run_<test> files to allow greater 'personalization'
    # based on the problem 
    #@exp_table = Classifier.new(-14.0,0.7,@fKparam) #for sonar
    #@exp_table = Classifier.new((-13.5/@fKparam),0.0004,@fKparam)  #works for banana
    #@exp_table = init_table
    @lut       = init_lut
    puts "<<<<<<<<<<<<<<<<<<<<@exp_table.create>>>>>>>>>>>>>>>"
    #puts @exp_table.create_with_tracking
    #puts @exp_table.create_c
    if @parser.norm_type > 0
      class << self
        include Normalized_cSVM
      end
    elsif @parser.norm_type == 0	    
      class << self
        include UnNormalized_cSVM
      end
    else
      raise "illegal norm_type"
    end
    @multval = (2**@lut.addr_bits)/(@lut.min.abs) 
    puts "create alpha_fp lookup table"
    @alpha_fp  = to_fixed_pt(@cSVM_alpha)

  end #initialize

  #create vhdl for this SVM
  def to_vhdl(x)
    puts "CSVM.to_vhdl"
    require 'lutgen'	   
    require 'csvmfsmgen'
    require 'csvmgen'
    #create exp lookup table
    explut = @lut.to_vhdl
    #create xin lookup table
    x=normalize(x)
    x=to_fixed_pt(x,@bits,@bits)
    xlut = LutGen.new("xin_lut",Math.log2(x.size),@bits,x,@bits)
    #create alpha lookup table and sign table (sign is MSB, 1=-, 0=+)
    puts "create alphalut bits = #{@bits} "
    alphalut = LutGen.new("alpha_lut",Math.log2(@alpha_fp.size),@bits,@alpha_fp,@binpt,"unsigned",true)
    #create support_vector lookup table (2 dimensional->1 dim)
    onedim_table = @sv_fixed_pt.flatten
    sv_table = LutGen.new("sv_lut",Math.log2(@nsv*@ni),@bits,onedim_table,@bits)
    #generate the FSM for controlling the csvm
    csvmfsm  = CsvmFsmGen.new(@nsv,@ni)
    #generate toplevel CSVM:
    csvmvhd  = CsvmGen.new(self,explut,xlut,alphalut,sv_table)
  end

  def sv_to_fixedpt
    @sv_fixed_pt = []
    @cSVM_sv.each_with_index {|vector,i|
      @sv_fixed_pt[i] = []
      vector.each {|xval|
        @sv_fixed_pt[i] << FixedPt.new(xval,@bits,@bits)
      } 
    }
  end

  def cSVM_FF(x)
    raise "dimension of x not equal to #{@ni}" if x.size != @ni
    return self.send(@model,x)
    case @parser.kernel_type
    when 0
      return linear_kernel(x)
    when 1
	    return gaussian_kernel_fixedint(x)  #currently only gaussian_kernel works
	    #return gaussian_kernel_gold(x)  #currently only gaussian_kernel works
	    #return gaussian_kernel(x)  #currently only gaussian_kernel works
    when 2
      return polynomial_kernel(x)
    else
      raise "invalid kernel type!"
    end
  end
end

if $0 == __FILE__
  #require 'scanf'
  require 'csvm_test'
  parser = AAAParser.new("tests/sonar")  
  svm    = C_SVM.new(parser)
  test_svm = CSVM_Tester.new("tests/sonar",svm)
  result = test_svm.run 
  
end
