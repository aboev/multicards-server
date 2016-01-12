require 'constants'
require 'utils'

class UserController < ApplicationController
skip_before_filter :verify_authenticity_token
before_filter :check_credentials, :except => [:new]

def new
  json_body = JSON.parse(request.body.read)
  user = User.new
  if (json_body["name"] == nil)
    name = Utils.make_nickname
    tries = 0
    while ((User.find_by_name(name) != nil) and (tries < 20))
      name = Utils.make_nickname
      tries = tries + 1
    end
    if tries < 20
      json_body["name"] = name
    end
  end
  user.details = json_body.to_json
  user.save
  msg = { :result => Constants::RESULT_OK, :data => { :id => user.id, :details => json_body } }
  respond_to do |format|
    format.json  { render :json => msg }
  end    
end

def update
  new_details = JSON.parse(request.body.read)
  @user.update(new_details)
  @user.save
  msg = { :result => "OK"}
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

end
