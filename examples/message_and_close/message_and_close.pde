#include <Base64.h>
#include <XMPPClient.h>
#include <SPI.h>
#include <Ethernet.h>
#include <PubSubClient.h>
#include <avr/pgmspace.h>

// Update these with values suitable for your network.
byte mac[]    = {  0xDE, 0xED, 0xBA, 0xFE, 0xFE, 0xED };
byte server[] = { 192,168,2,1 };
byte ip[]     = { 192,168,2,10 };

XMPPClient client(server, 5222);

void setup()
{
  Serial.begin(9600);
  Ethernet.begin(mac, ip);
  /* Connect to the XMPP server */
  if (client.connect("adam", "test.awg", "arduinus", "avrud0")) {
    /* Connected, let everyone know that we're online */
    client.sendPresence();
  }
}

int count = 0;
void loop() {
  /* Say hello! */
  client.sendMessage("admin@test.awg", "hello");
  delay(5000);
  
  /* A couple of times... */
  if(count++ > 0) {
    /* Say goodbye! */
    client.sendMessage("admin@test.awg", "bye!");
    /* Close the connection */
    client.close();
    /* Spin forever */
    while(1) {;}
  }
}




