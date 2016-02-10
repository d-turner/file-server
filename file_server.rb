require './server'

class FileServer < SocketServer
  def initialize(port)
    super(port)
    @dir = 'file_server' + @port.to_s
    request_to_join
  end

  # override connection
  def connection(client, request)
    cipher = get_session_key(request)
    data = client.readline
    read_line = decrypt(data.strip, cipher)

    if read_line == END_TRANS; client.close

    elsif read_line.start_with?OPEN_FILE; find_file(client, read_line, cipher)

    elsif read_line.start_with?WRITE_FILE; write_file(client, read_line.split(':')[1], cipher)

    elsif read_line.start_with?GET_LISTING; send_file_list(client, cipher)

    else
      puts 'Command not known'
      client.close
    end
  end

  # Write file on client to file server
  def write_file(client, filename, cipher)
    client.puts(encrypt(ACCEPT, cipher))
    File.open(@dir + '/' + filename, 'w') do |file|
      client.each_line do |data|
        line = decrypt(data, cipher)
        if line == END_TRANS; puts 'File saved'
        else file.write(line + "\n")
        end
      end
    end
    client.close
  end

  # Send file list to directory server
  def send_file_list(client, cipher)
    file_names = Dir[@dir + '/**/*']
    file_names.each do |file|
      client.puts(encrypt(file, cipher))
    end
    client.puts(encrypt(END_TRANS, cipher))
    client.flush
    client.close
  end

  # Open file for sending to client
  def open_file(client, path, cipher)
    if File.exist?(path)
      File.open(path, 'r') do |f|
        f.each_line do |line|
          client.puts(encrypt(line, cipher))
        end
      end
    end
  end

  def find_file(client, find, cipher)
    find = find.strip.split(':')[1]
    file_names = Dir[@dir + '/**/*']
    file_names.each do |path|
      filename = path.split('/').last
      if filename == find
        open_file(client, path, cipher)
      end
    end
    client.puts(encrypt(END_TRANS, cipher))
    client.flush
    client.close
  end

  def request_to_join
    ds = TCPSocket.new DIR_ADD, DIR_PORT
    ticket = TICKET + @server_key
    cipher = @server_key
    msg = encrypt(ticket, cipher)
    ds.puts(msg)
    ds.puts(encrypt(JOIN_REQUEST, cipher))
    read_line = decrypt(ds.readline, cipher)
    if read_line.start_with?ACCEPT
      ds.puts(encrypt(IP_ADD + @ip, cipher))
      ds.puts(encrypt(PORT_ADD + @port, cipher))
      ds.puts(encrypt(END_TRANS, cipher))
      read_line = decrypt(ds.readline, cipher)
      if read_line == END_TRANS; puts 'Successfully added'
      else puts 'Failed to add'
      end
    else
      puts 'Failed to add'
    end
    ds.flush
    ds.close
  end
end

if ARGV[0].nil?
  puts 'No Port Specified restart!'
else
  port = ARGV[0]
  puts "Using Port Number #{port}"
  server = FileServer.new(port)
  server.run
end
