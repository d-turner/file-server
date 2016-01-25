require './server'

class Directory_Service < Socket_Server
  def initialize(port)
    # call initializer of the server class
    #@port, @server, @max_threads, @max(q), @que, @ip, @main(thread)
    super(port)
    @file_servers = {1=>'localhost:4001', 2=>'localhost:4002', 3=>'localhost:4003', 4=>'localhost:4004'}
    @files = {}
    query_servers
  end

  # override connection
  def connection
    begin
      while true
        client = @que.pop(false)
        begin
          timeout(5) do
            client.each_line do |read_line|
              if read_line == "KILL_SERVICE\n"
                kill(client)
              elsif read_line.start_with?('HELO')
                student(client, read_line)
              elsif read_line.start_with?(@find_server)
                #elsif read_line.start_with?('open')
                  # expecting=> "open file.txt"
                  #          => "open ComputerName:\dir1\dir2\file.txt"
                  #words = read_line.split(' ')
                  #directory = words[1].split('/')
                  #directory = directory.reject{|d| d.empty?}
                read_line = read_line.strip
                puts "#{read_line}"
		            #address = lookup(read_line.split(' ')[1].split('/').reject {|d| d.empty?}[0] )
                address = lookup(read_line.split(':')[1])
                if address.nil?; client.puts(@not_found)
                else client.puts(address); end
                client.flush
                client.close
                break
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

  def lookup(filename)
    @files[filename]
  end

  def add_server(name, address)
    @file_servers[name=>address]
  end

  def remove_server(server_name)
    @file_servers.delete(server_name)
  end

  def update_server(server_name, new_location )
    @file_servers[server_name] = new_location
  end

  def query_servers
    @file_servers.each do |key, location|
      local = location.split(':')
      address = local[0]
      port = local[1]
      fs = TCPSocket.new address, port
      fs.puts(@get_listing)
      fs.each_line do |read_line|
        read_line = read_line.strip
        if read_line == @end_transmission
          break
        end
        filename = read_line.split('/').last
        @files[filename] = location
      end
      fs.close
    end
    puts "#{@files}"
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
