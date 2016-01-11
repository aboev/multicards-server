class Qcardset < ActiveRecord::Base

  def add_like(userid)
    update_attributes likes: likes + [ userid ]
    self.like_count = self.like_count + 1
  end

  def remove_like(userid)
    update_attributes likes: likes - [ userid ]
    self.like_count = self.like_count - 1
  end

end
