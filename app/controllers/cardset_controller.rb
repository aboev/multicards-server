require 'constants'
require 'net/http'
require 'utils'

class CardsetController < ApplicationController
skip_before_filter :verify_authenticity_token
before_filter :check_credentials

def get
  json_body = JSON.parse(request.body.read)
  cardsets = Cardset.all
  msg = { :result => Constants::RESULT_OK, :data => cardsets.to_json }
  respond_to do |format|
    format.json  { render :json => msg }
  end    
end

def import
  gid = request.headers['setid']
  msg = { :result => Constants::RESULT_OK }
  if Utils.import_qcardset(gid) == false
    msg = { :result => Constants::RESULT_ERROR }
  end
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

def popular
  res = Qcardset.where("like_count > 0 ORDER BY like_count DESC LIMIT 50")
  msg = { :result => Constants::RESULT_OK, :data => res.to_json }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

def like
  gid = request.headers['setid']
  Utils.like(gid, @user.id)
  msg = { :result => Constants::RESULT_OK }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

def unlike
  gid = request.headers['setid']
  Utils.unlike(gid, @user.id)
  msg = { :result => Constants::RESULT_OK }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

end
