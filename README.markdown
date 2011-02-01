Introduction
------------

Arduino-XMPP is a simple write only XMPP client for the Arduino platform.

Operation
---------

Basic operation is as follows:
    1. Create an XMPPClient instance specifying your XMPP server IP address and port.
    2. Call connect on the XMPPClient interface, specifying your username, the server's host name, the resource name you wish to bind to and the your password.
    3. If connect returns 1, you're good to go on.
    4. Register your presence as available by calling sendPresence.
    5. Send messages using sendMessage.
    6. Close the connection and XMPP stream using close.

Limitations
-----------

This client library is somewhat restricted in what in can do. The major restrictions are as follows:
    1. SASL-PLAIN authentication only
    2. No SSL/TLS encryption on the stream
    3. No ability to receive and interpret incoming messages

While the first one is on the two do list in some capacity, the first two are likely to never be rectified, due primarily to the SRAM restrictions of the Arduino
