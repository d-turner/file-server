require "./directory_service"
include Directory_Service
file = openFile(".", "hello.txt")
puts readFile(file)