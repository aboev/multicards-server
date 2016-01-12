require 'constants'
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

    json_body.each do |key, value|
        cur_details[key] = value
    end
    self.details = cur_details.to_json
  end

  def get_details
    details = JSON.parse(self.details)
    details[Constants::JSON_USER_ID] = self.id
    return details
  end

  def self.find_by_name(name)
    users = User.all
    users.each do |user|
      details = user.get_details
      if ((details["name"] != nil) and (details["name"] == name))
        return user
      end
    end
    return nil
  end

end
