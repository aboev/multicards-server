require 'constants'
require 'net/http'
require 'utils'

class SearchController < ApplicationController
skip_before_filter :verify_authenticity_token
before_filter :check_credentials

def search
  query = request.headers[Constants::HEADER_QUERY]
  res = Qcardset.where("title LIKE ?", "%#{query}%") 
  msg = { :result => Constants::RESULT_OK, :data => res.to_json }
  respond_to do |format|
    format.json  { render :json => msg }
  end    
end

def popular
  query = request.headers[Constants::HEADER_QUERY]
  res = Qcardset.where("like_count > 0 ORDER BY like_count DESC LIMIT 50")
  msg = { :result => Constants::RESULT_OK, :data => res.to_json }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

end
