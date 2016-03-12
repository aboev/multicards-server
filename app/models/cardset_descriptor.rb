require 'utils'

class CardsetDescriptor
  @@cardset_id = 0
  @@gid = ""
  @@title = ""
  @@url = ""
  @@created_by = ""
  @@lang_terms = ""
  @@lang_definitions = ""
  @@has_images = false
  @@creator_id = 0
  @@description = ""
  @@term_count = 0
  @@like_count = 0
  @@flags = []
  @@terms = []

  def self.set_terms
    setid = Utils.parse_gid(@@gid)[1]
    provider = Utils.parse_gid(@@gid)[0]
    if provider == "quizlet"
      terms = Qcard.where(:cardset_id => setid)
      @@terms = terms
    end
  end

  def self.from_json(cardset_json, include_terms)
    @@cardset_id = cardset_json['id']
    @@url = cardset_json['url']
    @@title = cardset_json['title']
    @@has_images = cardset_json['has_images']
    @@lang_terms = cardset_json['lang_terms']
    @@lang_definitions = cardset_json['lang_definitions']
    @@creator_id = cardset_json['creator_id']
    @@description = cardset_json['description']
    @@term_count = cardset_json['term_count']
    @@like_count = 0
    @@terms = cardset_json['terms'] if include_terms == true
    return self
  end

  def self.from_qcardset(qcardset)
    @@cardset_id = qcardset.cardset_id
    @@title = qcardset.title
    @@gid = "quizlet_" + qcardset.cardset_id.to_s
    @@lang_terms = qcardset.lang_terms
    @@lang_definitions = qcardset.lang_definitions
    @@like_count = qcardset.like_count
    @@flags = qcardset.flags
    set_terms
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
    {:cardset_id => @@cardset_id, :gid => @@gid, :title => @@title, :lang_terms => @@lang_terms, :lang_definitions => @@lang_definitions, :like_count => @@like_count, :flags => @@flags, :terms => @@terms, :has_images => @@has_images}
  end

end
