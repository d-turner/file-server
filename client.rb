require 'socket'

soc = TCPSocket.new 'localhost', 3001
msg = 'open /A/./testDir/testfile2.sh'
soc.puts(msg)
address = soc.readline
soc.close

if address == "\n"
  puts 'Server not found'
else
  #msg = "open /home/dan/Documents/git/fileServer/testDir/testfile2.sh\n"
  msg = 'open /etc/ts.conf'
  soc = TCPSocket.new 'localhost', address.to_i
  soc.puts(msg)
  file = File.open('./testDir/output.txt', 'w')
  soc.each_line do |line|
    file.write(line)
  end
  file.close
  soc.close
end
