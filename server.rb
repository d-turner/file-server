require 'thread'
require 'socket'
require 'timeout'
END_TRANS = "--END--\n"
NOT_FOUND = "404\n"
JOIN_REQUEST = "--JOIN_REQUEST--\n"
ACCEPT = "--ACCEPT--\n"
DECLINE = "--DECLINE--\n"
GET_LISTING = "--FILE_LIST--\n"
FIND_SERVER = "--WHERE_IS:"
OPEN_FILE = "--OPEN:"
WRITE_FILE = "--WRITE:"
KILL = "KILL_SERVICE\n"
HELO = "HELO"
IP_ADD = "--IP:%s\n"
PORT_ADD = "--PORT:%s\n"
ACTION = "--ACTION:"
DIR_ADD = 'localhost'
DIR_PORT = 3001
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
          read_line = client.readline

          if read_line == KILL;  kill(client)

          elsif read_line.start_with?(HELO);  student(client,read_line)

          end
        end
        end
    rescue ThreadError
      puts 'Thread Error'
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
    client.close
  end

end
