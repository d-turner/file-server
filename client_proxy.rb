require 'socket'
class Client_Proxy
  # for the proxy implement the % part
  # eg OPEN = "--OPEN:%s\n"
  # puts OPEN % filename
END_TRANS = "--END--\n"
NOT_FOUND = "404\n"
FIND_SERVER = "--WHERE_IS:%s\n"
OPEN_FILE = "--OPEN:%s\n"
WRITE_FILE = "--WRITE:%s\n"
KILL = "KILL_SERVICE\n"
ACTION = "--ACTION:%d\n"

  def initialize
    @dir_server_address = 'localhost'
    @dir_server_port = 3001
    @output_dir = './local/'
    @get_listing = '--file_list--'
    @find_server = 'where_is:'
    @open_file = 'open:'
    @end_transmission = '--END--'
    @not_found = '404'
  end

  def directory_server(filename, msg)
    ds = TCPSocket.new @dir_server_address, @dir_server_port
    ds.puts(msg % filename)
    reply = ds.readline
    ds.close
    reply
  end

  def open(filename)
    reply = directory_server(filename, FIND_SERVER)
    if reply == NOT_FOUND
      puts 'File does not exist'
    else
      address = reply.strip.split(':')
      ip = address[0]
      port = address[1]
      fs = TCPSocket.new ip, port
      fs.puts(OPEN_FILE % filename)
      save_file(fs, filename)
    end
  end

  def save_file(fs, filename)
    File.open(@output_dir+filename, 'w') do |file|
      #while chunk = as this may not work
      #fs.read(size) do |chunk|
      #  file.write(chunk)
      #end
      fs.each_line do |line|
        puts line
        if line == END_TRANS
          puts 'File saved'
        else
          file.write(line)
        end
      end
    end
  end

  def write(filename)
    filename = filename.strip
    address = directory_server(filename, WRITE_FILE)
    (ip, port) = address.strip.split(':')
    TCPSocket.open ip, port do |fs|
      fs.puts(WRITE_FILE % filename)
      reply = fs.readline
      if reply.equal?(END_TRANS)
        puts 'Failed to add file...'
      else
        File.open(@output_dir+filename, 'r') do |file|
          file.each_line do |line|
            fs.puts(line)
          end
        end
        fs.puts(END_TRANS)
        fs.flush
      end
    end
  end

end