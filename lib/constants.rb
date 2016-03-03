class Constants
  SOCK_MSG_TYPE_NEW_EVENT=	"new_event"
  SOCK_MSG_TYPE_NEW_QUESTION=	"new_question"
  SOCK_MSG_TYPE_PLAYER_STATUS_UPDATE="player_status"
  SOCK_MSG_TYPE_PLAYER_ANSWERED	="player_answered"
  SOCK_MSG_TYPE_PLAYER_TYPED	="player_typed"
  SOCK_MSG_TYPE_SOCKET_CLOSE	="socket_disconnected"
  SOCK_MSG_TYPE_GAME_END	="game_end"
  SOCK_MSG_TYPE_GAME_STOP	="game_stop"
  SOCK_MSG_TYPE_QUIT_GAME	="quit_game"
  SOCK_MSG_TYPE_GAME_START	="game_start"
  SOCK_MSG_TYPE_GAME_INVITE	="game_invite"
  SOCK_MSG_TYPE_INVITE_ACCEPTED	="invite_accepted"
  SOCK_MSG_TYPE_INVITE_REJECTED	="invite_rejected"
  SOCK_MSG_TYPE_ANNOUNCE_USERID	="announce_userid"
  SOCK_MSG_TYPE_ANNOUNCE_SOCKID	="socket_id_announce"
  SOCK_MSG_TYPE_ANSWER_ACCEPTED	="answer_accepted"
  SOCK_MSG_TYPE_ANSWER_REJECTED	="answer_rejected"
  SOCK_MSG_TYPE_CHECK_NAME	="check_name"
  SOCK_MSG_TYPE_CHECK_NETWORK	="check_network"
  SOCK_MSG_TYPE_ON_CONNECTED	="connected"
  SOCK_MSG_TYPE_NEW_BONUS	="new_bonus"
  SOCK_MSG_TYPE_SET_GID		="set_gid"
  SOCK_MSG_TYPE_CONFIRM		="receive_confirm"
  SOCK_MSG_TYPE_CUSTOM		="custom"

  JSON_GAME_ID		=	"game_id"
  JSON_GAME_GID		=	"game_gid"
  JSON_GAME_STATUS	=	"status"
  JSON_GAME_PLAYERS	=	"players"
  JSON_GAME_SCORES	=	"scores"
  JSON_GAME_PROFILES	=	"profiles"
  JSON_GAME_CURQUESTION	=	"question"
  JSON_GAME_QUESTIONCNT	=	"question_count"
  JSON_GAME_SETID	=	"setid"
  JSON_GAME_OPPONENTID	=	"opponentid"
  JSON_GAME_PREVQST	=	"prev_questions"
  JSON_GAME_GAMEPLAYDATA=	"gameplay_data"
  JSON_GAME_BONUSES	=	"bonuses"
  JSON_GAME_TOTAL_QUESTIONS=	"total_questions"
  JSON_GAME_WINNER_ID	=	"winner"

  JSON_USER_SOCKETID	=	"socketid"
  JSON_USER_ID		=	"id"
  JSON_USER_AVATAR	=	"avatar"
  JSON_USER_NAME	=	"name"
  JSON_USER_DEVICEID	=	"deviceid"

  JSON_INVITATION_USER	=	"user"
  JSON_INVITATION_GAME	=	"game"
  JSON_INVITATION_CARDSET=	"cardset"

  JSON_SOCK_MSG_TO	=	"id_to"
  JSON_SOCK_MSG_FROM	=	"id_from"
  JSON_SOCK_MSG_BODY	=	"msg_body"
  JSON_SOCK_MSG_TYPE	=	"msg_type"
  JSON_SOCK_MSG_EXTRA	=	"msg_extra"
  JSON_SOCK_MSG_ID	=	"msg_id"
  JSON_SOCK_MSG_GAMEID	=	"game_id"
  JSON_SOCK_MSG_EVENTTYPE=	"event"
  JSON_SOCK_MSG_DATA	=	"data"

  JSON_SOCK_MSG_NEW_EVENT_TYPE=	"event"
  JSON_SOCK_MSG_NEW_EVENT_DATA=	"data"

  JSON_QST_ID		=	"question_id"
  JSON_QST_QUESTION	=	"question"
  JSON_QST_OPTIONS	=	"options"
  JSON_QST_IMAGES	=	"images"
  JSON_QST_ANSWER_ID	=	"answer_id"
  JSON_QST_TYPE		=	"question_type"
  JSON_QST_STATUS	=	"question_status"

  RESULT_OK             =       "OK"
  RESULT_ERROR          =       "ERROR"

  ERROR_JSON_PARSE      =       101
  MSG_JSON_PARSE        =       "JSON parse error"
  ERROR_BODY_FORMAT     =       102
  MSG_BODY_FORMAT       =       "Missing required argument in body"
  ERROR_NOT_FOUND       =       103
  MSG_NOT_FOUND         =       "Entry not found"
  ERROR_NAME_EXISTS	=	104
  MSG_NAME_EXISTS	=	"Name already exists"
  ERROR_USER_NOT_FOUND  =       105
  MSG_USER_NOT_FOUND    =       "User not found"
  ERROR_GAME_NOT_FOUND  =       106
  MSG_GAME_NOT_FOUND    =       "Game not found"
  ERROR_CARDSET_EMPTY   =       107
  MSG_CARDSET_EMPTY     =       "Cardset is empty or too small"
  ERROR_CARDSET_NOT_FOUND=      108
  MSG_CARDSET_NOT_FOUND =       "Cardset not found"
  ERROR_MISSING_HEADER  =       109
  MSG_MISSING_HEADER    =       "Missing required header"

  HEADER_USERID         =       "id"
  HEADER_USERNAME       =       "name"
  HEADER_SOCKETID       =       "socketid"
  HEADER_SETID		=       "setid"
  HEADER_TAGID		=       "tagid"
  HEADER_FLAGID		=       "flagid"
  HEADER_QUERY	        =       "query"
  HEADER_OPPONENTNAME   =       "opponentname"
  HEADER_OFFSET 	=       "offset"
  HEADER_LIMIT		=       "limit"
  HEADER_IDS		=       "ids"
  HEADER_MULTIPLAYER_TYPE=       "multiplayerType"
  HEADER_GAMEID		=       "gameid"

  SOCK_EV_NEW_GAME      =       "game_start"

  DB_FLAG_INVERT	=	1
  DB_FLAG_EMPTY		=	2
  DB_FLAG_INAPPROP	=	3
  DB_FLAG_MISTAKE	=	4

  SCORE_PER_WIN		=	5
  SCORE_PER_GAME	=	2

  GAMEPLAY_Q_PER_G	=	25
  GAMEPLAY_O_PER_Q	=	4

  FLAG_INVERTED		=	0
  FLAG_DISCOVERED	=	1

  KEY_SERVER_VERSION	=	"version"
  KEY_MIN_CLIENT_VERSION=	"min_client"
  KEY_LATEST_APK_URL	=	"latest_apk"
  KEY_LATEST_APK_VER	=	"latest_ver"
  KEY_UPDATE_COMMENT	=	"update_comment"
  KEY_PUSHID		=	"pushid"

  BONUS_WINNER		=	{:bonus_title => {:en => "Winner bonus", :ru => "Бонус победителя"}, :bonus => 50, :bonus_id => 2, :description => {:en => "Bonus for the player with most correct answers", :ru => "Бонус игрока с максимальным количество правильных ответов"}}
  BONUS_DISCOVERER	=	{:bonus_title => {:en => "Discoverer bonus", :ru => "Бонус первооткрывателя"}, :bonus => 10, :bonus_id => 1, :description => {:en => "Bonus for the first discoverer of the cardset", :ru => "Бонус первооткрывателю набора"}}
  BONUS_MODERATOR	=	{:bonus_title => {:en => "Moderator bonus", :ru => "Бонус модератора"}, :bonus => 10, :bonus_id => 3, :description => {:en => "Bonus for moderating the cardset", :ru => "Бонус за модерирование набора"}}

  TAG_APPLY_THRESHOLD	=	2
  FLAG_APPLY_THRESHOLD	=	2

  STATUS_ONLINE		=	1
  STATUS_OFFLINE	=	2

  MULTIPLAYER_TYPE_JOIN	=	"0"
  MULTIPLAYER_TYPE_NEW	=	"1"

  ROBOT_NAME		=	"Robot"

end

