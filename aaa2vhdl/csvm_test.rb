require 'scanf'
class CSVM_Tester
  def initialize(testfile,svm)
    @file     = testfile
    @svm    = svm
    @passfail = nil
    @known_errors = []
  end

  def read_val_file
    File.foreach("#{@file}.val") {|line|
      @known_errors << ((line =~ /ERROR/) != nil)
    }
  end

  def run
    x = []
    failures = 0
    i = 0
    read_val_file if File.exists? "#{@file}.val"
    File.foreach("#{@file}.tst") {|line|
      pass = false
      pass = true if line.strip =~ /1$/
      x = line.scanf("%f"*@svm.ni)
      puts x.join(",")
      answer = @svm.cSVM_FF x
      if (answer > 0 && pass) || (answer < 0 && !pass)
        puts "correct!"
      elsif (answer > 0 && !pass) || (answer < 0 && pass )
        if @known_errors[i]
          puts "wrong: but known error"
	  #failures += 1 if @known_errors[i]
        else
          puts "Wrong!"
          failures += 1 
        end
      end
      puts "answer is: #{answer} pass is: #{pass}"
      puts
      i+=1
    }
    puts "#{x.join(",")}"
    puts 
    puts "#{i} testcases were run"
    if failures > 0
      $stderr.puts "#{failures} Failure(s) found!!!!!!!!!!!!!!" 
      puts "#{failures} Failure(s) found!!!!!!!!!!!!!!" 
    end
    return failures == 0 #return true if no failures
  end

  def create_vhdl_tb
    vectfile = File.open("vectors","w")
    x = []
    failures = 0
    i = 0
    vectfile << "type test_vector is record\n"
    vectfile << "  xin_0: signed(XIN_DATA_BITS -1 downto 0); xin_1: signed(XIN_DATA_BITS -1 downto 0); pass: boolean;\n"
    vectfile << "end record;\n"
    vectfile << "type test_vector_array is array(natural range <>) of test_vector;\n"
    vectfile << "constant test_vectors: test_vector_array := (\n"
    vectors = []
    read_val_file if File.exists? "#{@file}.val"
    File.foreach("#{@file}.tst") {|line|
      if @known_errors[i] == true
        #puts "skip" #skip known errors
      else
        pass = false
        pass = true if line.strip =~ /1$/
        x = line.scanf("%f"*@svm.ni)
        x_norm = @svm.normalize(x)
      
        xin    = x_norm.map{|j| FixedPt.new(j,@svm.bits+2,@svm.binpt).to_bin }
        #puts xin.join(",") + "pass = #{pass}"
	vectors << "  (xin_0 => \"#{xin[0]}\", xin_1 => \"#{xin[1]}\", pass => #{pass}) #{i}"
      end

      i+=1
      next  

      answer = @svm.cSVM_FF x
      if (answer > 0 && pass) || (answer < 0 && !pass)
        puts "correct!"
      elsif (answer > 0 && !pass) || (answer < 0 && pass )
        if @known_errors[i]
          puts "wrong: but known error"
	  #failures += 1 if @known_errors[i]
        else
          puts "Wrong!"
          failures += 1 
        end
      end
      puts "answer is: #{answer} pass is: #{pass}"
      puts
    }
    vectfile << vectors.join(",\n")
    vectfile << "\n);\n"
    puts 
    puts "#{i} testcases were run"
    if failures > 0
      $stderr.puts "#{failures} Failure(s) found!!!!!!!!!!!!!!" 
      puts "#{failures} Failure(s) found!!!!!!!!!!!!!!" 
    end
    return failures == 0 #return true if no failures
  end

  #temporary way of creating HDL for cSVM
  def create_hdl
    x = []
    failures = 0
    i = 0
    read_val_file if File.exists? "#{@file}.val"
    File.foreach("#{@file}.tst") {|line|
      pass = false
      pass = true if line.strip =~ /1$/
      x = line.scanf("%f"*@svm.ni)
      puts x.join(",")
      @svm.to_vhdl x # x from test file
      exit
    }
    #puts "#{x.join(",")}"
    #puts 
    #puts "#{i} testcases were run"
    #$stderr.puts "#{failures} Failure(s) found!!!!!!!!!!!!!!" if failures > 0
    #return failures == 0 #return true if no failures
  end

end
