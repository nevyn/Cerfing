Cerfing
====================
By Nevyn Joachim Bengtsson <nevyn.jpg@gmail.com>, 2011-12-28

I like constructing simple network protocols from plist/json-safe dictionaries, and
transmit them over a socket as json, with as little framing as possible. Easy
to prototype with, easy to debug. Give Cerfing an AsyncSocket, and it:

* Will wrap the socket to send JSON-serialized dictionaries over it
* Has a simple request-response system
* Supports Arbitrary NSData attachments
* Has an automatic 'delegate dispatching' feature, where the correct ObjC method
  is called based on the contents of the incoming method (very simplistic RPC)

It can also:

* Support other serializations than JSON;
* Be interleaved with another network protocol
* Wrap other socket libraries than AsyncSocket using a 'transport' abstraction.

Example
-------

An example of using Cerfing to send a request to update the server's MOTD:

<pre><code>[_conn requestDict:@{
	@"command": @"setMessage", // the command is 'setMessage'
	@"contents": msg // Send 'msg' as the new message to set.
} response:^(NSDictionary *response) {
	// The server has replied.
	if([response[@"success"] boolValue])
		NSLog(@"Successfully updated message!");
	else
		NSLog(@"Couldn't set message, because %@", [response objectForKey:@"reason"]);
}];</code></pre>

And on the receiving side:

<pre><code>-(void)request:(CerfingConnection*)conn setMessage:(NSDictionary*)dict responder:(CerfingResponseCallback)respond;
{
	NSString *newMessage = dict[@"contents"];
	if([newMessage rangeOfString:@"noob"].location != NSNotFound) {
		respond(@{
			@"success": @NO,
			@"reason": @"you should be kind!"
		});
	} else {
		_message = newMessage;
		respond(@{
			@"success": @YES
		});
	}
}</code></pre>

Note that in the response, the selector of the method to be called (request:setMessage:responder:)
has been deduced based on the incoming dictionary.

As you can see, the resulting protocol is very weakly typed. In theory,
this means you will be making typos and not understanding why the hell
your network seems broken; in reality, I've never had that problem.

Installation
------------

To use Cerfing with AsyncSocket, add these files to your project:

* CerfingConnection.{h|m}
* CerfingTransport.{h|m}
* CerfingSerialization.{h|m}
* CerfingAsyncSocketTransport.{h|m}
* AsyncSocket (the RunLoop variant; from this repo or from the original distribution)

What's up with the "Transport" abstraction?
-------------------------------------------

Cerfing used to be a single file. That was nice. However, I want to be able to use
the same protocl over multiple different transports. To start off, I'd love to
be able to use UDP in a game engine, but I don't want to break other usages of Cerfing
which wants to use it over TCP. The nicest (but not very nice) design I came up with
was to add a layer between the Cerfing and the socket — thus, the transport. Adding layers
to a design is often an antipattern (particularly when it's just a binding layer that
adds very little in terms of abstraction). If you have a better design, please let me know.

If you wish to use Cerfing as a single class with as little fuzz as possible, git tag "1.0.0"
is stable and easy to use, and "1.1.0" is the last 1.x release that retains this API.


What's up with the name 'Cerfing'?
----------------------------------

This project used to be called TCAHP, or TCAsyncHashProtocol, which is a terrible
and unpronouncable name. Of course a network library is asynchronous; 'hash' isn't used
to mean 'dictionary' in ObjC; and yeah ok, it's a protocol.

'Cerfing' is a homage to Vint Cerf, one of the original creators of the Internet as
we know it. By 'cerfing', you can quickly hack together network protocols without
bothering too much about the implementation details.

