require './server'

class File_Server < Socket_Server

  def initialize(port)
    # call initializer of the server class
    #@port, @server, @max_threads, @max(q), @que, @ip, @main(thread)
    super(port)
    @files = {}
  end

  # override connection
  def connection
    begin
      while true
           client = @que.pop(false)
        begin timeout(5) do
          client.each_line do |read_line|
            if read_line == 'KILL_SERVICE\n'   ; kill(client)
            elsif read_line.start_with?('HELO'); student(client, read_line)
            elsif read_line.start_with?('open')
              file = open_file(read_line)
              if file.nil?
                puts 'File not found'
                client.sendmsg("\n")
              else
                file.each_line do |line|
                  client.sendmsg(line)
                end
                file.close
              end
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

  def write_file(directory_name, file_name, data)
    if File.directory?(directory_name)
      if File.exists?(directory_name+'/'+file_name)
        File.open(directory_name+'/'+file_name, 'w').write(data)
      else nil end
    end
  end

  def open_file(read_line)
    # format => "open ComputerName:\dir1\dir2\file.txt"
    #        => "open /home/username/dir1/dir2/file.txt"
    # .split('\').reject{|d| d.empty?} => [ "ComputerName:", "dir1", "dir2", "file.txt" ]
    path = read_line.split(' ')[1]
    if File.exist?(path)
      File.open(path, 'r')
    else nil end
  end

  def close_file(file)
    file.close
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