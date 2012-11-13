Socket = require 'sockjs-client'
{EventEmitter2} = require 'EventEmitter2'

module.exports = ->
  if SERVER?
    Socket = new WebSocket "ws://#{window.location.hostname}:3000"
  else
    Socket = new SockJS "http://#{window.location.hostname}:3000/socket"
  class ProxyEmitter extends EventEmitter2
    constructor: ->
      super
    on: (event, args...) ->
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
    Socket.send JSON.stringify ['propagate', [@event].concat(args)]
  Socket.onopen = ->
    emitter.emit 'socket.open'
  Socket.onclose = ->
    emitter.emit 'socket.close'
  Socket.onmessage = (e) ->
    [command, args] = JSON.parse e.data
    emitter[command].apply emitter, args
  return emitter