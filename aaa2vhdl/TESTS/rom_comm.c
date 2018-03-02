#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <ctype.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#include "ruby.h"

//extern int result;
//extern int address;

#define RCV_FIFO_NAME "np2"
#define SND_FIFO_NAME "np1"
static int fdw;
void send_address(int addr)
{
  char buf[80];
  printf("sending address(%d)\n",addr);
  
  //transform addr from int to string
  sprintf(buf,"%d",addr);
  printf("sending address(%s)(string length is:%d )\n",buf,strlen(buf));
  //fdw = open(SND_FIFO_NAME,O_WRONLY);
  //write to pipe:
  write(fdw,buf,strlen(buf));
  printf("after write\n");
}

static int fdr;
static int r_opened = 0;
static int w_opened = 0;

static void setup_named_rcv_pipe()
{
  //if((mkfifo(RCV_FIFO_NAME,(S_IRUSR|S_IWUSR) ) == -1)&&(errno !=EEXIST)){
  if((mkfifo(RCV_FIFO_NAME,0666 ) == -1)&&(errno !=EEXIST)){
    fprintf(stderr,"Could not create (receive) named pipe");
    exit(1);
  }

  if(!r_opened){
    /* Open the pipe for reading */
    printf("before open(%s, O_RDONLY)\n",RCV_FIFO_NAME);
    //fdr = open(RCV_FIFO_NAME, O_RDONLY|O_NONBLOCK);
    fdr = open(RCV_FIFO_NAME, O_RDONLY);
    printf("after open()\n");
    r_opened = 1;
  }
}

static void setup_named_snd_pipe()
{
  if((mkfifo(SND_FIFO_NAME,(S_IRUSR|S_IWUSR) ) == -1)&&(errno !=EEXIST)){
    fprintf(stderr,"Could not create (receive) named pipe");
    exit(1);
  }
  if(!w_opened){
    /* Open the pipe for writing */
    printf("snd: before open(%s,O_WRONLY)\n",SND_FIFO_NAME);
    fdw = open(SND_FIFO_NAME, O_WRONLY);
    //fdr = open(SND_FIFO_NAME, O_RDONLY);
    printf("snd: after open()\n");
    w_opened = 1;
  }

}
static void  setup_named_pipes()
{
  setup_named_snd_pipe();
  setup_named_rcv_pipe();
}
 
static int receive_result()
{
  printf("receive_result()\n");
  long result = 0;
  int num_bytes_read;
  char buf[80];
  //setup_named_rcv_pipe();
  printf("waiting to receive result\n");
  num_bytes_read = read(fdr, buf, 80);
  buf[num_bytes_read] = '\0';
  result = atoi(buf);
  return result;

}

static VALUE rc_init(VALUE self)
{
  setup_named_pipes(); 
  //receive_result(); //clear the pipe (doesn't work)
  return self;
}

static VALUE rc_get_expval(VALUE self, VALUE addr)
{
   send_address(NUM2INT(addr)); 
   return(INT2NUM(receive_result()));
}

VALUE cComm;

void Init_RomComm(){
  cComm = rb_define_class("RomComm",rb_cObject);
  rb_define_method(cComm,"initialize", rc_init,0);
  rb_define_method(cComm,"get_expval", rc_get_expval,1);
}

