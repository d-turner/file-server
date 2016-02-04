require './client_proxy'
@proxy  = Client_Proxy.new

def print(x)
  c = TCPSocket.new 'localhost', 3001
  c.puts("--ACTION:#{x}\n")
  c.close
end

def kill
  c = TCPSocket.new 'localhost', 3001
  c.puts("KILL_SERVICE\n")
  c.close
end

def helo
  c = TCPSocket.new 'localhost', 3001
  c.puts("HELO anything\n")
  deets = c.readlines
  puts "#{deets}"
  c.close
end

def auth
  puts "Enter user name and press enter\n"
  username = gets.strip
  puts "Enter password and press enter\n"
  password = gets.strip
  @proxy.auth_user(username, password)
end

input = 0
while input != "9\n"

  puts "# Press 1 to retrieve remote file
# Press 2 to save local file to remote server
# Debugging: press 3 to print files on directory server
#            press 4 to print servers on directory server
#            press 5 make directory server query file servers
#            press 6 to KILL all servers
#            press 7 to print HELO message
#            press 8 to authenticate user
# Press 9 to exit\n"
  input = gets
  case input
    when "1\n"
      puts "Enter file name and press enter\n"
      filename = gets
      @proxy.open(filename.strip)
    when "2\n"
      puts "Enter file name and press enter\n"
      filename = gets
      @proxy.write(filename.strip)
    when "3\n"; print(1)
    when "4\n"; print(2)
    when "5\n"; print(3)
    when "6\n"; kill
    when "7\n"; helo
    when "8\n"; auth
    when "9\n"; puts 'Goodbye'
    else puts "I don't understand #{input}"
  end
end