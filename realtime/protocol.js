var consts = require('./consts.js');
var http = require('http');
http.post = require('http-post');
var rails_server;
if (process.env['ENV'] == 'test')
  rails_server = consts.RAILS_SERVER_TEST;
else
  rails_server = consts.RAILS_SERVER;

exports.msg_ext = function (io, socket, msg) {
  msg_json = JSON.parse(msg);
  msg_json.id_from = socket.id;
  console.log('Processing message: ' + JSON.stringify(msg_json));
  if ((msg_json.id_to != null) && (msg_json.id_to.length > 0)) {
    for (var i = 0; i < msg_json.id_to.length; i++)
      io.to(msg_json.id_to[i]).emit('event', JSON.stringify(msg_json));
    this.http_post_local(msg_json);
  } else {
    this.http_post_local(msg_json);
  }
};

exports.msg_int = function (io, msg) {
  console.log('got redis message ' + msg);
  msg_json = JSON.parse(msg);
  for (var i = 0; i < msg_json.id_to.length; i++) {
    io.to(msg_json.id_to[i]).emit('event', msg);
    console.log('sending message to ' + msg_json.id_to[i]);
  }
};

exports.make_json_msg = function (idto, msgtype, msgbody) {
  msg_json = { id_to: idto, msg_type: msgtype, msg_body: msgbody };
  return msg_json;
};

exports.announce_socket_id = function (io, socket_id) {
  msg = JSON.stringify( this.make_json_msg (null, consts.SOCK_MSG_TYPE_ANNOUNCE_SOCKETID, socket_id) );
  console.log("Sending " + msg);
  io.to(socket_id).emit('event', msg);
};

exports.http_post_local = function (json_msg) {
  'use strict';
 
  var parse = require('url-parse'), url = parse(rails_server, true);

  var data = JSON.stringify(json_msg);

  var options = {
    host: url.hostname,
    port: url.port,
    path: url.pathname,
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Accept': '*/*',
        'Content-Length': Buffer.byteLength(data)
    }
  };

  var req = http.request(options, function(res) {
    res.setEncoding('utf8');
    res.on('data', function (chunk) {
        console.log("body: " + chunk);
    });
  });

  req.write(data);
  req.end();

};
