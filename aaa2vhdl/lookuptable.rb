require 'rangeint'
class LookupTable
  attr_accessor :min,:addr_bits,:data_bits,:resolution,:table
  def initialize(min_val,scale,addr_bits,data_bits )
    @min = min_val/scale
    @scale = scale  # /scale #NOTE: Why was the / here?
    puts "min is: #{@min}"
    @addr_bits = addr_bits
    @data_bits = data_bits
    #@resolution,rem= (@min.abs).divmod(2**addr_bits-1)
    @resolution = (@min.abs)/((2**addr_bits).to_f)
    puts "resolution is: #@resolution"
    @num_cases = (2**addr_bits)-1
    puts "num_cases is: #{@num_cases}"
    @table = []
    create
  end

  def [](i)
    return @table[i]
  end

  def size
    return @table.size
  end

  def to_vhdl
    require 'lutgen'
    vhdlgen = LutGen.new("explut",@addr_bits,@data_bits,@table,@data_bits)
  end

  private
  def create
    value = @min
    (0..@num_cases).each {|i|
      @table <<  FixedPt.new(Math.exp(value*@scale),@data_bits,@data_bits)
      value += @resolution
      puts "value is: #{value}" if $DEBUG
    }
    @table.reverse!
  end

end

if $0 == __FILE__
  #lut = LookupTable.new(-10.0*(9.99999/184),6,8) 
  scale = 50
  lut = LookupTable.new(-12.5,scale,10,18)
  puts "lut.res = #{lut.resolution}"
  puts lut.to_vhdl
end
