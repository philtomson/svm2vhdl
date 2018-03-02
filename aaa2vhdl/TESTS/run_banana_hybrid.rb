$: << '..'

DATABITS = 16
ADDRBITS = 7
require 'lookuptable'
module LookupTableParams
 
  def init_lut
    #LookupTable.new(-12.5,@fKparam,10,18)
    LookupTable.new(-12.25,@fKparam,ADDRBITS,DATABITS)
    #LookupTable.new(-12.5,@fKparam,5,16)
  end
end

require 'aaaparser'
require 'csvm'
require 'csvm_test'
test     = "banana"
#first fork off the 'test_comm' VHDL part:
fork do
  system("./test_comm")
end
parser   = AAAParser.new(test)
#svm      = C_SVM.new(parser,19,18)
svm      = C_SVM.new(parser,DATABITS,DATABITS,:gaussian_kernel_hybrid)
test_svm = CSVM_Tester.new(test,svm)
result   = test_svm.run

