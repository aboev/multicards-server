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
end
