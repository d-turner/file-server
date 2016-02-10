
module Protocol
  # Constants
  END_TRANS    = '--END--'
  NOT_FOUND    = '--404--'
  KILL         = '--KILL_SERVICE--'
  GET_LISTING  = '--FILE_LIST--'
  JOIN_REQUEST = '--JOIN_REQUEST--'
  ACCEPT       = '--ACCEPT--'
  DECLINE      = '--DECLINE--'
  HELO         = 'HELO'
  DIR_ADD      = 'localhost'
  DIR_PORT     = 3001
  # Constants with argument
  SESSION_KEY  = '--SESSION_KEY:'
  TICKET       = '--TICKET:'
  FIND_SERVER  = '--WHERE_IS:'
  OPEN_FILE    = '--OPEN:'
  WRITE_FILE   = '--WRITE:'
  ACTION       = '--ACTION:'
  AUTH_USER    = '--AUTHENTICATE:'
  IP_ADD       = '--IP:'
  PORT_ADD     = '--PORT:'
end
