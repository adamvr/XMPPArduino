#include <Base64.h>
#include <SPI.h>
#include <Ethernet.h>
#include <stdarg.h>
#include <avr/pgmspace.h>

const prog_char PROGMEM open_stream_template[] = "<stream:stream " 
                             "xmlns='jabber:client' " 
                             "xmlns:stream='http://etherx.jabber.org/streams' " 
                             "to='%s' " 
                             "version='1.0'>";
const prog_char PROGMEM plain_auth_template[] = "<auth " 
                            "xmlns='urn:ietf:params:xml:ns:xmpp-sasl' " 
                            "mechanism='PLAIN'>" 
                            "%s" 
                            "</auth>";
const prog_char PROGMEM bind_template[] = "<iq " 
                      "type='set' " 
                      "id='bind_1'>" 
                      "<bind " 
                      "xmlns='urn:ietf:params:xml:ns:xmpp-bind'>" 
                      "<resource>%s</resource>" 
                      "</bind>" 
                      "</iq>";
const prog_char PROGMEM session_request_template[] = "<iq " 
                                 "to='%s' " 
                                 "type='set' " 
                                 "id='ard_sess'>" 
                                 "<session " 
                                 "xmlns='urn:ietf:params:xml:ns:xmpp-session' />" 
                                 "</iq>"

const prog_char PROGMEM presence_template[] = "<presence>" 
                          "<show/>" 
                          "</presence>"
                          
const prog_char PROGMEM message_template[] = "<message " 
                         "to='%s' " 
                         "xmlns='jabber:client' " 
                         "type='chat' " 
                         "id='msg' " 
                         "xml:lang='en'>" 
                         "<body>%s</body>" 
                         "</message>"
enum XMPPState {
  INIT,
  AUTH,
  AUTH_STREAM,
  BIND,
  SESS,
  READY,
  WAIT
};

struct XMPPTransitionTableEntry {
  XMPPState currentState;
  XMPPState nextState;
  char *keyword;
};

XMPPTransitionTableEntry connTable[] = {{INIT, AUTH, "PLAIN"},
                                        {AUTH, AUTH_STREAM, "success"},
                                        {AUTH_STREAM, BIND, "bind"},
                                        {BIND, SESS, "jid"},
                                        {SESS, READY, "session"},
                                        {READY, WAIT, ""},
                                        {WAIT, WAIT, ""}};
int connTableSize = 6;

/*******/
/* XMPP Instances */
/*******/
XMPPState state = INIT;

char username[] = "adam";
char server[] = "test.awg";
char resource[] = "arduino";
char password[] = "avrud0";

/*******/
/* Function prototypes */
/*******/
void xmpp_stream(char *server);
void xmpp_auth(char *username, char *password);
void xmpp_bind(char *resource);
void xmpp_session(char *server);
void xmpp_presence();
void xmpp_mess(char *recipient, char *message);
void sendTemplate(char *temp, int fillLen, ...);
void sendRaw(char *message);

void process_input();


/*******/
/* XML parsing */
/*******/
// # DEFINES here later maybe?

/*******/
/* Ethernet */
/*******/
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192,168,2,11 };
byte serverIp[] = { 192,168,2,1 };

Client client(serverIp, 5222);

extern int __bss_end;
extern void *__brkval;

int get_free_memory()
{
  int free_memory;

  if((int)__brkval == 0)
    free_memory = ((int)&free_memory) - ((int)&__bss_end);
  else
    free_memory = ((int)&free_memory) - ((int)__brkval);

  return free_memory;
}

void setup() {
  Serial.begin(9600);
  Serial.println(get_free_memory());
  
  Ethernet.begin(mac, ip);
  
  delay(1000);
 
  Serial.println("Conn...");
  while(!client.connect()) {
    Serial.println("Ret...");
    delay(1000);
  }
  
  Serial.println("Connected");
}

void loop() {
 Serial.print("State = ");
 Serial.println(state);
 Serial.print("Free memory = ");
 Serial.print(get_free_memory());
 Serial.println(" bytes");

 switch(state) {
  case INIT:
    xmpp_stream(server);
    break;
  case AUTH:
    xmpp_auth(username, password);
    break;
  case AUTH_STREAM:
    xmpp_stream(server);
    //state = BIND;
    break;
  case BIND:
    xmpp_bind(resource);
    //state = SESS;
    break;
  case SESS:
    xmpp_session(server);
    //state = READY;    
    break;
  case READY:
    xmpp_presence();
    //state = WAIT;
    break;
  case WAIT:
    while(1) {
    xmpp_mess("admin@temp.awg", "HELLO FAGFACE");
    delay(1000);
    }
    break;
  default:
    break;
 }
 process_input(); 
}


void sendRaw(char *message) {
  Serial.println(message);
  Serial.println(get_free_memory());
  client.write(message);
}

void sendTemp(prog_char *temp_P, int fillLen, ...) {  
  /* Set up some buffers and calculate the template length */
  int tempLen = strlen_P(temp_P);
  char temp[tempLen];
  char buffer[tempLen + fillLen];
  va_list args;

  strcpy_P(temp, temp_P);

  va_start(args, fillLen);
  vsprintf(buffer, temp, args);
  sendRaw(buffer);
} 

void xmpp_stream(char *server) {
  sendTemp(open_stream_template, strlen(server), server);
}

void xmpp_auth(char *username, char *password) {
  int plainStringLen = strlen(username) + strlen(password) + 2;
  int encStringLen = base64_enc_len(plainStringLen);
  char plainString[plainStringLen];
  char encString[encStringLen];
  
  /* Set up our plain auth string. It's in the form:
   * "\0username\0password"
   * where \0 is the null character
   */
  memset(plainString, '\0', plainStringLen);
  memcpy(plainString + 1, username, strlen(username));
  memcpy(plainString + 2 + strlen(username), password, strlen(password));
  
  /* Encode to base64 */
  base64_encode(encString, plainString, plainStringLen);
  sendTemp(plain_auth_template, encStringLen, encString);
}

void xmpp_bind(char *resource) {
  sendTemp(bind_template, strlen(resource), resource);
}

void xmpp_session(char *server) {
  sendTemp(session_request_template, strlen(server), server);
}

void xmpp_presence() {
  sendTemp(presence_template, 0);
}

void xmpp_mess(char *recipient, char *message) {
  sendTemp(message_template, strlen(recipient) + strlen(message), recipient, message);
}

void process_input() {
  int bufLen = 8;
  char buffer[bufLen];
  int i = 0;
  memset(buffer, '\0', bufLen);
  boolean stateChanged = false;

  if(!client.connected()) {
    state = WAIT;
    return;
  }

  while(!stateChanged) {
    if(client.available()) {
      /* Push a character from the ethernet interface into the buffer */
      for(i = 0 ; i < bufLen; i++) {
        buffer[i] = buffer[i+1];
      }
      buffer[i] = client.read();
      
      
      /* Ignore what we've read if it's an empty string */
      if(!strlen(buffer)) {
        continue;
      } else {
         //Serial.println(buffer);
      }
      
      for(int i = 0; i < connTableSize; i++) {
        if(state == connTable[i].currentState && strstr(buffer,connTable[i].keyword)) {
          
          Serial.println(buffer);
          Serial.println(connTable[i].keyword);
          Serial.println((int)strstr(buffer, connTable[i].keyword)); 
          
          Serial.print(connTable[i].keyword);
          Serial.println(" seen, transitioning");
          
          state = connTable[i].nextState;
          client.flush();
          stateChanged = true;
          break;
        }
      }
    } else {
      delay(10);
    }
  }
}
