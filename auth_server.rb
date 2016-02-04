require 'socket'
require './server'

class Auth_Server < Socket_Server

  def initialize(port)
    super(port)
    @salt = "\xFB\xD9\x0E\xCC\xD69\xB3\xC74-\xA2\xF3\xBA\x83\x8D\b"
    @iter = 20000
    @digest = OpenSSL::Digest::SHA256.new
    @len = @digest.digest_length
    @user_names = {:dturner => "?\x9Bu\xDC\t\xD6\x93\x02^7\xC5;\f\xFATN\bA\x81\xF0x\x880\x8B\xE4\x9E\x7Fw\xA9W\xA7\x85", #secret
                  :jturner => "7jN^\xCAEr\xE58\xA31eN\xCB\x82D\xCBD\xF8\x8DE@\xFB\xF3[\x83\xDE\x918^\x16q" #secret1
                 }
  end

  def connection
    begin
      while true
        client = @que.pop(false)
        begin timeout(5) do
          read_line = client.readline

          if read_line == END_TRANS;  client.close

          elsif read_line.start_with?(AUTH_USER);  auth_user(client, read_line)

          else
            puts 'Command not known'
            client.close
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

  def auth_user(client, readline)
    username = readline.strip.split(':')[1]
    hash = @user_names[username.to_sym]
    unless hash.nil?
      (cipher, cipher2) = get_ciphers
      session_key = cipher.random_key
      cipher.key = @server_key
      ticket_string = "--Ticket:%s\n" % session_key
      #ticket = cipher.update(ticket_string) + cipher.final
      ticket = encrypt(ticket_string, cipher)
      token_string = "--Session_key:%s\n" % session_key
      token = token_string + END_TRANS + ticket + END_TRANS
      cipher2.encrypt
      cipher2.key = hash
      #token = cipher2.update(token) + cipher2.final
      token = encrypt(token, cipher2)
      client.write(token)
    end
    client.flush
    client.close
  end

end

auth = Auth_Server.new(5001)
auth.run