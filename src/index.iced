Socket = require 'sockjs-client'
{EventEmitter2} = require 'EventEmitter2'

if SERVER?
  Socket = new WebSocket "ws://#{window.location.hostname}:3000"
else
  Socket = new SockJS "http://#{window.location.hostname}:3000/socket"
fromServer = false
open = false
class ProxyEmitter extends EventEmitter2
  constructor: ->
    super
  on: (event, cb) ->
    if event is socket.open and open
      do cb
    if event isnt 'socket.open' and event isnt 'socket.close'
      Socket.send JSON.stringify ['subscribe', event]
    super
  off: (event, callback) ->
    if event isnt 'socket.open' and event isnt 'socket.close'
      Socket.send JSON.stringify ['unsubscribe', event]
emitter = new ProxyEmitter
  wildcard: true
  delimiter: '.'
  maxListeners: 20
emitter.onAny (args...) ->
  if !fromServer
    Socket.send JSON.stringify ['propagate', [@event].concat(args)]
  else
    fromServer = false
Socket.onopen = ->
  emitter.emit 'socket.open'
  open = true
Socket.onclose = ->
  emitter.emit 'socket.close'
Socket.onmessage = (e) ->
  fromServer = true
  [command, args...] = JSON.parse e.data
  emitter[command].apply emitter, args

module.exports = emitter