//=============================================================
//=                        module cSVM                        
//=            this file is generated automatically           
//=           (C) DIBE - University of Genova, Italy         
//=           Fri May 06 03:32:33 EDT 2005 
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
#include "banana.h"

double cSVM::FF(double* x){
  int i,j;                        //counter
  double f;                       //stimolus
  double k;                       //kernel value
  double x_norm[cSVM_ni];         //Normalized Data

  for(i=0;i<ni;i++)
    x_norm[i]=cSVM_cNorm[i][0]*x[i]+cSVM_cNorm[i][1];
  f=0;
  for(i=0;i<nsv;i++){
      //--- kernel gaussian 
    k=0.0;
    for(j=0;j<ni;j++){
      k+=(x_norm[j]-cSVM_sv[i][j])*(x_norm[j]-cSVM_sv[i][j]);
    }
    f+=cSVM_alpha[i]*exp(-k*cSVM_kRpar/cSVM_ni);
  } 
  return f+=bias;
}

cSVM::cSVM(){
  ni = cSVM_ni;
  nsv = cSVM_nsv;
  bias = cSVM_bias;
  kRpar = cSVM_kRpar;
}

/****************************************************/
/* end of file                                      */
/****************************************************/
