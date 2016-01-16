class TagDescriptor < ActiveRecord::Base

  def self.to_json
    {:tag_id => self.tag_id, :tag_name => @@self.tag_name}
  end

end
