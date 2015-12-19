require 'protocol'

class Question

  QTYPE_MULTI_CHOICE = 1
  QTYPE_DIRECT_INPUT = 2

  def self.make_random(qtype, set_id)
    if qtype == QTYPE_MULTI_CHOICE
      return make_multichoice_question(set_id)
    elsif qtype == QTYPE_DIRECT_INPUT
      question = make_directinput_question(set_id)
      return question if question != nil
      return make_random(QTYPE_MULTI_CHOICE)
    end
  end

  def self.make_multichoice_question(set_id)
    cards = Card.order("RANDOM()").first(4)
    if set_id != -1
      cards = Card.where(:set_id => set_id).order("RANDOM()").first(4)
    end
    answer_id = rand(4)
    options = cards.map {|option| option.back}
    question = Protocol.make_question(cards[answer_id].front, options, answer_id)
    return question
  end

  def self.make_directinput_question(set_id)
    cards = Card.order("RANDOM()").first(20)
    if set_id != -1
      cards = Card.where(:set_id => set_id).order("RANDOM()").first(20)
    end
    card = nil
    cards.each do |item|
      if (item.back.length >= 3)
        card = item
        break
      end
    end
    
    return nil if card == nil

    # Hash several characters
    answer = card.back
    hidden_chars_cnt = answer.length / 2
    hidden_chars_pos = (1..answer.length).to_a.shuffle.first(hidden_chars_cnt)

    question = Protocol.make_question(card.front, hidden_chars_pos, answer)
       
  end

end
