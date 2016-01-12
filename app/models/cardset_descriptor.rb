class CardsetDescriptor
  @@gid = ""
  @@title = ""
  @@created_by = ""

  def self.from_qcardset(qcardset)
    @@title = qcardset.title
    @@gid = "quizlet_" + qcardset.cardset_id.to_s
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
    {:gid => @@gid, :title => @@title}
  end

end
