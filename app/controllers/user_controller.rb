require 'constants'
require 'utils'

class UserController < ApplicationController
skip_before_filter :verify_authenticity_token
before_filter :check_credentials, :except => [:new]

def new
  json_body = JSON.parse(request.body.read)
  user = User.new
  user.details = json_body.to_json
  user.save
  user.init
  msg = { :result => Constants::RESULT_OK, :data => user.to_json }
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
