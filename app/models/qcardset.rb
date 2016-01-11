class Qcardset < ActiveRecord::Base

  def add_like(userid)
    update_attributes likes: likes + [ userid ]
  end

  def remove_like(userid)
    update_attributes likes: likes - [ userid ]
  end

end
