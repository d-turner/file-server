require './server'
require 'find'
class File_Server < Socket_Server

  def initialize(port)
    # call initializer of the server class
    #@port, @server, @max_threads, @max(q), @que, @ip, @main(thread)
    super(port)
    @files = {}
    p=@port%4000
    @dir = 'file_server'+p.to_s
  end

  # override connection
  def connection
    begin
      while true
           client = @que.pop(false)
        begin timeout(5) do
          client.each_line do |read_line|
            puts "#{read_line}"
            if read_line == 'KILL_SERVICE\n'   ; kill(client)
            elsif read_line.start_with?('HELO'); student(client, read_line)

            elsif read_line.start_with?(@open_file)
              file = find_file(read_line.strip)
              if file != @not_found
                file = open_file(file)
                if file == @not_found
                  puts 'File not found'
                else
                  file.each_line do |line|
                    client.puts(line)
                    puts "#{line}"
                  end
                  file.close
                end
              end
              client.puts(@end_transmission)
              client.flush
              client.close
              break

            elsif read_line <=> @get_listing
              files = Dir[@dir+'/**/*']
              files.each do |file|
                puts "#{file}"
                client.puts(file)
              end
              client.puts(@end_transmission)
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

  def open_file(path)
    if File.exist?(path)
      File.open(path, 'r')
    else @not_found end
  end

  def close_file(file)
    file.close
  end

  def find_file(find_file)
    files = Dir[@dir+'/**/*']
    files.each do |file|
      filename = file.split('/').last
      if filename <=> find_file
        return file
      end
    end
    return @not_found
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