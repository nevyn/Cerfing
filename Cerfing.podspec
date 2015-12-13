Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.name         = "Cerfing"
  s.version      = "2.0.2"
  s.summary      = "Lightweight json-based network protocol for rapid prototyping"

  s.description  = <<-DESC
                    I like constructing simple network protocols from plist/json-safe dictionaries, and transmit them over a socket as json, with as little framing as possible. Easy to prototype with, easy to debug. Give Cerfing an AsyncSocket, and it:

                    * Will wrap the socket to send JSON-serialized dictionaries over it
                    * Has a simple request-response system
                    * Supports Arbitrary NSData attachments
                    * Has an automatic 'delegate dispatching' feature, where the correct ObjC method is called based on the contents of the incoming method (very simplistic RPC)
                    
                    It can also:

                    * Support other serializations than JSON;
                    * Be interleaved with another network protocol
                    * Wrap other socket libraries than AsyncSocket using a 'transport' abstraction.
                   
                   DESC

  s.homepage     = "https://github.com/nevyn/Cerfing"
  s.license      = { :type => "Simplified BSD", :file => "LICENSE" }
  s.author             = { "Nevyn Bengtsson" => "nevyn.jpg@gmail.com" }
  s.social_media_url   = "http://twitter.com/nevyn"
  s.source       = { :git => "https://github.com/nevyn/Cerfing.git", :tag => s.version }

  s.ios.deployment_target = '7.0'
  s.osx.deployment_target = '10.9'

  # ――― Build settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.source_files  = "Cerfing", "Cerfing/**/*.{h,m}"
  s.header_mappings_dir = 'Cerfing'
  # s.public_header_files = "Classes/**/*.h"
  s.ios.frameworks = "Foundation"
  s.osx.frameworks = "Foundation", "CoreServices"
  # s.dependency "AsyncSoket"
end
