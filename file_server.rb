require './server'
require 'find'
class File_Server < Socket_Server

  def initialize(port)
    # call initializer of the server class
    #@port, @server, @max_threads, @max(q), @que, @ip, @main(thread)
    super(port)
    @dir = 'file_server'+@port.to_s
    request_to_join
  end

  # override connection
  def connection
    begin
      while true
        client = @que.pop(false)
        begin timeout(5) do
          read_line = client.readline

          if read_line == END_TRANS;  client.close

          elsif read_line == KILL;  kill(client)

          elsif read_line.start_with?(HELO);  student(client, read_line)

          elsif read_line.start_with?(OPEN_FILE);  find_file(client, read_line)

          elsif read_line == GET_LISTING;  send_file_list(client)

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

  def write_file(directory_name, file_name, data)
    if File.directory?(directory_name)
      if File.exists?(directory_name+'/'+file_name)
        File.open(directory_name+'/'+file_name, 'w').write(data)
      else nil end
    end
  end

  def send_file_list(client)
    file_names = Dir[@dir+'/**/*']
    file_names.each do |file|
      client.puts(file)
    end
    client.puts(END_TRANS)
    client.flush
    client.close
  end

  def open_file(client, path)
    if File.exist?(path)
      File.open(path, 'r') do |f|
        f.each_line do |line|
          client.puts(line)
        end
      end
    end
  end

  def find_file(client, find)
    find = find.strip.split(':')[1]
    file_names = Dir[@dir+'/**/*']
    file_names.each do |path|
      filename = path.split('/').last
      if filename == find
        open_file(client, path)
      end
    end
    client.puts(END_TRANS)
    client.flush
    client.close
  end

  def request_to_join
    ds = TCPSocket.new DIR_ADD, DIR_PORT
    ds.puts(JOIN_REQUEST)
    read_line = ds.readline
    if read_line == ACCEPT
      ds.puts(IP_ADD % @ip)
      ds.puts(PORT_ADD % @port)
      ds.puts(END_TRANS)
      read_line = ds.readline
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