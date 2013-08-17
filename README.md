TCAsyncHashProtocol
====================
By Joachim Bengtsson <joachimb@gmail.com>, 2011-12-28

I like constructing simple network protocols from plist/json-safe dicts, and
transmit them over a socket as json, with as little framing as possible. Easy
to prototype with, easy to debug. Give TCAHP an AsyncSocket, and this is what
it'll do for you, plus support for request-response, and arbitrary NSData
attachments.

("HashProtocol" is a bit of a misnomer. 'Hash' in this context means
"dictionary", from the Ruby usage of the word "hash" meaning "hash table".)

It is an embarrassment and almost an insult that my example project is a
massive 200 lines. I hope to be able to reduce the verbosity and boilerplate
clutter of using TCAHP without making it heavy-weight.

Example
-------

An example of using TCAHP to send a request to update the server's MOTD:

<pre><code>[_proto requestHash:@{
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

<pre><code>-(void)request:(TCAsyncHashProtocol*)proto setMessage:(NSDictionary*)hash responder:(TCAsyncHashProtocolResponseCallback)respond;
{
	NSString *newMessage = hash[@"contents"];
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

(Note the latest piece of magic that I added, where the selector of the
delegate method is created based on the value of the key 'command' in the
message. I quite like it.)

As you can see, the resulting protocol is very weakly typed. In theory,
this means you will be making typos and not understanding why the hell
your network seems broken; in reality, I've never had that problem.

Installation
------------

To use TCAHP with AsyncSocket, add these files to your project:

* TCAsyncHashProtocol.{h|m}
* TCAHPTransport.{h|m}
* TCAHPAsyncSocketTransport.{h|m}

To use TCAHP with Eminet (a UDP network library for game networking), replace
TCAHPAsyncSocketTransport with TCAHPEmiConnectionTransport.

What's up with the "Transport" abstraction?
-------------------------------------------

TCAHP used to be a single file. That was nice. However, I want to be able to use
the same protocl over multiple different transports. To start off, I'd love to
be able to use UDP in a game engine, but I don't want to break other usages of TCAHP
which wants to use it over TCP. The nicest (but not very nice) design I came up with
was to add a layer between the TCAHP and the socket — thus, the transport. Adding layers
to a design is often an antipattern (particularly when it's just a binding layer that
adds very little in terms of abstraction). If you have a better design, please let me know.

If you wish to use TCAHP as a single class with as little fuzz as possible, git tag "1.0.0"
is stable and easy to use, and "1.1.0" is the last 1.x release that retains this API.


