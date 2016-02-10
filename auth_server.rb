require './server'

class AuthServer < SocketServer
  def initialize(port)
    super(port)
    @user_names = { :dturner => 'secret',
                    :jturner => 'secret1'
                 }
  end

  def connection(client, read_line)

    if read_line == END_TRANS; client.close

    elsif read_line.start_with?AUTH_USER
      auth_user(client, read_line.strip.split(':')[1])

    else
      puts 'Command not known'
      client.close
    end

  end

  def auth_user(client, username)
    cipher = @user_names[username.to_sym]
    unless cipher.nil?
      key_gen = OpenSSL::Cipher::Cipher.new 'aes-128-cbc'
      session_key = [key_gen.random_key].pack('m0')
      token_string = SESSION_KEY + session_key
      ticket_string = TICKET + session_key
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

auth = AuthServer.new(5001)
auth.run
