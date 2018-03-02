$: << '..'
require 'lookuptable'
module LookupTableParams
  def init_table
	  #Classifier.new((-12.0/@fKparam),(2.0),@fKparam, @multiplier)  
    Classifier.new((-12.0/@fKparam),(2.0),@fKparam)  
  end

  def init_lut
	  #LookupTable.new(-12.0,@fKparam,6,18) 
    LookupTable.new(-10.666666666667,@fKparam,6,18) 
  end
end

require 'aaaparser'
require 'csvm'
require 'csvm_test'
test     = "sonar"
parser   = AAAParser.new(test)
svm      = C_SVM.new(parser,19,18)
test_svm = CSVM_Tester.new(test,svm)
result   = test_svm.run

