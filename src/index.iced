Socket = require 'sockjs-client'
{EventEmitter2} = require 'EventEmitter2'

if SERVER?
  Socket = new WebSocket "ws://#{window.location.hostname}:3000"
else
  Socket = new SockJS "http://#{window.location.hostname}:3000/socket"
emitter = new EventEmitter2
  wildcard: true
  delimiter: '.'
  maxListeners: 20
emitter.onAny ->
  Socket.send JSON.stringify [@event].concat arguments
Socket.onopen ->
  emitter.emit 'socket.open'
Socket.onclose ->
  emitter.emit 'socket.close'
Socket.onmessage (e) ->
  [command, args] = JSON.parse e.data
  emitter[command].apply emitter, args

module.exports = emitter