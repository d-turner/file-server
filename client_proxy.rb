require 'socket'
require 'openssl'
class Client_Proxy
  # for the proxy implement the % part
  # eg OPEN = "--OPEN:%s\n"
  # puts OPEN % filename
END_TRANS = "--END--\n"
NOT_FOUND = "404\n"
FIND_SERVER = "--WHERE_IS:%s\n"
OPEN_FILE = "--OPEN:%s\n"
WRITE_FILE = "--WRITE:%s\n"
KILL = "KILL_SERVICE\n"
ACTION = "--ACTION:%d\n"
AUTH_USER = "--AUTHENTICATE:%s\n"

  def initialize
    @dir_server_address = 'localhost'
    @dir_server_port = 3001
    @auth_server_address = 'localhost'
    @auth_server_port = 5001
    @output_dir = './local/'
    @get_listing = '--file_list--'
    @find_server = 'where_is:'
    @open_file = 'open:'
    @end_transmission = '--END--'
    @not_found = '404'
    @salt = "\xFB\xD9\x0E\xCC\xD69\xB3\xC74-\xA2\xF3\xBA\x83\x8D\b"
    @iter = 20000
    @digest = OpenSSL::Digest::SHA256.new
    @len = @digest.digest_length
    @session_cipher = OpenSSL::Cipher.new 'AES-128-CBC'
    @ticket = nil
  end

  def directory_server(filename, msg)
    ds = TCPSocket.new @dir_server_address, @dir_server_port
    ds.puts(@ticket)
    ds.puts(encrypt(msg % filename, @session_cipher))
    reply = ds.readline
    endtrans = ds.readline
    if decrypt(endtrans, @session_cipher) == END_TRANS
      puts 'Found Server'
    end
    ds.close
    decrypt(reply, @session_cipher)
  end

  def open(filename)
    reply = directory_server(filename, FIND_SERVER)
    if reply == NOT_FOUND
      puts 'File does not exist'
    else
      address = reply.strip.split(':')
      ip = address[0]
      port = address[1]
      fs = TCPSocket.new ip, port
      fs.puts(@ticket)
      fs.puts(encrypt(OPEN_FILE % filename, @session_cipher))
      save_file(fs, filename)
    end
  end

  def save_file(fs, filename)
    File.open(@output_dir+filename, 'w') do |file|
      #while chunk = as this may not work
      #fs.read(size) do |chunk|
      #  file.write(chunk)
      #end
      fs.each_line do |data|
        line = decrypt(data, @session_cipher)
        puts line
        if line == END_TRANS
          puts 'File saved'
        else
          file.write(line)
        end
      end
    end
  end

  def write(filename)
    address = directory_server(filename, WRITE_FILE)
    (ip, port) = address.strip.split(':')
    TCPSocket.open ip, port do |fs|
      fs.puts(@ticket)
      fs.puts(encrypt(WRITE_FILE % filename, @session_cipher))
      data = fs.readline
      reply = decrypt(data, @session_cipher)
      if reply.equal?(END_TRANS)
        puts 'Failed to add file...'
      else
        File.open(@output_dir+filename, 'r') do |file|
          file.each_line do |line|
            data = encrypt(line, @session_cipher)
            fs.puts(data)
          end
        end
        fs.puts(encrypt(END_TRANS, @session_cipher))
        fs.flush
        fs.close
      end
    end
  end

  def auth_user(username, password)
    begin
      auth_s = TCPSocket.new @auth_server_address, @auth_server_port
      auth_s.puts(AUTH_USER % username)
      token = auth_s.read
      auth_s.close
      cipher = OpenSSL::Cipher.new 'AES-128-CBC'
      cipher.decrypt
      hash = OpenSSL::PKCS5.pbkdf2_hmac(password , @salt, @iter, @len, @digest)
      cipher.key = hash
      #token = cipher.update(token) + cipher.final
      token = decrypt(token, cipher)
      if token.start_with?("--Session_key:")
        puts "User authenticated.\n"
        items = token.split(END_TRANS)
        @ticket = items[1]
        @session_cipher.key = items[0].strip.split(':')[1]
      else
        puts 'User not authenticated'
      end
    rescue OpenSSL::Cipher::CipherError => e
      puts 'Bad password or username not authenticated'
        p e
    rescue ArgumentError
      puts 'Username does not exist'
    end
  end

  def encrypt(msg, cipher)
    puts "Message:"
    p msg
    #encrypted = cipher.update msg
    #encrypted << cipher.final
    #puts "Encrypted:"
    #p encrypted
    data = [msg].pack('m0')
    puts "Encoded:"
    p data
    data
  end

  def decrypt(encoded, decipher)
    encoded = encoded.strip
    msg = encoded.unpack('m0')[0]
    puts "Message:"
    p msg
    puts "Encoded:"
    p encoded
    msg
    #puts "Encrypted:"
    #p encrypted
    #decrypted = decipher.update encrypted
    #decrypted << decipher.final
    #puts "Decrypted:"
    #p decrypted
    #decrypted
  end

  def get_ciphers
    cipher = OpenSSL::Cipher.new 'AES-128-ECB'
    cipher.encrypt
    decipher = OpenSSL::Cipher.new 'AES-128-ECB'
    decipher.decrypt
    return cipher, decipher
  end

end