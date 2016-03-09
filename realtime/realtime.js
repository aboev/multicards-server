var app = require('http').createServer();
var server;
var redis = require('redis').createClient();
var consts = require('./consts.js');
if (process.env['ENV'] == 'test') {
  server = app.listen(5002);
  redis.subscribe(consts.SOCK_CHANNEL_TEST);
} else if (process.env['ENV'] == 'development') {
  server = app.listen(5003);
  redis.subscribe(consts.SOCK_CHANNEL_DEV);
} else {
  server = app.listen(5001);
  redis.subscribe(consts.SOCK_CHANNEL_PROD);
}
var io = require('socket.io').listen(server);
var fs = require('fs');
var http = require('http');
var utf8 = require('utf8');
var protocol = require('./protocol.js');
http.post = require('http-post');

redis.on('message', function(channel, message){
  protocol.msg_int(io, message);
});

io.on('connection', function(socket){
  protocol.announce_socket_id(io, socket.id);

  socket.on('message', function(message){
    protocol.msg_ext(io, socket, message);
  });

  socket.on('disconnect', function() {
    protocol.log_msg('Disconnected ' + socket.id);
    json_msg = protocol.make_json_msg(null, consts.SOCK_MSG_TYPE_SOCKET_CLOSE, socket.id);
    protocol.http_post_local(json_msg);
  });

});
