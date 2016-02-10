require 'aescrypt'
require 'base64'
require 'rubygems'
require './protocol'

module MyCipher
  include Protocol
  def get_session_key(data)
    ticket = decrypt(data, @server_key)
    if ticket.start_with?(TICKET)
      ticket.strip.split(':')[1]
    else
      puts 'Failed to get session key'
      nil
    end
  end

  def encrypt(msg, key)
    encrypted = AESCrypt.encrypt(msg, key)
    [encrypted].pack('m0')
  end

  def decrypt(encoded, key)
    encrypted = encoded.strip.unpack('m0')[0]
    AESCrypt.decrypt(encrypted, key)
  end
end