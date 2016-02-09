require './server'

class Directory_Service < Socket_Server

  def initialize(port)
    super(port)
    @file_servers = []
    @files = {}
  end

  def connection
    begin
      while true
        client = @que.pop(false)
        begin
          timeout(25) do
            ticket = client.readline
            if ticket.start_with?ACTION
              action(ticket)
              client.close
            else
              sk = get_session_key(ticket)
              msg = client.readline
              read_line = decrypt(msg.strip, sk)

              if read_line == END_TRANS;  client.close

              elsif read_line == KILL;  kill(client)

              elsif read_line.start_with?HELO;  student(client, read_line, sk)

              elsif read_line.start_with?FIND_SERVER;  lookup(client, read_line.strip.split(':')[1], sk)

              elsif read_line.start_with?WRITE_FILE;  allocate_server(client, read_line.strip.split(':')[1], sk)

              elsif read_line == JOIN_REQUEST;  manage_join(client, sk)

              else
                puts 'Command not known'
                client.close
              end
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

  def allocate_server(client, filename, cipher)
    address =  @files[filename]
    if address.nil?
      i = Random.new.rand(0..@file_servers.length-1)
      client.puts(encrypt(@file_servers[i], cipher))
      @files[filename] = @file_servers[i]
    else client.puts(encrypt(address, cipher)); end
    client.puts(encrypt(END_TRANS, cipher))
    client.flush
    client.close
  end

  def lookup(client, filename, cipher)
    address =  @files[filename]
    if address.nil?; client.puts(encrypt(NOT_FOUND, cipher))
    elsif !@file_servers.include? address;  client.puts(encrypt(NOT_FOUND, cipher))
    else client.puts(encrypt(address, cipher)); end
    client.flush
    client.close
  end

  def remove_server(address)
    @file_servers.delete(address)
  end

  def manage_join(client, cipher)
    client.puts(encrypt(ACCEPT, cipher))
    data = client.readline
    fs_ip = decrypt(data, cipher)
    data = client.readline
    fs_port = decrypt(data, cipher)
    data = client.readline
    end_trans= decrypt(data, cipher)
    address = nil
    if end_trans == END_TRANS && fs_ip.start_with?('--IP:') && fs_port.start_with?('--PORT:')
      fs_ip = fs_ip.strip.split(':')[1]
      fs_port = fs_port.strip.split(':')[1]
      address = fs_ip + ':' + fs_port
      unless @file_servers.include?address
        @file_servers.push(address)
      end
    else
      puts 'Failed to add server'
      client.puts(encrypt(DECLINE, cipher))
    end
    client.puts(encrypt(END_TRANS, cipher))
    client.flush
    client.close
    unless address.nil?
      query_server address
    end
  end

  def query_servers
    @file_servers.each do |fs|
      query_server fs
    end
  end

  def query_server(address)
    begin
      (ip,port) = address.split(':')
      fs = TCPSocket.new ip, port
      cipher = @server_key
      fs.puts(encrypt("--Ticket:%s\n" % @server_key, cipher))
      fs.puts(encrypt(GET_LISTING, cipher))
      fs.each_line do |rd|
        line = decrypt(rd, cipher)
        if line == END_TRANS
          puts 'Finished gathering files...'
        else
          filename = line.strip.split('/').last
          @files[filename] = address
        end
      end
    rescue Errno::ECONNREFUSED
      puts 'File server down removing...'
      @file_servers.delete(address)
    end
    fs.flush
    fs.close
  end

  def print_files
    @files.each do |file, server|
      puts "File: #{file}, Server Address: #{server}"
    end
  end

  def print_servers
    @file_servers.each do |fs|
      (ip, port) = fs.split(':')
      puts 'IP: ' + ip + ', Port: ' + port
    end
  end

  def action(read_line)
    action = read_line.strip.split(':')[1]
    case action
    when '1'; print_files
    when '2'; print_servers
    when '3'; query_servers
    else ; print 'No action'
    end
  end
end

port = 3001
if ARGV[0] == nil
  puts "No Port Specified using default #{port}"
else
  port = ARGV[0]
  puts "Using Port Number #{port}"
end

server = Directory_Service.new(port)
server.run
