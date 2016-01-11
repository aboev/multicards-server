require 'net/https'

module Utils
  def self.make_gid(provider, set_id)
    gid = provider + "_" + set_id
  end

  def self.parse_gid(gid)
    provider = gid.split("_")[0]    
    set_id = gid.split("_")[1]
    return [provider, set_id]
  end

  def self.get_cardset(gid)
    cardset = Cardset.where(:gid => gid).first
    import_cardset(gid) if (cardset == nil)
    return Cardset.where(:gid => gid).first
  end

  def self.import_qcardset(gid)
    set_id = parse_gid(gid)[1]
    provider = parse_gid(gid)[0]
    if provider == "quizlet"
      url = URI.parse('https://api.quizlet.com/2.0/sets/'+set_id+'?client_id='+APP_CONFIG['quizlet_client_id'])
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https') {|http| http.request(req)}
      if res.kind_of? Net::HTTPSuccess
        cardset_json = JSON.parse(res.body)
        terms = cardset_json['terms']
        puts cardset_json['url']
        cardset_json.delete('terms')
        cardset = Qcardset.new
        cardset.cardset_id = cardset_json['id']
        cardset.url = cardset_json['url']
        cardset.title = cardset_json['title']
        cardset.created_date = cardset_json['created_date']
        cardset.modified_date = cardset_json['modified_date']
        cardset.published_date = cardset_json['published_date']
        cardset.has_images = cardset_json['has_images']
        cardset.lang_terms = cardset_json['lang_terms']
        cardset.lang_definitions = cardset_json['lang_definitions']
        cardset.creator_id = cardset_json['creator_id']
        cardset.description = cardset_json['description']
        cardset.term_count = cardset_json['term_count']
        cardset.like_count = 0
        cardset.total_diff = 0
        cardset.diff_count = 0
        cardset.save

        terms.each do |term|
          card = Qcard.new
          card.cardset_id = cardset.cardset_id
          card.term_id = term['term_id']
          card.term = term['term']
          card.definition = term['definition']
          card.image = term['image']
          card.rank = term['rank']
          card.save
        end
        return true
      end
    end
    return false
  end

  def self.import_cardset(gid)
    set_id = parse_gid(gid)[1]
    provider = parse_gid(gid)[0]
    if provider == "quizlet"
      url = URI.parse('https://api.quizlet.com/2.0/sets/'+set_id+'?client_id='+APP_CONFIG['quizlet_client_id'])
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https') {|http| http.request(req)}
      if res.kind_of? Net::HTTPSuccess
        cardset_json = JSON.parse(res.body)
        terms = cardset_json['terms']
        puts cardset_json['url']
        cardset_json.delete('terms')
        cardset = Cardset.new
        cardset.gid = Utils.make_gid("quizlet", cardset_json['id'].to_s)
        cardset.details = cardset_json.to_json
        cardset.save
        terms.each do |term|
          puts cardset.id
          card = Card.new
          card.front = term["term"]
          card.back = term["definition"]
          card.set_id = cardset.id
          card.save
          puts card.to_json
        end
        return true
      else
        puts res.body
        return false
      end
    else
      return false
    end
  end

  def self.like(gid, userid)
    set_id = parse_gid(gid)[1]
    provider = parse_gid(gid)[0]
    if provider == "quizlet"
      if ((Qcardset.where(:cardset_id => set_id).count > 0) or (import_qcardset(gid) == true))
        cardset = Qcardset.where(:cardset_id => set_id).first
        if (!cardset.likes.include?(userid.to_s))
          cardset.add_like(userid.to_s)
          cardset.save
          return true
        end
      end
    end    
    return false
  end

  def self.unlike(gid, userid)
    set_id = parse_gid(gid)[1]
    provider = parse_gid(gid)[0]
    if provider == "quizlet"
      cardset = Qcardset.where(:cardset_id => set_id)
      if ((cardset.count > 0) and (cardset.first.likes.include?(userid.to_s)))
        cardset.remove_like(userid.to_s)
        cardset.save
        return true
      end
    end
    return false
  end

  def self.make_nickname
  end

end
