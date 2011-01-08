Introduction
------------

Arduino-xmpp is a simple XMPP client library for
the Arduino platform.

At this point, it isn't even a library so much as a
messy bit of code that tends to buffer overrun itself
if you lengthen strings, but this is set to change!

To use it at this point you will need to do the following:
    1. Find out the IP address of the jabber server you want to connect to
    2. Insert that into the 'serverIp' field
    3. Fill in your JID details in the 'username', 'server' and 'resource' fields
    4. Fill in your password in the 'password'
    5. Compile and load
    6. Hello Arduino!

