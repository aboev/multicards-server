class UploadController < ApplicationController
skip_before_filter :verify_authenticity_token

MEDIUM_WIDTH = 600
SMALL_WIDTH = 200

def upload
  server_prefix = APP_CONFIG['server_prefix']

  image = params[:image]
  name = params[:name]
  local_uri = params[:uri_local]
  img_id = SecureRandom.uuid

  # Processing original image
  name_original = img_id + "_original" + File.extname(name) 
  filepath_original = Rails.root.join('public', 'uploads', name_original)
  url_original = server_prefix + "/uploads/" + name_original

  File.open( filepath_original, 'wb') do |file|
    file.write(image.read)
  end

  image_original = Magick::Image.read( filepath_original ).first
  orig_width = image_original.columns
  orig_height = image_original.rows
  aspect_ratio = orig_height.to_f / orig_width

  # Processing medium thumbnail
  name_medium = img_id + "_medium" + File.extname(name)
  filepath_medium = Rails.root.join('public', 'uploads', name_medium) 
  url_medium = server_prefix + "/uploads/" + name_medium
  medium_height = MEDIUM_WIDTH * aspect_ratio
  image_medium = image_original.resize_to_fit(MEDIUM_WIDTH, medium_height)
  image_medium.write( filepath_medium ){self.quality=100}

  # Processing small thumbnail
  name_small = img_id + "_small" + File.extname(name)
  filepath_small = Rails.root.join('public', 'uploads', name_small)
  url_small = server_prefix + "/uploads/" + name_small
  small_height = SMALL_WIDTH * aspect_ratio
  image_small = image_original.resize_to_fit(SMALL_WIDTH, small_height)
  image_small.write( filepath_small ){self.quality=100}

  # Storing ActiveRecord
  
  details = @user.get_details
  details[Constants::JSON_USER_AVATAR] = url_small
  @user.details = details.to_json
  @user.save

  msg = { :result => "OK", :data => url_small }
  render :json => msg
end

end
