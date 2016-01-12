#Ruby Distributed File Server
###Structure
Modules and classes for Replication, Locking and Security 

### Ruby Dependencies

Ruby Version 2.7.*
Requires thread, socket

### Need to add 
A client side file proxy should be provided that hides all access to the file system behind a simple language specific mechanism, such as a Java interface 
So add a file class and methods
````
File_class.open(filename)
def open(filename)
  socket stuff here
end
````

### Directory server
## Initialize the directory server
Scan / Query the file servers for a list of directories and files
Map the returned values to the ip and port addresses of the servers
Each user can access all files on any server or
can implement user based directory structure if doing authentication

### Security 
## Kerberos

### Locking
Dictionary of booleans?
