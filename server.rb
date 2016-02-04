require 'thread'
require 'socket'
require 'timeout'
require 'openssl'
require 'base64'
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
AUTH_USER = "--AUTHENTICATE:"
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
    @server_key = "Tf\x17(\xF6\xFF\xF5V(\xEE\x0Fla\x0F\"\xF1"
    #@iv = "Ik\xCB\x96\xEC\"\xE5\x90\x11\xD7\xA1\xF2-H\xD0\xA4"
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

  def get_session_key(data, decipher)
    data = data.strip
    ticket = decrypt(data, decipher)
    if ticket.start_with?("--Ticket:")
      ticket.strip.split(':')[1]
    else
      puts 'Failed'
      nil
    end
  end

  def encrypt(msg, cipher)
    encrypted = cipher.update msg
    encrypted << cipher.final
    #cipher.final
    encoded = [encrypted].pack("m0")
    puts "Message:"
    p msg
    puts "Encrypted:"
    p encrypted
    puts "Encoded:"
    p encoded
    encoded
  end

  def decrypt(encoded, decipher)
    encoded = encoded.strip.force_encoding 'US-ASCII'
    encrypted = encoded.unpack("m0")[0]
    msg = decipher.update encrypted
    msg << decipher.final
    puts "Message:"
    p msg
    puts "Encrypted:"
    p encrypted
    puts "Encoded:"
    p encoded
    msg
  end

  def get_ciphers
    cipher = OpenSSL::Cipher::Cipher.new 'des-ecb'
    cipher.encrypt
    decipher = OpenSSL::Cipher::Cipher.new 'des-ecb'
    decipher.decrypt
    return cipher, decipher
  end

end
