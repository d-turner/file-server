#Ruby Distributed File Server
###Structure
Modules and classes for Replication, Locking and Transactions

### Ruby Dependencies

Ruby Version 2.7.*
Requires thread, socket
Added
### Need to add 
A client side file proxy should be provided that hides all access to the file system behind a simple language specific mechanism, such as a Java interface 
So add a file class and add methods like
File_class.open(filename)
def open(filename)
  does socket stuff here
end
