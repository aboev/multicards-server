var app = require('http').createServer();
var server;
if (process.env['ENV'] == 'test')
  server = app.listen(5002);
else if (process.env['ENV'] == 'development')
  server = app.listen(5003);
else
  server = app.listen(5001);
var io = require('socket.io').listen(server);
var fs = require('fs');
var redis = require('redis').createClient();
var consts = require('./consts.js');
var http = require('http');
var utf8 = require('utf8');
var protocol = require('./protocol.js');
http.post = require('http-post');

redis.subscribe(consts.SOCK_CHANNEL);

redis.on('message', function(channel, message){
  protocol.msg_int(io, channel, message);
});

io.on('connection', function(socket){
  protocol.announce_socket_id(io, socket.id);

  socket.on('message', function(message){
    protocol.msg_ext(io, socket, message);
  });

  socket.on('disconnect', function() {
    console.log('Disconnected ' + socket.id);
    json_msg = protocol.make_json_msg(null, consts.SOCK_MSG_TYPE_SOCKET_CLOSE, socket.id);
    protocol.http_post_local(json_msg);
  });

});
