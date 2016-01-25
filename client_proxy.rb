require 'socket'
class Client_Proxy
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

  def open(filename)
    # directory server
    reply = ds(filename)
    reply = reply.strip
    if reply == @not_found
      puts 'File does not exist'
    else
      # file server
      reply= reply.split(':')
      address = reply[0]
      port = reply[1]
      fs = TCPSocket.new address, port
      fs.puts(@open_file+filename)
      save_file(fs, filename)
      fs.close
    end
  end

  def ds(filename)
    ds = TCPSocket.new @dir_server_address, @dir_server_port
    ds.puts(@find_server + filename)
    reply = ds.readline
    ds.close
    reply
  end

  def save_file(fs, filename)
    #size = fs.readline
    File.open(@output_dir+filename, 'w') do |file|
      #while chunk = as this may not work
      #fs.read(size) do |chunk|
      #  file.write(chunk)
      #end
      fs.each_line do |line|
        if line.strip == @end_transmission
          break
        end
          file.write(line)
      end
    end
  end

end