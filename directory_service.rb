require './server'

class Directory_Service < Socket_Server

  def initialize(port)
    #@port, @server, @max_threads, @max(q), @que, @ip, @main(thread)
    super(port)
    @file_servers = []
    @files = {}
  end

  def connection
    begin
      while true
        client = @que.pop(false)
        begin
          timeout(500) do
            read_line = client.readline

            if read_line == END_TRANS;  client.close

            elsif read_line == KILL;  kill(client)

            elsif read_line.start_with?HELO;  student(client, read_line)

            elsif read_line.start_with?FIND_SERVER;  lookup(client, read_line.strip.split(':')[1])

            elsif read_line == JOIN_REQUEST;  manage_join(client)

            elsif read_line.start_with?ACTION
              action = read_line.strip.split(':')[1]
              case action
                when '1'; print_files
                when '2'; print_servers
                when '3'; query_servers
                else ; print 'No action'
              end
              client.close

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

  def lookup(client, filename)
    address =  @files[filename]
    if address.nil?; client.puts(NOT_FOUND)
    elsif !@file_servers.include? address;  client.puts(NOT_FOUND)
    else client.puts(address); end
    client.puts(END_TRANS)
    client.flush
    client.close
  end

  def remove_server(address)
    @file_servers.delete(address)
  end

  def manage_join(client)
    client.puts(ACCEPT)
    fs_ip = client.readline
    fs_port = client.readline
    end_trans = client.readline
    if end_trans == END_TRANS && fs_ip.start_with?('--IP:') && fs_port.start_with?('--PORT:')
      fs_ip = fs_ip.strip.split(':')[1]
      fs_port = fs_port.strip.split(':')[1]
      address = fs_ip + ':' + fs_port
      unless @file_servers.include?address
        @file_servers.push(address)
      end
    else
      puts 'Failed to add server'
      client.puts(DECLINE)
    end
    client.puts(END_TRANS)
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
      fs.puts(GET_LISTING)
      fs.each_line do |read_line|
        if read_line == END_TRANS
          puts 'Finished gathering files...'
        else
          filename = read_line.strip.split('/').last
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
