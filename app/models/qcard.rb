require 'json'

class Qcard < ActiveRecord::Base

  def get_metacard
    image_json = {}
    begin
      image_json = eval(image) if ((image != nil) and (image.length > 0))
    rescue
    end
    return {Constants::JSON_OPTION_TEXT => definition, Constants::JSON_OPTION_IMAGE => image_json}
  end

end
