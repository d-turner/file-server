require 'thread'
require 'socket'
require 'timeout'

class Socket_Server

  def initialize(port)
    @port = port
    @server = TCPServer.new @port
    @max_threads = 4
    @max = 1_000
    @que = Queue.new
    addr_infos = Socket.ip_address_list
    @ip = addr_infos[1].ip_address.to_s
    @threads = nil
  end

  def run
    Thread.new {
      while true do
        if @que.length > @max
          @server.reject
        else
          @que.push(@server.accept)
        end
      end
    }
    @threads = @max_threads.times.map do
      Thread.new{connection}
    end
    @threads.map &:join
    puts 'Quiting'
  end

  # outdated
  def connection
    begin
      while true
        client = @que.pop(false)
        while true
          readLine = client.readline
          if readLine == 'KILL_SERVICE\n'
            kill(client)
          elsif readLine.start_with?('HELO')
            student(client,readLine)
          end
        end
      end
      rescue ThreadError
    end
  end

  def kill(client)
    client.close
    puts 'Killing'
    @online = false
    @threads.each do |thread|
      thread.exit unless thread == Thread.current
    end
    Thread.exit
  end

  def student(client, read_line)
    reply = read_line.concat("IP:#{@ip}\nPort:#{@port}\nStudentID:33d4fcfd69df0c9bbbd0bd54ce854663db8238836b6faec70a00cf9e835a6bd1\n")
    client.write(reply)
    client.flush
  end

end
