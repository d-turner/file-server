require 'thread'
require 'socket'
require 'timeout'
require 'aescrypt'
require 'base64'
require 'rubygems'
END_TRANS = '--END--'
NOT_FOUND = '404'
JOIN_REQUEST = '--JOIN_REQUEST--'
ACCEPT = '--ACCEPT--'
DECLINE = '--DECLINE--'
GET_LISTING = '--FILE_LIST--'
FIND_SERVER = '--WHERE_IS:'
OPEN_FILE = '--OPEN:'
WRITE_FILE = '--WRITE:'
KILL = 'KILL_SERVICE'
HELO = 'HELO'
IP_ADD = '--IP:%s'
PORT_ADD = '--PORT:%s'
ACTION = '--ACTION:'
AUTH_USER = '--AUTHENTICATE:'
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
    @server_key = "VGYXKPb/9VYo7g9sYQ8i8Q=="
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
    # do some server stuff
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

  def student(client, read_line, cipher)
    reply = read_line.concat("IP:#{@ip}\nPort:#{@port}\nStudentID:33d4fcfd69df0c9bbbd0bd54ce854663db8238836b6faec70a00cf9e835a6bd1\n")
    data = encrypt(reply, cipher)
    client.puts(data)
    client.flush
    client.close
  end

  def get_session_key(data)
    data = data.strip
    ticket = decrypt(data, @server_key)
    if ticket.start_with?("--Ticket:")
      ticket.strip.split(':')[1]
    else
      puts 'Failed'
      nil
    end
  end

  def encrypt(msg, key)
    encrypted = AESCrypt.encrypt(msg, key)
    encoded = [encrypted].pack("m0")
    puts "Message:"
    p msg
    puts "Encrypted:"
    p encrypted
    puts "Encoded:"
    p encoded
    encoded
  end

  def decrypt(encoded, key)
    encrypted = encoded.strip.unpack("m0")[0]
    msg = AESCrypt.decrypt(encrypted, key)
    puts "Message:"
    p msg
    puts "Encrypted:"
    p encrypted
    puts "Encoded:"
    p encoded
    msg
  end

end
