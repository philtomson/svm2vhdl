$: << '..'

DATABITS = 16
ADDRBITS = 7
require 'lookuptable'
module LookupTableParams
 
  def init_lut
    #LookupTable.new(-12.5,@fKparam,10,18)
    LookupTable.new(-12.5,@fKparam,ADDRBITS,DATABITS)
    #LookupTable.new(-12.5,@fKparam,5,16)
  end
end

require 'aaaparser'
require 'csvm'
require 'csvm_test'
test     = "banana"
parser   = AAAParser.new(test)
#svm      = C_SVM.new(parser,19,18)
svm      = C_SVM.new(parser,DATABITS,DATABITS)
test_svm = CSVM_Tester.new(test,svm)
result   = test_svm.create_vhdl_tb

