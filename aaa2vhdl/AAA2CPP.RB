################################################################
# aaa2cpp.rb - C++ backend for cSVM
# takes a aaa file as input and generates a .h and .cpp file
# 
# Author: Phil Tomson
# Date:   January 14, 2005
################################################################
require 'aaaparser'
require 'erb'
class CPP_Generator
  
@@prog_info= <<ENDOFINFOSTRING
============================================================ 
=               PROGRAM     aaa2cpp                        = 
============================================================
= Authors and contributors:                                =
=  D.Anguita, A.Boni, S.Ridella, F.Rivieccio, D.Sterpi     =
=  Ruby Version: Phil Tomson                               =
=  Dept. of Biophysical and Electronic Engineering (DIBE)  =
=  University of Genova                                    =
=  Via Opera Pia 11a, Genova, ITALY                        =
=  contact: anguita@dibe.unige.it                          =
============================================================
ENDOFINFOSTRING

#h_file has embedded Ruby (uses erb)
@@h_file= <<ENDOFHFILE
//=============================================================!
//=                        module cSVM                        =!
//=            this file is generated automatically           =!
//=           (C) DIBE - University of Genova, Italy          =!
//=           <%= Time.now %>   
//=============================================================!
//= Authors and contributors:                                 =!
//=  D.Anguita, A.Boni, S.Ridella, F.Rivieccio, D.Sterpi      =!
//=                                                           =!
//=  Dept. of Biophysical and Electronic Engineering (DIBE)   =!
//=  University of Genova                                     =!
//=  Via Opera Pia 11a, Genova, ITALY                         =!
//=  contact: anguita@dibe.unige.it                           =!
//=============================================================!


#ifndef cSVM_H
#define cSVM_H

#define cSVM_ni    <%= @parser.num_features %>     //number of features
#define cSVM_nsv   <%= @parser.num_support_vectors %> //number of Support Vectors
#define cSVM_bias  <%= @parser.b %>      //bias
<% if @parser.kernel_type == 1 %>
#define cSVM_kRpar <%= @parser.gamma %>  //kernel real parameter
<% elsif @parser.kernel_type == 2 %>
#define cSVM_kRpar <%= @parser.gamma %> //kernel real parameter
#define cSVM_kIpar BOGUS      //kernel integer parameter
<%end%>


class cSVM {
  int ni;                //number of features
  int nsv;               //number of Support Vectors 
<% if @parser.kernel_type == 1 %>
  double kRpar;          //kernel real parameter
<% elsif @parser.kernel_type == 2 %>
  double kIpar;              //kernel integer parameter
  double kRpar;              //kernel real parameter
<% end %>
  double  bias;

public:
  double FF(double* x);
  cSVM();

};



static double cSVM_alpha[cSVM_nsv] = {   //Support Vector parameters
<%= @parser.y_vector.join(",") %>
};



static double cSVM_sv[cSVM_nsv][cSVM_ni]={   //Support Vectors
<% @parser.x_vector.each_with_index  do |x,i| %>
//Support vector number <%= i %>

    {
  <%= x.join(", ") %>

    } <%= if i < @parser.x_vector.length-1; ","; end %>
<% end %>
};

<% if norm_type > 0 %>
 
static double cSVM_cNorm[cSVM_ni][2]={  //normalization coefficients
<% @parser.norm_params.each_with_index do |p,i| %>
  {<%= p.join(", ") %> }<%= if i < @parser.norm_params.length-1; ","; end %> 
<% end %>
};
<% end %>
#endif
/****************************************************/
/* end of file                                      */
/****************************************************/
ENDOFHFILE

@@cpp_file= <<ENDOFCPPFILE
//=============================================================
//=                        module cSVM                        
//=            this file is generated automatically           
//=           (C) DIBE - University of Genova, Italy         
//=           <%= Time.now %> 
//=============================================================
//= Authors and contributors:                                 
//=  D.Anguita, A.Boni, S.Ridella, F.Rivieccio, D.Sterpi     
//=                                                         
//=  Dept. of Biophysical and Electronic Engineering (DIBE)  
//=  University of Genova                                    
//=  Via Opera Pia 11a, Genova, ITALY                        
//=  contact: anguita@dibe.unige.it                          
//=============================================================
#include<stdio.h>
#include<math.h>
#include "<%= @output_file%>.h"

