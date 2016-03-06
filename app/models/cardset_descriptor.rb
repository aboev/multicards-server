class CardsetDescriptor
  @@gid = ""
  @@title = ""
  @@created_by = ""
  @@lang_terms = ""
  @@lang_definitions = ""
  @@like_count = 0
  @@flags = []

  def self.from_qcardset(qcardset)
    @@title = qcardset.title
    @@gid = "quizlet_" + qcardset.cardset_id.to_s
    @@lang_terms = qcardset.lang_terms
    @@lang_definitions = qcardset.lang_definitions
    @@like_count = qcardset.like_count
    @@flags = qcardset.flags
    return self
  end

  def self.from_qcardset_list(qcardset_list)
    res = []
    qcardset_list.each do |item|
      res << from_qcardset(item).to_json
    end
    return res
  end

  def self.to_json 
    {:gid => @@gid, :title => @@title, :lang_terms => @@lang_terms, :lang_definitions => @@lang_definitions, :like_count => @@like_count, :flags => @@flags}
  end

end
