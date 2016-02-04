class Qcardset < ActiveRecord::Base

  def add_like(userid)
    update_attributes likes: likes + [ userid ]
    self.like_count = self.like_count + 1
  end

  def remove_like(userid)
    update_attributes likes: likes - [ userid ]
    self.like_count = self.like_count - 1
  end

  def add_tag(tagid)
    update_attributes tags: tags + [ tagid ]
  end

  def remove_tag(tagid)
    update_attributes tags: tags - [ tagid ]
  end

  def add_flag(flagid)
    if !flags.include?(flagid.to_s)
      update_attributes flags: flags + [ flagid ]
    end
  end

  def remove_flag(flagid)
    if flags.include?(flagid.to_s)
      update_attributes flags: flags - [ flagid ]
    end
  end

end
