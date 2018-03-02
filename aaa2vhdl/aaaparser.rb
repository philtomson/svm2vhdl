####################################################
# aaaparser.rb
# parses the output of cSVM
# Phil Tomson      January 12, 2005
####################################################

##############################################################
# TODO: create a generic aaa parser first, then specialize
# for creating VHDL output (essentially a VHDL backend for
# cSVM.)
##############################################################

require 'scanf'

class AAAParser
  attr_reader :kernel_type, :x_vector, :b, :y_vector, :norm_type, :norm_params
  attr_reader :num_features, :num_support_vectors, :gamma
  def initialize( aaa_file)
    @numKernelParams = nil
    @kernel_type  = nil
    @num_features = nil
    @num_support_vectors = nil
    @x_vector = []
    @gamma = nil
    @y_vector = []
    @b = nil
    @aaa_file = aaa_file
    parse
  end

  def parse
    f = File.open( "#{@aaa_file}.aaa") { |file|
      @kernel_type = file.gets.scanf("%d")[0] 
      @numKernelParams = file.gets.strip.scanf("%d")[0]
      puts "kerneltype is: #@kernel_type"
      puts "numKernelParams is: #@numKernelParams #{@numKernelParams.class}"
      @gamma = file.gets.scanf("%f")[0]
      puts "gamma is: #@gamma"
      @b = file.gets.scanf("%f")[0]
      puts "b is: #@b"
      @num_support_vectors = file.gets.scanf("%d")[0]
      @num_support_vectors.times {|i|
        uselessNum,  y_num = file.gets.scanf("%d %f")
	@y_vector << y_num
      }
      @num_features = file.gets.scanf("%d")[0]
      puts "num_support_vectors is: #{@num_support_vectors}"
      puts "num_features is: #{@num_features}"
      @num_support_vectors.times {|i|
        x_array = []
	while x_array.length < @num_features
          x_array << file.gets.scanf("%f") {|f| f[0] }.flatten 
	  #puts "x_array.length is: #{x_array.length} @num_support_vectors is: #{@num_support_vectors}" 
	  x_array.flatten!
        end
	x_array.flatten!
	@x_vector << x_array
      }
      #now get the kind of normalization:
      @norm_type = file.gets.scanf("%d")[0]
      puts "norm_type is: #@norm_type"
      #get the number of norm params:
      numNormParams = file.gets.scanf("%d")[0]
      puts "numNormParams is: #{numNormParams}"
      @norm_params = []
      @num_features.times {|i|
        @norm_params << file.gets.scanf("%f%f")
      }
    }
  end
end


