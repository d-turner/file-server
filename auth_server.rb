require 'socket'
require './server'

class Auth_Server < Socket_Server

  def initialize(port)
    super(port)
    @salt = "\xFB\xD9\x0E\xCC\xD69\xB3\xC74-\xA2\xF3\xBA\x83\x8D\b"
    @iter = 20000
    @digest = OpenSSL::Digest::SHA256.new
    @len = @digest.digest_length
    # Username => password
    # Should store passwords as Hash
    @user_names = {:dturner => "secret",
                   :jturner => "secret1"
                 }
  end

  def connection
    begin
      while true
        client = @que.pop(false)
        begin timeout(5) do
          read_line = client.readline

          if read_line == END_TRANS;  client.close

          elsif read_line.start_with?AUTH_USER  auth_user(client, read_line)

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
    cipher = @user_names[username.to_sym]
    unless cipher.nil?
      key_gen = OpenSSL::Cipher::Cipher.new 'aes-128-cbc'
      session_key = [key_gen.random_key].pack('m0')

      token_string = '--Session_key:%s' % session_key
      ticket_string = '--Ticket:%s' % session_key
      ticket = encrypt(ticket_string, @server_key)

      token = token_string + END_TRANS + ticket + END_TRANS
      token = encrypt(token, cipher)
      client.puts(token)
    end
    client.puts(END_TRANS)
    client.flush
    client.close
  end

end

auth = Auth_Server.new(5001)
auth.run