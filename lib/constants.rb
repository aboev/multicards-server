class Constants
  SOCK_MSG_TYPE_NEW_EVENT=	"new_event"
  SOCK_MSG_TYPE_NEW_QUESTION=	"new_question"
  SOCK_MSG_TYPE_PLAYER_STATUS_UPDATE="player_status"
  SOCK_MSG_TYPE_PLAYER_ANSWERED	="player_answered"
  SOCK_MSG_TYPE_PLAYER_TYPED	="player_typed"
  SOCK_MSG_TYPE_SOCKET_CLOSE	="socket_disconnected"
  SOCK_MSG_TYPE_GAME_END	="game_end"
  SOCK_MSG_TYPE_QUIT_GAME	="quit_game"
  SOCK_MSG_TYPE_GAME_START	="game_start"
  SOCK_MSG_TYPE_ANNOUNCE_USERID	="announce_userid"

  JSON_GAME_ID		=	"game_id"
  JSON_GAME_STATUS	=	"status"
  JSON_GAME_PLAYERS	=	"players"
  JSON_GAME_SCORES	=	"scores"
  JSON_GAME_PROFILES	=	"profiles"
  JSON_GAME_CURQUESTION	=	"question"
  JSON_GAME_QUESTIONCNT	=	"question_count"
  JSON_GAME_QUESTIONTYPE=	"question_type"
  JSON_GAME_SETID	=	"setid"

  JSON_USER_SOCKETID	=	"socketid"
  JSON_USER_ID		=	"id"
  JSON_USER_AVATAR	=	"avatar"

  JSON_SOCK_MSG_TO	=	"id_to"
  JSON_SOCK_MSG_FROM	=	"id_from"
  JSON_SOCK_MSG_BODY	=	"msg_body"
  JSON_SOCK_MSG_TYPE	=	"msg_type"
  JSON_SOCK_MSG_GAMEID	=	"game_id"
  JSON_SOCK_MSG_EVENTTYPE=	"event"
  JSON_SOCK_MSG_DATA	=	"data"

  JSON_SOCK_MSG_NEW_EVENT_TYPE=	"event"
  JSON_SOCK_MSG_NEW_EVENT_DATA=	"data"

  JSON_QST_QUESTION	=	"question"
  JSON_QST_OPTIONS	=	"options"
  JSON_QST_ANSWER_ID	=	"answer_id"

  RESULT_OK             =       "OK"
  RESULT_ERROR          =       "ERROR"

  ERROR_JSON_PARSE      =       101
  MSG_JSON_PARSE        =       "JSON parse error"
  ERROR_BODY_FORMAT     =       102
  MSG_BODY_FORMAT       =       "Missing required argument in body"
  ERROR_NOT_FOUND       =       103
  MSG_NOT_FOUND         =       "Entry not found"

  HEADER_USERID         =       "id"
  HEADER_SOCKETID       =       "socketid"

  SOCK_CHANNEL          =       "events"

  SOCK_EV_NEW_GAME      =       "game_start"


end
