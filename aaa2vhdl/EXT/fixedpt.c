#include <string.h>
#include <stdio.h>
#include <math.h>
#include "ruby.h"
static int id_rawval;
static int id_ival;
static int id_bits;
static int id_binpt;
static int id_sign;
static int id_maxint;
//static int sign;
static VALUE minus_one;
static VALUE positive_one;


static VALUE fp_check_sign(VALUE self, VALUE val)
{
  double i = NUM2DBL(val);
  //printf("i is: %f\n",i);
  int retval;

  if(i < 0.0) {
   // retval = -1;
   rb_iv_set(self,"@sign",minus_one);
  }else {
   // retval = 1;
   rb_iv_set(self,"@sign",positive_one);
  }
  //return INT2FIX(retval);
  return self;
}

static VALUE fix_abs(VALUE fix)
{
    long i = FIX2LONG(fix);

    if (i < 0) i = -i;

    return LONG2NUM(i);
}


static VALUE rfp_init(VALUE self, VALUE rawval, VALUE total_bits, VALUE binpt)
{
  VALUE sign;
  rb_iv_set(self,"@rawval",fix_abs(rawval));
  rb_iv_set(self,"@bits",total_bits);
  rb_iv_set(self,"@binpt",binpt);
  if( FIX2INT(rawval) < 0){
    sign = INT2FIX(-1);
  } else {
    sign = INT2FIX(1);
  }
  rb_iv_set(self,"@sign",sign);
  return self;
}

static VALUE rfp_rawval(VALUE self)
{
  return rb_iv_get(self,"@rawval");
}

static VALUE rfp_bits(VALUE self)
{
  return rb_iv_get(self,"@bits");
}

static VALUE rfp_binpt(VALUE self)
{
  return rb_iv_get(self,"@binpt");
}

static VALUE rfp_sign(VALUE self)
{
  return rb_iv_get(self,"@sign");
}
//FixedPt methods


static VALUE fp_rawval(VALUE self)
{
  return rb_iv_get(self,"@ival");
}
static VALUE fp_ival(VALUE self)
{
  return rb_iv_get(self,"@ival");
}

static VALUE fp_bits(VALUE self)
{
  return rb_iv_get(self,"@bits");
}

static VALUE fp_binpt(VALUE self)
{
  return rb_iv_get(self,"@binpt");
}

static VALUE fp_sign(VALUE self)
{
  return rb_iv_get(self,"@sign");
}

static VALUE fp_maxint(VALUE self)
{
  return rb_iv_get(self,"@maxint");
}

static VALUE fp_value(VALUE self)
{
  //int sign   = FIX2INT(fp_sign(self));
  long sign   = FIX2LONG(fp_sign(self));
  //int ival   = FIX2INT(fp_ival(self));

  long ival   = FIX2LONG(fp_ival(self));
  //return (INT2FIX(ival * sign));
  return (LONG2FIX(ival * sign));
}

static VALUE fp_check_for_overflow(VALUE self, VALUE result)
{
  int val    = FIX2INT(result);
  int binpt  = FIX2INT(fp_binpt(self));
  int bits   = FIX2INT(fp_bits(self));
  long maxint= FIX2LONG(fp_maxint(self));
  long retval;
  if(binpt == bits) return result;
  if((val >> binpt)  > maxint ){
    //printf("OVERFLOW\n"); 
    result = LONG2FIX(pow(2,(bits-1)));
  }
  return result;
}

static VALUE fp_check_sizes(VALUE self, VALUE other)
{
  int this_binpt  = FIX2INT(fp_binpt(self));
  int other_binpt = FIX2INT(fp_binpt(other));
  if(this_binpt != other_binpt ){
    rb_raise(rb_eRuntimeError, "binary points don't match: ( %d != %d)\n",this_binpt, other_binpt); 
  }
  return self; 
}

static VALUE fp_multiply(VALUE self, VALUE other)
{
  VALUE result;

  fp_check_sizes(self,other);
  result = (FIX2INT(fp_value(self)) * FIX2INT(fp_value(other)) >> FIX2INT(fp_binpt(self)) );
  result = fp_check_for_overflow(self,LONG2FIX(result)); 
  return result;
}

