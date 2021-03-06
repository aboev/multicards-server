require 'protocol'
require 'constants'

class Question

  QTYPE_MULTI_CHOICE = 1
  QTYPE_DIRECT_INPUT = 2

  QSTATUS_NO_ANSWER = 0
  QSTATUS_WRONG_ANSWER = 1
  QSTATUS_RIGHT_ANSWER = 2

  def self.make_random(qtype, set_id, question_id)
    cardset = Qcardset.where(:cardset_id => set_id).first
    invert = false
    invert = true if ((cardset != nil) and (cardset.tags.include?(Constants::DB_FLAG_INVERT)))

    if qtype == QTYPE_MULTI_CHOICE
      return make_multichoice_qquestion(set_id, question_id, invert)
    elsif qtype == QTYPE_DIRECT_INPUT
      question = make_directinput_qquestion(set_id, question_id, invert)
      return question if question != nil
      return make_random(QTYPE_MULTI_CHOICE)
    end
  end

  def self.make_multichoice_qquestion(set_id, question_id, invert)
    return if set_id == -1
    question = nil
    if (!invert)
      cards = Qcard.where(:cardset_id => set_id).order("RANDOM()").first(4)
      answer_id = rand(4)
      options = cards.map {|option| option.definition}
      question = Protocol.make_question(cards[answer_id].term, options, answer_id, question_id)
    else
      cards = Qcard.where(:cardset_id => set_id).order("RANDOM()").first(4)
      answer_id = rand(4)
      options = cards.map {|option| option.term}
      question = Protocol.make_question(cards[answer_id].definition, options, answer_id, question_id)
    end
    return question
  end

  def self.make_directinput_qquestion(set_id, question_id, invert)
    return if set_id == -1
    cards = Qcard.where(:cardset_id => set_id).order("RANDOM()").first(20)
    card = nil
    cards.each do |item|
      if (item.definition.length >= 3)
        card = item
        break
      end
    end

    return nil if card == nil

    # Hash several characters
    answer = card.definition
    hidden_chars_cnt = answer.length / 2
    hidden_chars_pos = (1..answer.length).to_a.shuffle.first(hidden_chars_cnt)

    question = Protocol.make_question(card.term, hidden_chars_pos, answer, question_id)
  end

  def self.make_multichoice_question(set_id, question_id)
    cards = Card.order("RANDOM()").first(4)
    if set_id != -1
      cards = Card.where(:set_id => set_id).order("RANDOM()").first(4)
    end
    answer_id = rand(4)
    options = cards.map {|option| option.back}
    question = Protocol.make_question(cards[answer_id].front, options, answer_id, question_id)
    return question
  end

  def self.make_directinput_question(set_id, question_id)
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

    question = Protocol.make_question(card.front, hidden_chars_pos, answer, question_id)
       
  end

end
