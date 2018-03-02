#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <ctype.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <string.h>
#define RCV_FIFO_NAME "np1"
#define SND_FIFO_NAME "np2"
#define MAX_BUF_SIZE 80
static int i = 0;
static int result = 0;
static int current_address=0 ;
static int get_addr_ok = 1;
static int fdr;
static int fdw;
static int r_opened = 0;
static int w_opened = 0;
char* strs[3] = { "11","12","15" };


void setup_named_rcv_pipe()
{
  if((mkfifo(RCV_FIFO_NAME,(S_IRUSR|S_IWUSR) ) == -1)&&(errno !=EEXIST)){
    fprintf(stderr,"Could not create (receive) named pipe");
    exit(1);
  }

  if(!r_opened){
    /* Open the pipe for reading */
    //fdr = open(RCV_FIFO_NAME, O_RDONLY|O_NONBLOCK);
    printf("open(%s,O_RDONLY)\n",RCV_FIFO_NAME);
    fdr = open(RCV_FIFO_NAME, O_RDONLY);
    r_opened = 1;
  }
}
void setup_named_send_pipe()
{
  if((mkfifo(SND_FIFO_NAME,(S_IRUSR|S_IWUSR) ) == -1)&&(errno !=EEXIST)){
    fprintf(stderr,"Could not create (send) named pipe");
    exit(1);
  }
  if(!w_opened){
    /* Open the pipe for reading */
    printf("open(%s,O_WRONLY)\n",SND_FIFO_NAME);
    fdw = open(SND_FIFO_NAME, O_WRONLY);
    w_opened = 1;
  }
}

int get_addr(int x)
{
  //but you shouldn't really get another address until 
  //data gets sent back
  printf("get_addr()\n");
  long address = 0;
  int num_bytes_read;
  char buf[MAX_BUF_SIZE];
  setup_named_rcv_pipe();
  setup_named_send_pipe();
  /* Open the pipe for reading */
  num_bytes_read = read(fdr, buf, MAX_BUF_SIZE);
  buf[num_bytes_read] = '\0';
  //TESTING ONLY: strcpy(buf,"4567");
  //translate string in buf to an integer: 
  //address = (atoi(strs[i]));  
  address = strtol(buf,0,0);
  //sleep(1);
  printf("get_addr returning: %d\n",address);
  return address;

}

int send_result(int res)
{
  char buf[MAX_BUF_SIZE];
  setup_named_send_pipe();
  //transform result from int to string:
  sprintf(buf,"%d",res);
  printf("Sending result: %d\n",res); 
  result = res;
  write(fdw,buf,strlen(buf));
  //sleep(1);
}

/*
void set_address(int addr)
{
  printf("external_func: set_address(%d)\n",addr);
  address = addr;
  printf("external_func: address is now: %d\n",address);
}

int get_result()
{
  return result;
}

*/
