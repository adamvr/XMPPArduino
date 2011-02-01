#ifndef _H_XMPP_CLIENT
#define _H_XMPP_CLIENT

#include <Base64.h>
#include <Ethernet.h>
#include <string.h>
#include <stdarg.h>
#include <avr/pgmspace.h>

enum XMPPState {
  INIT,
  AUTH,
  AUTH_STREAM,
  BIND,
  SESS,
  READY,
  WAIT
};

class XMPPClient {
    private:
	Client client;
	char *username;
	char *server;
	char *password;
	char *resource;
	XMPPState state;

	int sendTemplate(const prog_char *strTemplate, int fillLen, ...);

	int openStream(char *server);
	int authenticate(char *username, char *password);
	int bindResource(char *resource);
	int openSession(char *server);

	void processInput();
	int stateAction();


    public:
	XMPPClient();
	XMPPClient(uint8_t *ip, uint16_t port);

	int connect(char *username, char *server, char *resource, char *password);
	int connect(char *jid, char *password);

	int sendMessage(char *recipientJid, char *message);
	int sendPresence();

	int close();

};

#endif /* _H_XMPP_CLIENT */
