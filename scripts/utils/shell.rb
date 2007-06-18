require 'rubygems'
require 'socket'
require 'session' # Ara T. Howard's session library

client = TCPSocket.new('localhost', 3003)

bash = Session::Bash.new

bash.outproc = lambda { |out| client.print out }
bash.errproc = lambda { |err| client.print err }

while input = client.gets
  if input =~ /\s*exit\s*$/ then
    client.close
    exit
  end
  bash.execute(input)
end
