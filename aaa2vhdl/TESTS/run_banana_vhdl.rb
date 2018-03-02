$: << '..'

DATABITS         = 16
BINPT            = DATABITS
EXPLUT_ADDR_BITS = 7  
EXPLUT_MIN_VAL   = -12.25

require 'lookuptable'
module LookupTableParams
  def init_table
	  #Classifier.new((-13.5/@fKparam),0.0004,@fKparam,@multiplier)  #works for banana with gaussian_kernel
	  Classifier.new((-13.5/@fKparam),0.0004,@fKparam) #try this
  end
 
  def init_lut
    LookupTable.new(EXPLUT_MIN_VAL,@fKparam,EXPLUT_ADDR_BITS,DATABITS)
  end
end

require 'aaaparser'
require 'csvm'
require 'csvm_test'
test     = "banana"
parser   = AAAParser.new(test)
svm      = C_SVM.new(parser,DATABITS,BINPT)
test_svm = CSVM_Tester.new(test,svm)
result   = test_svm.create_hdl

