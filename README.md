# TellaPeer

Ruby peer client for the CSETella P2P network.
CSE 552 Spring 2013
Keith Stone

## To run

Requires Ruby 2.0

```
bundle install
bundle exec thor client:start 
```

Default serves on port 9000 and serves a GUID as the text.

Available options:
* --reply
    * Text to serve
* --log_level
    * DEBUG, INFO, WARN, FATAL
* --ttl
    * Message time to live
* --public_ip
    * Public IP to communicate over the protocol (Stops auto-find of this value)
* --port
    * Port to run our server on
* --local
    * Run the server on localhost

## Code structure

* client.thor
    * Handles reading of command line options and starting the various threads that need to run and starts the server.
* lib/tella_peer/message.rb
    * Subclass for all messages. Implements the marshalling and unmarshalling of the bits after they cross the wire. There is a implementation of each type of message that implements logic needed by those individual methods to pack and unpack themselves.
* lib/tella_peer/connection.rb
    * Models a high level wrapper around the actual socket connection. Contains the logic for what to do when receiving various messages as well as how to watch the socket in a threaded way.
* lib/tella_peer/connections.rb
    * Models the group of connections. Is responsible for keeping track of all currently open connections and to reach out to new potential connections. This class also hold most of the statistics my status page shows including overal message counts, potential connections, and active connections.

I was able to build a pretty solid test base around my own message creation, marshalling and unmarshalling. These were not to hard as they were essentually unit tests and could be stubbed out to test exactly the pieces I was unsure of. What was impossible to test and I think still broken is my interations with peers. Predicting how peers were going to drop or act was not something I could model out 100%. My answer to this was just logging and monitoring. When running log level DEBUG the output is very verbose so as to be able to see and fix issues that my tests missed.

## Web server

I have screen caps of my status page in the sinatra_server folder. My NAT is open on 76.104.193.163:4567 but I am running on my laptop so I may not be available during the day as it comes to work with me.
