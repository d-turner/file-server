require 'socket'
require './client_proxy'
proxy  = Client_Proxy.new
proxy.open('test1a.txt')