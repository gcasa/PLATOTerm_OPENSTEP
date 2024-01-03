/**
 * PLATOTerm64 - A PLATO Terminal for the Commodore 64
 * Based on Steve Peltz's PAD
 * 
 * Author: Thomas Cherryhomes <thom.cherryhomes at gmail dot com>
 *
 * io.h - Input/output functions (serial/ethernet)
 */

#include <sys/types.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/file.h>
#include <errno.h>
#include <fcntl.h>
#include <arpa/inet.h>
#include <strings.h>
#include <fcntl.h>
#include <unistd.h>

#include "io.h"
#include "protocol.h"

//#define TRUE 1
//#define FALSE 0

int rxlen;
padByte rxBuf[32768];
padByte replaybuf[32768];
int replaylen;
struct sockaddr_in sa;
int sockfd;
int fileflags;
struct hostent *hp;

void io_inject(b,l)
padByte* b;
int l;
{
}

/**
 * void io_init() - Set-up the I/O
 */
void io_init(hostname,port)
char *hostname;
unsigned short port;
{
	hp = gethostbyname(hostname);

	if (hp == 0) 
	{
		sa.sin_addr.s_addr = inet_addr(hostname);	
	}
	else	
		bcopy(hp->h_addr,(char *)&sa.sin_addr, hp->h_length);

        sockfd = socket(AF_INET, SOCK_STREAM, 0);        
        sa.sin_family = AF_INET;       
	sa.sin_port = htons(port);
        connect(sockfd,(struct sockaddr *)&sa, sizeof(sa)); 	

	fileflags = fcntl(sockfd,F_GETFL,0);
	fcntl(sockfd,F_SETFL,fileflags|FNDELAY);
}

/**
 * void io_send_byte(b) - Send specified byte out
 */
void io_send_byte(b)
unsigned char b;
{
	write(sockfd, &b, 1);
}

/**
 * void io_main() - The IO main loop
 */
void io_main()
{
	rxlen = read(sockfd, &rxBuf[0], sizeof(rxBuf));
	if (rxlen < 0 )
		return;

	/* copy to replay buffer */
	bcopy(&rxBuf[0],&replaybuf[replaylen],rxlen);
	replaylen += rxlen;

	ShowPLATO(&rxBuf[0], rxlen);	
}

/**
 * Replay
 */
void io_replay()
{
	if (replaylen>0)
		ShowPLATO(&replaybuf[0],replaylen);
}

/**
 * Clear replay buffer
 */
void io_replay_clear()
{
	if (replaylen>0)
	{
		memset(&replaybuf[0],0,sizeof(replaybuf));
		replaylen=0;
	}
}

/**
 * void io_done() - Called to close I/O
 */
void io_done()
{
	close(sockfd);
}
