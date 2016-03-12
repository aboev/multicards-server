require 'constants'
require 'net/http'
require 'utils'

class CardsetController < ApplicationController
skip_before_filter :verify_authenticity_token
before_filter :check_credentials

def search
  offset = request.headers[Constants::HEADER_OFFSET]
  limit = request.headers[Constants::HEADER_LIMIT]
  tag_ids = request.headers[Constants::HEADER_TAGID]
  query = request.headers[Constants::HEADER_QUERY]
  limit = 50 if limit == nil

  res = []
  if tag_ids != nil
    tags = tag_ids.split(",")
    qcardset_list = Qcardset.where('? = ANY(tags)', tags[0]).limit(limit)
    tags.each do |tagid|
      qcardset_list = qcardset_list.where('? = ANY(tags)', tagid)
    end

    res = CardsetDescriptor.from_qcardset_list(qcardset_list, false)
  elsif query != nil
    res = Utils.search_qcardset_page(query, 1)
  end
  ret_ok(res)
  return
end

def get
  gid = request.headers[Constants::HEADER_SETID]
  set_id = Utils.parse_gid(gid)[1]
  provider = Utils.parse_gid(gid)[0]
  qcardset = Utils.get_qcardset(gid)
  if ((provider == "quizlet") and (qcardset != nil))
    ret_ok(CardsetDescriptor.from_qcardset_list([qcardset]))
  else
    ret_error(Constants::ERROR_CARDSET_NOT_FOUND, Constants::MSG_CARDSET_NOT_FOUND)
  end
end

def import
  gid = request.headers[Constants::HEADER_SETID]
  msg = { :result => Constants::RESULT_OK }
  if Utils.import_qcardset(gid) == false
    msg = { :result => Constants::RESULT_ERROR }
  end
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

def popular
  limit = 50  
  qcardset_list = Qcardset.where("like_count > 0").order('like_count DESC').limit(limit)
  res = CardsetDescriptor.from_qcardset_list(qcardset_list, false)
  msg = { :result => Constants::RESULT_OK, :data => res }
  respond_to do |format|
    format.json  { render :json => msg.to_json }
  end
end

def like
  gid = request.headers[Constants::HEADER_SETID]
  Utils.like(gid, @user.id)
  msg = { :result => Constants::RESULT_OK }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

def unlike
  gid = request.headers[Constants::HEADER_SETID]
  Utils.unlike(gid, @user.id)
  msg = { :result => Constants::RESULT_OK }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

def get_tags
  tags = TagDescriptor.all
  tags.each do |tag|
    tag_name_json = JSON.parse(tag.tag_name)
    tag.tag_name = tag_name_json
  end
  msg = { :result => Constants::RESULT_OK, :data => tags }
  respond_to do |format|
    format.json  { render :json => msg.to_json }
  end
end

def put_tag
  gid = request.headers[Constants::HEADER_SETID]
  tagids = request.headers[Constants::HEADER_TAGID]
  tagids.split(",").each do |tagid|
    Utils.tag(gid, tagid, @user.id)
  end

  msg = { :result => Constants::RESULT_OK }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

def drop_tag
  gid = request.headers[Constants::HEADER_SETID]
  tagids = request.headers[Constants::HEADER_TAGID]
  tagids.split(",").each do |tagid|
    Utils.untag(gid, tagid)
  end
  msg = { :result => Constants::RESULT_OK }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

def put_flag
  gid = request.headers[Constants::HEADER_SETID]
  flagids = request.headers[Constants::HEADER_FLAGID]
  flagids.split(",").each do |flagid|
    Utils.flag(gid, flagid)
  end

  msg = { :result => Constants::RESULT_OK }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

def drop_flag
  gid = request.headers[Constants::HEADER_SETID]
  flagids = request.headers[Constants::HEADER_FLAGID]
  flagids.split(",").each do |flagid|
    Utils.unflag(gid, flagid)
  end
  msg = { :result => Constants::RESULT_OK }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

def ret_ok (data)
  msg = { :result => Constants::RESULT_OK, :data => data }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

def ret_error(err_code, err_msg)
  msg = { :result => Constants::RESULT_ERROR, :code => err_code, :msg => err_msg }
  respond_to do |format|
    format.json  { render :json => msg }
  end
end

end