static VALUE fp_init(VALUE self, VALUE val, VALUE total_bits, VALUE binpt)
{
  char* name = rb_class2name(rb_obj_class(val));
  switch (TYPE(val)) {
    case T_FIXNUM:
      rb_funcall(self,rb_intern("construct_from_fixnum"),3,val,total_bits,binpt);
      /*
      printf("T_FIXNUM:\n");
      rb_iv_set(self,"@rawval",val);
      rb_iv_set(self,"@bits",total_bits);
      rb_iv_set(self,"@binpt",binpt);
      rb_iv_set(self,"@sign", INT2FIX(check_sign(val)));
      */
      break;
    case T_FLOAT:
      //printf("T_FLOAT:\n");
      rb_funcall(self,rb_intern("construct_from_float"),3,val,total_bits,binpt);
      break;
    default:
      //printf("*FixedPT:\n");
      if( ! strcmp(name,"RawFixedPt") ){
        //printf("RawFixedPT:\n");
        /*
        rb_iv_set(self,"@ival",rb_funcall(val,id_rawval,0) );
        rb_iv_set(self,"@bits",rb_funcall(val,id_bits,0) );
        rb_iv_set(self,"@binpt",rb_funcall(val,id_binpt,0) );
	rb_iv_set(self,"@sign",rb_funcall(val,id_sign,0) );
	*/
        //this should be a bit faster:
        rb_iv_set(self,"@ival",rfp_rawval(val));
        rb_iv_set(self,"@bits",rfp_bits(val));
        rb_iv_set(self,"@binpt",rfp_binpt(val));
	rb_iv_set(self,"@sign",rfp_sign(val));

      }else if( ! strcmp(name,"FixedPt") ){
        //printf("FixedPT:\n");
        rb_iv_set(self,"@ival",fp_ival(val));
        rb_iv_set(self,"@bits",fp_bits(val));
        rb_iv_set(self,"@binpt",fp_binpt(val));
	rb_iv_set(self,"@sign",fp_sign(val));
      }else {
        rb_raise(rb_eTypeError, "not a valid value");
      }
      break;
  }
  int diff= FIX2INT(rb_iv_get(self,"@bits"))-FIX2INT(rb_iv_get(self,"@binpt"));
  rb_iv_set(self,"@maxint", LONG2FIX((pow(2,diff ))-1 ) ) ;
  return self;
}
/*
static VALUE fp_init(VALUE self, VALUE val, VALUE total_bits, VALUE binpt)
{
   //rb_funcall(self,rb_intern("from_fixnum"),3,val,total_bits,binpt);
   char* name = rb_class2name(rb_obj_class(val));
   int type = TYPE(val);
   printf("type: %d\n",type);
   printf("class name: %s\n",name);
   printf("T_FIXNUM:\n");
   rb_iv_set(self,"@rawval",val);
   rb_iv_set(self,"@bits",total_bits);
   rb_iv_set(self,"@binpt",binpt);
   rb_iv_set(self,"@sign", INT2FIX(check_sign(val)));
   return self;
}
*/

VALUE cRawFixedPt;
VALUE cFixedPt;

void Init_fixedpt() {
  //class RawFixedPt
  cRawFixedPt = rb_define_class("RawFixedPt", rb_cObject);
  rb_define_method(cRawFixedPt,"initialize", rfp_init, 3);
  rb_define_method(cRawFixedPt,"rawval",rfp_rawval,0);
  rb_define_method(cRawFixedPt,"bits",rfp_bits,0);
  rb_define_method(cRawFixedPt,"binpt",rfp_binpt,0);
  rb_define_method(cRawFixedPt,"sign",rfp_sign,0);

  //class FixedPt
  cFixedPt = rb_define_class("FixedPt",rb_cObject);
  rb_define_method(cFixedPt,"initialize",fp_init,3);
  rb_define_method(cFixedPt,"check_sign",fp_check_sign,1);
  rb_define_method(cFixedPt,"rawval",fp_rawval,0);
  rb_define_method(cFixedPt,"ival",fp_ival,0);
  rb_define_method(cFixedPt,"bits",fp_bits,0);
  rb_define_method(cFixedPt,"binpt",fp_binpt,0);
  rb_define_method(cFixedPt,"sign",fp_sign,0);
  rb_define_method(cFixedPt,"maxint",fp_maxint,0);
  rb_define_method(cFixedPt,"check_sizes",fp_check_sizes,1);
  rb_define_method(cFixedPt,"value",fp_value,0);
  rb_define_method(cFixedPt,"multiply",fp_value,1);
  rb_define_method(cFixedPt,"check_for_overflow",fp_check_for_overflow,1);
  //

  //create symbols here:
  id_rawval    = rb_intern("rawval");
  id_ival      = rb_intern("ival");
  id_bits      = rb_intern("bits");
  id_binpt     = rb_intern("binpt");
  id_sign      = rb_intern("sign");
  id_maxint    = rb_intern("maxint");

  minus_one    = INT2NUM(-1);
  positive_one = INT2NUM(1);
}