double cSVM::FF(double* x){
  int i,j;                        //counter
  double f;                       //stimolus
<% if @parser.kernel_type == 0 %>
  double d;                       //dot product
<% end %>
<% if @parser.kernel_type == 1 %>
  double k;                       //kernel value
<% end %>
<% if @parser.kernel_type == 2 %>
  double dotii;                   // dot product 1
  double dotjj;                   // dot product 2
  double dotij;                   // dot product 3
<% end %>
<% if norm_type > 0 %>
  double x_norm[cSVM_ni];         //Normalized Data

  for(i=0;i<ni;i++)
    x_norm[i]=cSVM_cNorm[i][0]*x[i]+cSVM_cNorm[i][1];
  f=0;
  for(i=0;i<nsv;i++){
  <% case kernel_type; when 0 %>
  //--- kernel lineare %>
    d=0;
    for(j=0;j<ni;j++){
      d+=x_norm[j]*cSVM_sv[i][j];
    }
    f=f+d*cSVM_alpha[i];
  <% when 1 %>
    //--- kernel gaussian 
    k=0.0;
    for(j=0;j<ni;j++){
      k+=(x_norm[j]-cSVM_sv[i][j])*(x_norm[j]-cSVM_sv[i][j]);
    }
    f+=cSVM_alpha[i]*exp(-k*cSVM_kRpar/cSVM_ni);
  <% when 2 %>
    //--- kernel polynomial 
    dotii = 0; 
    dotjj = 0;
    dotij = 0;
    for(j=0;j<ni;j++){
      dotij+=x_norm[j]*cSVM_sv[i][j];
      dotii+=x_norm[j]*x_norm[j];
      dotjj+=cSVM_sv[i][j]*cSVM_sv[i][j];
    }
   f+=cSVM_alpha[i]*pow((dotij+cSVM_kRpar),cSVM_kIpar)/sqrt(pow((dotii+cSVM_kRpar),cSVM_kIpar)*pow((dotjj+cSVM_kRpar),cSVM_kIpar));")')
  <% end %>
<% elsif norm_type == 0 %>
<%# !! ------------ NO Normalization %>

  f=0;
  for(i=0;i<nsv;i++){
  <% case kernel_type; when 0 %>
  //--- kernel linear
    d=0;
    for(j=0;j<ni;j++){
      d+=x[j]*cSVMsv[i][j];
    }
    f=f+d*cSVM_alpha[i];
  <% when 1 %>
  //--- kernel gaussian 
    k=0.0;
    for(j=0;j<ni;j++){
      k+=(x[j]-cSVM_sv[i][j])*(x[j]-cSVM_sv[i][j]);
    }
    f+=cSVM_alpha[i]*exp(-k*kRpar/ni);
  <% when 2 %>
  //--- kernel polinomial 
    dotii = 0; 
    dotjj = 0;
    dotij = 0;
    for(j=0;j<ni;j++){
      dotij+=x[j]*cSVM_sv[i][j];
      dotii+=x[j]*x[j];
      dotjj+=cSVM_sv[i][j]*cSVM_sv[i][j];
    }
    f+=cSVM_alpha[i]*pow((dotij+kRpar),kIpar)/sqrt(pow((dotii+kRpar),kIpar)*pow((dotjj+kRpar),kIpar));
  <% end %>
<% end %>
} 
  return f+=bias;
}

cSVM::cSVM(){
  ni = cSVM_ni;
  nsv = cSVM_nsv;
  bias = cSVM_bias;
<% if kernel_type == 1 %>
  kRpar = cSVM_kRpar;
<% end %>
<% if kernel_type == 2 %>
 write(77,'(" kRpar = cSVM_kRpar;")')
 write(77,'(" kIpar = cSVM_kIpar;")')
<% end %>
}

/****************************************************/
/* end of file                                      */
/****************************************************/
ENDOFCPPFILE


  def initialize(aaaFile,outputFile)
    puts @@prog_info
    @aaa_file = aaaFile
    @output_file = outputFile
    @parser = AAAParser.new("#{aaaFile}.aaa")
    hfile_out = ERB.new(@@h_file,0,">")
    outStr = hfile_out.result binding
    hfile = File.open("#{outputFile}.h","w")
    hfile << outStr
    hfile.close

    cpp_file_temp = ERB.new(@@cpp_file,0,">")
    outStr = cpp_file_temp.result binding
    cppfile = File.open("#{outputFile}.cpp","w")
    cppfile << outStr
    cppfile.close

  end

  attr_reader :parser

  def method_missing(meth_id,*args)
    #delegate to the parser:
    @parser.send meth_id, *args
  end
end

if $0 == __FILE__
  usage = "ruby aaa2cpp.rb <aaafile> <output>"
  aaaFile = ARGV[0]
  outputFile = ARGV[1]

  if (aaaFile == nil || outputFile == nil)
    puts usage
    exit
  end
  
  gen = CPP_Generator.new(aaaFile, outputFile)
  p gen.x_vector[0]
end
