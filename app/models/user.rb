require 'constants'
require 'utils'

class User < ActiveRecord::Base
  @@name = ""
  @@phone = ""
  @@email = ""
  @@avatar = ""

  def to_json
    details_json = JSON.parse(self.details)
    @@name = details_json['name']
    @@phone = details_json['phone']
    @@email = details_json['email']
    @@avatar = details_json['avatar']
    {:id => self.id, :name => @@name, :avatar => @@avatar}
  end

  def update(json_body)
    if ((self.details == nil) or (self.details.length == 0))
      cur_details = {}
    else
      cur_details = JSON.parse(self.details)
    end

    if ((json_body['name'] != nil) and (json_body['name'].length > 0))
      ex_user = User.find_by_name(json_body['name'])
      return false if ((ex_user != nil) and (ex_user.id != self.id))
    end

    if ((json_body[Constants::JSON_USER_DEVICEID] != nil) and (json_body[Constants::JSON_USER_DEVICEID].length > 0))
      ex_user = User.where(:deviceid => json_body[Constants::JSON_USER_DEVICEID]).first
      return false if ((ex_user != nil) and (ex_user.id != self.id))
    end

    json_body.each do |key, value|
      if key == Constants::KEY_PUSHID
        self.pushid = value
      elsif key == Constants::JSON_USER_DEVICEID
        self.deviceid = value
      elsif key == "name"
        self.name = value
        cur_details[key] = value
      else
        cur_details[key] = value
      end
    end
    self.details = cur_details.to_json
    return true
  end

  def get_details
    details = JSON.parse(self.details)
    details[Constants::JSON_USER_ID] = self.id
    return details
  end

  def init
    details = JSON.parse(self.details)
    
    if ((details["name"] == nil) or (details["name"].length == 0))
      username = Utils.make_nickname
      tries = 0
      while ((User.find_by_name(username) != nil) and (tries < 20))
        username = Utils.make_nickname
        tries = tries + 1
      end
      if tries < 20
        details["name"] = username
      end
    end

    if ((details["avatar"] == nil) or (details["avatar"].length == 0))
      avatar_prefix = APP_CONFIG['avatar_prefix']
      index = rand(1 .. 20)
      avatar_url = "%s/%s/%s%02d.png" % [APP_CONFIG['server_prefix'], "uploads", APP_CONFIG['avatar_prefix'], rand(1 .. 20)]
      details["avatar"] = avatar_url
    end
    
    self.name = username
    self.details = details.to_json
    self.save
  end

  def self.find_by_name(name)
    user = User.where(:name => name).first
    return user if user != nil
    users = User.all
    users.each do |user|
      details = user.get_details
      if ((details["name"] != nil) and (details["name"] == name))
        user.name = name
        return user
      end
    end
    return nil
  end

  def self.find_by_socket_id(socketid)
    user = User.where(:socket_id => socketid).first
    return user
  end

  def self.find_by_device_id(deviceid)
    if ((deviceid != nil) and (deviceid.length > 0))
      user = User.where(:deviceid => deviceid).first
      return user
    else
      return nil
    end
  end

end
