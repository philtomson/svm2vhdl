require 'RomComm.so'

def communicate
  rc = RomComm.new
  10.times do |i|
    puts rc.get_expval(i)
  end
end

communicate
