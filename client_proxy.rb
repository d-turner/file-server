require 'socket'
require './cipher'
require './protocol'

class ClientProxy
  include MyCipher
  include Protocol
  def initialize
    @dir_server_address = 'localhost'
    @dir_server_port = 3001
    @auth_server_address = 'localhost'
    @auth_server_port = 5001
    @output_dir = './local/'
    @session_key = nil
    @ticket = nil
  end

  def directory_server(msg)
    ds = TCPSocket.new @dir_server_address, @dir_server_port
    ds.puts(@ticket)
    ds.puts(encrypt(msg, @session_key))
    reply = decrypt(ds.readline, @session_key)
    ds.close
    unless reply == NOT_FOUND
      puts 'Found Server'
    end
    reply
  end

  def open(filename)
    msg = FIND_SERVER + filename
    address = directory_server(msg)
    if address == NOT_FOUND
      puts 'File does not exist'
    else
      (ip, port) = address.strip.split(':')
      fs = TCPSocket.new ip, port
      fs.puts(@ticket)
      msg = encrypt(OPEN_FILE + filename, @session_key)
      fs.puts(msg)
      save_file(fs, filename)
    end
  end

  def save_file(fs, filename)
    File.open(@output_dir + filename, 'w') do |file|
      fs.each_line do |data|
        line = decrypt(data, @session_key)
        if line == END_TRANS
          puts 'File saved'
        else
          file.write(line + "\n")
        end
      end
    end
  end

  def write(filename)
    msg = WRITE_FILE + filename
    address = directory_server(msg)
    (ip, port) = address.strip.split(':')

    TCPSocket.open ip, port do |fs|
      fs.puts(@ticket)
      fs.puts(encrypt(msg, @session_key))
      reply = decrypt(fs.readline, @session_key)
      if reply == END_TRANS; puts 'Failed to add file...'

      elsif File.exist?(@output_dir + filename)
        puts "here"
        File.open(@output_dir + filename, 'r') do |file|
          file.each_line do |line|
            fs.puts(encrypt(line, @session_key))
          end
        end
      else
        puts 'File does not exist'
      end
      fs.puts(encrypt(END_TRANS, @session_key))
      fs.flush
      fs.close
    end
  end

  def auth_user(username, password)
    begin
      auth_server = TCPSocket.new @auth_server_address, @auth_server_port
      auth_server.puts(AUTH_USER + username)
      read_line = auth_server.readline
      auth_server.close

      unless read_line == END_TRANS
        token = decrypt(read_line, password)
        if token.start_with?(SESSION_KEY)
          puts 'User authenticated.'
          items = token.split(END_TRANS)
          @session_key = items[0].strip.split(':')[1]
          @ticket = items[1]
        else
          puts 'User not authenticated'
        end
      end
      if @ticket.nil?
        puts 'User not authenticated'
      end
    rescue OpenSSL::Cipher::CipherError => e
      puts 'Bad password or username not authenticated'
      p e
    end
  end
end
