class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :check_credentials

  def check_credentials()
    user_id = request.headers[Constants::HEADER_USERID]
    @socket_id = request.headers[Constants::HEADER_SOCKETID]
    @user = User.find_by_id(user_id)
    if @user.socket_id == nil
      @user.socket_id = @socket_id
      @user.save
    end
    if @user == nil
      msg = { :result => "ERROR", :msg => "Wrong user id" }
      respond_to do |format|
        format.json  { render :json => msg } 
      end
    elsif @socket_id == nil
      msg = { :result => "ERROR", :msg => "Missing socket id" }
      respond_to do |format|
        format.json  { render :json => msg }
      end
    else
      @user_details = JSON.parse(@user.details)  
    end
    if @user.status != Constants::STATUS_ONLINE
      @user.status = Constants::STATUS_ONLINE
      @user.save
    end
  end

  def info
    msg = {:result => Constants::RESULT_OK, :data => {
		Constants::KEY_SERVER_VERSION => APP_CONFIG['server_version'],
		Constants::KEY_MIN_CLIENT_VERSION => APP_CONFIG['min_client_version'],
		Constants::KEY_LATEST_APK_VER => 4,
		Constants::KEY_LATEST_APK_URL => ""}}
    respond_to do |format|
        format.json  { render :json => msg }
    end
  end

end
