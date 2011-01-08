#include <Base64.h>
#include <TinyXML.h>
#include <SPI.h>
#include <Ethernet.h>
#include <avr/pgmspace.h>

const char openStreamTemplate[] = "<stream:stream "
                                            "xmlns='jabber:client' "
                                            "xmlns:stream='http://etherx.jabber.org/streams' "
                                            "to='%s' "
                                            "version='1.0'>";

const char plainAuthTemplate[] = "<auth "
                                 "xmlns='urn:ietf:params:xml:ns:xmpp-sasl' "
                                 "mechanism='PLAIN'>"
                                 "%s"
                                 "</auth>";
                              
const char bindTemplate[] = "<iq " 
                            "type='set' " 
                            "id='bind_1'>"
                            "<bind "
                            "xmlns='urn:ietf:params:xml:ns:xmpp-bind'>"
                            "<resource>%s</resource>"
                            "</bind>"
                            "</iq>";

/*
const char bindTemplate[] = "<iq type='set' id='bind_1'>"
  "<bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'/>"
"</iq>";
*/

const char sessionRequestTemplate[] = "<iq "
                                      "to='%s' "
                                      "type='set' "
                                      "id='sess_1'>"
                                      "<session xmlns='urn:ietf:params:xml:ns:xmpp-session'/> "
                                      "</iq>";
/*                                     
const char presenceTemplate[] = "<presence "
                                "type='%s'>"
                                "<status>%s</status>"
                                "</presence>";
*/
const char presence[] = "<presence><show/></presence>";

enum XMPPState {
  INIT,
  AUTH,
  AUTH_STREAM,
  BIND,
  SESS,
  READY,
  WAIT
};

/*******/
/* XMPP Instances */
/*******/
XMPPState state = INIT;

char username[] = "username";
char server[] = "jabber.org";
char resource[] = "arduino";
char password[] = "password";



/*******/
/* Function prototypes */
/*******/
void xmpp_openstream(char *server);
void xmpp_authenticate(char *username, char *password);
void xmpp_bind(char *resource);
void xmpp_makesession(char *server);
void xmpp_sendpresence();

void process_input();


/*******/
/* XML parsing */
/*******/
TinyXML xmlParser;
void parser_callback(uint8_t, char*, uint16_t, char*, uint16_t);
uint16_t xmlParserBufferLength = DEFAULT_BUFFER_SIZE;
uint8_t xmlParserBuffer[DEFAULT_BUFFER_SIZE];

/*******/
/* Ethernet */
/*******/
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192,168,2,23 };
byte serverIp[] = { 130,102,128,123 };

Client client(serverIp, 5222);

void setup() {
  xmlParser.init((uint8_t*) &xmlParserBuffer, 
                  xmlParserBufferLength, &parser_callback);
  Ethernet.begin(mac, ip);
  Serial.begin(9600);
  delay(1000);
  
  Serial.println("Conn...");
  while(!client.connect()) {
    Serial.println("Ret...");
    delay(1000);
  }
  
  
}

void loop() {
 //Serial.print("State = ");
 //Serial.println(state);
 switch(state) {
  case INIT:
    xmpp_openstream(server);
    state = WAIT;
    break;
  case AUTH:
    xmpp_authenticate(username, password);
    state = WAIT;
    break;
  case AUTH_STREAM:
    xmpp_openstream(server);
    state = WAIT;
    break;
  case BIND:
    xmpp_bind(resource);
    state = WAIT;
    break;
  case SESS:
    xmpp_makesession(server);
    state = WAIT;    
    break;
  case READY:
    xmpp_sendpresence();
    state = WAIT;
    break;
  default:
    break;
 }

 process_input(); 
}

void xmpp_openstream(char *server) {
  char buffer[strlen(openStreamTemplate) + strlen(server)];
  sprintf(buffer, openStreamTemplate, server);
  Serial.println(buffer);
  client.write(buffer);
}

void xmpp_authenticate(char *username, char *password) {
  int plainStringLen = strlen(username) + strlen(password) + 2;
  int encStringLen = base64_enc_len(plainStringLen);
  char plainString[plainStringLen];
  char encString[encStringLen];
  char sendBuffer[strlen(plainAuthTemplate) + encStringLen];
  
  /* Set up our plain auth string. It's in the form:
   * "\0username\0password"
   * where \0 is the null character
   */
  memset(plainString, '\0', plainStringLen);
  memcpy(plainString + 1, username, strlen(username));
  memcpy(plainString + 2 + strlen(username), password, strlen(password));
  
  /* Encode to base64 */
  base64_encode(encString, plainString, plainStringLen);
  
  /* Insert the encoded string into the authentication template */
  sprintf(sendBuffer, plainAuthTemplate, encString);
  
  /* Send the authentication */
  Serial.println(sendBuffer);
  client.write(sendBuffer);
}

void xmpp_bind(char *resource) {
  char buffer[strlen(bindTemplate) + strlen(resource)];
  sprintf(buffer, bindTemplate, resource);
  Serial.println(buffer);
  client.write(buffer);
  
  /*
  Serial.println(bindTemplate);
  client.write(bindTemplate);
  */
}

void xmpp_makesession(char *server) {
  char buffer[strlen(sessionRequestTemplate) + strlen(server)];
  sprintf(buffer, sessionRequestTemplate, server);
  Serial.println(buffer);
  client.write(buffer);
}

void xmpp_sendpresence() {
  Serial.println(presence);
  client.write(presence);
}  

void process_input() {
  while(client.available()) {
    char c = client.read();
    xmlParser.processChar(c);
  }
  
  delay(1000);
}

void parser_callback(uint8_t statusflags, char *tagName, uint16_t tagNameLen, char *data, uint16_t dataLen) {
    if (statusflags & STATUS_START_TAG)
  {
    if ( tagNameLen )
    {
      /*
      Serial.print("Start tag ");
      Serial.println(tagName);
      */
    }
  }
  else if  (statusflags & STATUS_END_TAG)
  {
    if(!strcmp(tagName, "/stream:stream/success")) {
      state = AUTH_STREAM;
    }
    
    if(!strcmp(tagName, "/stream:stream/stream:stream/stream:features/bind")) {
      state = BIND;
    }
    
    if(!strcmp(tagName, "/stream:stream/stream:stream/iq/bind/jid")) {
      state = SESS;
    }
    
    if(!strcmp(tagName, "/stream:stream/stream:stream/iq/session")) {
      state = READY;
    }
    
    Serial.print("End tag ");
    Serial.println(tagName);
  }
  else if  (statusflags & STATUS_TAG_TEXT)
  { 
    if(!strcmp(tagName, "/stream:stream/stream:features/mechanisms/mechanism") &&
       !strcmp(data, "PLAIN")) {
         state = AUTH;
    }
    
    Serial.print("Body:");
    Serial.print(tagName);
    Serial.print(" text:");
    Serial.println(data);
  }
  else if  (statusflags & STATUS_ATTR_TEXT)
  {
    /*
    Serial.print("Attribute:");
     Serial.print(tagName);
     Serial.print(" text:");
     Serial.println(data);
     */
  }
  else if  (statusflags & STATUS_ERROR)
  {
    
    /*
    Serial.print("XML Parsing error  Tag:");
     Serial.print(tagName);
     Serial.print(" text:");
     Serial.println(data);
     */
  }
}
