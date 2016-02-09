require './server'
require 'find'
class File_Server < Socket_Server

  def initialize(port)
    super(port)
    @dir = 'file_server'+@port.to_s
    request_to_join
  end

  # override connection
  def connection
    begin
      while true
        client = @que.pop(false)
        begin timeout(25) do
          ticket = client.readline
          sk = get_session_key(ticket.strip)
          msg = client.readline
          read_line = decrypt(msg, sk)

          if read_line == END_TRANS;  client.close

          elsif read_line == KILL;  kill(client)

          elsif read_line.start_with?(HELO);  student(client, read_line, sk)

          elsif read_line.start_with?(OPEN_FILE);  find_file(client, read_line, sk)

          elsif read_line.start_with?(WRITE_FILE);  write_file(client, read_line, sk)

          elsif read_line == GET_LISTING;  send_file_list(client, sk)

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

  # Write file on client to file server
  def write_file(client, filename, cipher)
    filename = filename.strip.split(':')[1]
    client.puts(encrypt(ACCEPT, cipher))
    File.open(@dir+'/'+filename, 'w') do |file|
      client.each_line do |data|
        line = decrypt(data, cipher)
        if line == END_TRANS
          puts 'File saved'
        else
          file.write(line+"\n")
        end
      end
    end
    client.close
  end

  # Send file list to directory server
  def send_file_list(client, cipher)
    file_names = Dir[@dir+'/**/*']
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
    file_names = Dir[@dir+'/**/*']
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
    ticket = '--Ticket:%s' % @server_key
    cipher = @server_key
    ds.puts(encrypt(ticket, cipher))
    ds.puts(encrypt(JOIN_REQUEST, cipher))
    read_line = decrypt(ds.readline, cipher)
    if read_line == ACCEPT
      ds.puts(encrypt(IP_ADD % @ip, cipher))
      ds.puts(encrypt(PORT_ADD % @port, cipher))
      ds.puts(encrypt(END_TRANS, cipher))
      read_line = decrypt(ds.readline, cipher)
      if read_line == END_TRANS
        puts 'Successfully added'
      else
        puts 'Failed to add'
      end
    else
      puts 'Failed to add'
    end
    ds.flush
    ds.close
  end

end

if ARGV[0] == nil
  puts 'No Port Specified restart!'
else
  port = ARGV[0]
  puts "Using Port Number #{port}"
  server = File_Server.new(port)
  server.run
end