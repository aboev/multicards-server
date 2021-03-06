require 'constants'
require 'utils'

class UserController < ApplicationController
skip_before_filter :verify_authenticity_token
before_filter :check_credentials, :except => [:new]

def new
  json_body = JSON.parse(request.body.read)
  user = User.find_by_device_id(json_body[Constants::JSON_USER_DEVICEID])
  if user == nil
    user = User.new
    user.details = json_body.to_json
    user.score = 0
    user.status = Constants::STATUS_ONLINE
    user.save
    user.init
  end
  msg = { :result => Constants::RESULT_OK, :data => user.to_json }
  respond_to do |format|
    format.json  { render :json => msg }
  end    
end

def update
  new_details = JSON.parse(request.body.read)
  msg = { }
  if @user.update(new_details)
    @user.save
    msg = { :result => Constants::RESULT_OK, :data => @user.to_json }
  else
    msg = { :result => Constants::RESULT_ERROR }  
  end
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

def get
  userid = request.headers[Constants::HEADER_USERID]
  username = request.headers[Constants::HEADER_USERNAME]
  
  msg = { }
  user = {}
  if (username != nil)
    user = User.find_by_name(username)
  elsif (userid != nil)
    user = User.where(:id => userid).first
  end
  
  if (user != nil)
    msg = { :result => Constants::RESULT_OK, :data => user.to_json }   
  else
    msg = { :result => Constants::RESULT_ERROR }
  end

  respond_to do |format|
    format.json  { render :json => msg }
  end
end

def get_bots
  bots = User.where('status = ? and ? = ANY(flags)', Constants::STATUS_ONLINE, Constants::FLAG_BOT.to_s)

  msg = { :result => Constants::RESULT_OK, :data => bots }

  respond_to do |format|
    format.json  { render :json => msg }
  end
end

def list
  ids = request.headers[Constants::HEADER_IDS]

  res = []
  id_list = ids.split(",")
  id_list.each do |id|
    user = User.where(:id => id).first
    if user != nil
      res << user.get_details
    end
  end

  msg = { :result => Constants::RESULT_OK, :data => res }

  respond_to do |format|
    format.json  { render :json => msg.to_json }
  end
end

end
