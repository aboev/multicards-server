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
  if Utils.import_cardset(gid) == false
    msg = { :result => Constants::RESULT_ERROR }
  end
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

end
