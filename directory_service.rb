require './server'

class Directory_Service < Socket_Server
  def initialize(port)
    # call initializer of the server class
    #@port, @server, @max_threads, @max(q), @que, @ip, @main(thread)
    super(port)
    @file_servers = {'A'=>"4001\n", 'B'=> "4002\n", 'C'=>"4003\n", 'D'=>"4004\n"}
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
              else
                #elsif read_line.start_with?('open')
                  # expecting=> "open /dir1/dir2/file.txt"
                  #          => "open ComputerName:\dir1\dir2\file.txt"
                  #words = read_line.split(' ')
                  #directory = words[1].split('/')
                  #directory = directory.reject{|d| d.empty?}
                address = lookup(read_line.split(' ')[1].split('/').reject {|d| d.empty?}[0] )
                # Either connect to file server and make request or
                # (doing this one) return the address:port to make a new socket connection
                #socket = TCPServer.new 'localhost', address
                if address.nil?; client.sendmsg("\n")
                else client.sendmsg(address.to_s); end
                client.flush
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

  def lookup(dir)
    @file_servers[dir]
  end

  def add_server(name, port)
    @file_servers[name=>port]
  end

  def remove_server(server_name)
    @file_servers.delete(server_name)
  end

  def update_server(server_name, new_port )
    @file_servers[server_name] = new_port
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