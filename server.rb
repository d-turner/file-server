require 'thread'
require 'socket'
require './directory_service'

class SocketServer

  def initialize(port)
    @port = port
    @server = TCPServer.new @port
    @max_threads = 4
    @max = 1_000
    @que = Queue.new
    addr_infos = Socket.ip_address_list
    @ip = addr_infos[1].ip_address.to_s
    @main = Thread.current
  end

  def run
    x = Thread.new {
      while true do
        if @que.length > @max
          @server.accept
        else
          @que.push(@server.accept)
        end
      end
    }
    threads = @max_threads.times.map do
      Thread.new{connection}
    end
    threads.map &:join
    puts "Quiting"
  end

  def connection
    begin
      while true
        client = @que.pop(false)
          while true
            readLine = client.readline
            if readLine == "KILL_SERVICE\n"
              client.close
              puts "Killing"
              Thread.list.each do |thread|
                thread.exit unless thread == @main
              end
            elsif readLine.start_with?("HELO")
              reply = readLine.concat("IP:#{@ip}\nPort:#{@port}\nStudentID:33d4fcfd69df0c9bbbd0bd54ce854663db8238836b6faec70a00cf9e835a6bd1\n")
              client.write(reply)
              client.flush
            end
          end
        end
      rescue ThreadError
      end
    end
  end

port = 3000
if ARGV[0] == nil
  puts "No Port Specified using default 3000"
else
  port = ARGV[0]
end

puts "Using Port Number #{port}"
server = SocketServer.new(port)
server.run
