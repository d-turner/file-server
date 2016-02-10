require 'thread'
require 'socket'
require 'timeout'
require './protocol'
require './cipher'

class SocketServer
  include MyCipher
  include Protocol
  def initialize(port)
    @port = port
    @server = TCPServer.new @port
    @max_threads = 4
    @max = 1_000
    @que = Queue.new
    addr_infos = Socket.ip_address_list
    @ip = addr_infos[1].ip_address.to_s
    @threads = nil
    @server_key = 'VGYXKPb/9VYo7g9sYQ8i8Q=='
  end

  def run
    Thread.new {
      while true
        if @que.length > @max
          @server.reject
        else
          @que.push(@server.accept)
        end
      end
    }
    @threads = @max_threads.times.map do
      Thread.new{ handle_client }
    end
    @threads.map { |t| t.join }
    puts 'Quiting'
  end

  def handle_client
    begin
      while true
        client = @que.pop(false)
        begin timeout(50) do
          read_line = (client.readline).strip
          if read_line.start_with?KILL; kill(client)

          elsif read_line.start_with?HELO; student(client, read_line)

          else connection(client, read_line)
          end
        end
        rescue Timeout::Error
          puts 'Timed Out!'
          client.close
        end
      end
    rescue ThreadError
      puts 'Thread Error'
    end
  end

  def connection(client, read_line)
    # do some server stuff
  end

  def kill(client)
    client.close
    puts 'Killing'
    @threads.each do |thread|
      thread.exit unless thread.equal?Thread.current
    end
    Thread.exit
  end

  def student(client, read_line)
    reply = read_line.concat("IP:#{@ip}\nPort:#{@port}\n
                             StudentID:33d4fcfd69df0c9bbbd0bd54ce8546
                              63db8238836b6faec70a00cf9e835a6bd1\n")
    client.puts(reply)
    client.flush
    client.close
  end
end
