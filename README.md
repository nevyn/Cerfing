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
