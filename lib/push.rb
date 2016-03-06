require 'net/http'
class PushSender
  EVENT_GAME_INVITATION	= 	0

  def self.perform(id, event, msg)
    if APP_CONFIG['ENABLE_PUSH'] != 1
      return
    end

    user = User.where(id: id).first
    if ((user == nil) or (user.pushid == nil) or (user.pushid.length == 0))
      return
    end

    http = Net::HTTP.new('android.googleapis.com', 80)
    request = Net::HTTP::Post.new('/gcm/send', 
      {'Content-Type' => 'application/json',
       'Authorization' => 'key=' + APP_CONFIG['google_api_key']})
    data = {:registration_ids => [user.pushid], :data => {:event => event, :msg => msg}}
    request.body = data.to_json
    response = http.request(request)
    if response.kind_of? Net::HTTPSuccess
      Rails.logger.debug "Notification sent to user " + user.id.to_s + ", response message: " + response.body
    else
      Rails.logger.debug "Failed to send notification to user " + user.id.to_s + ", response message: " + response.body
    end
  end

end
