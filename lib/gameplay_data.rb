require 'question'
require 'constants'
require 'game'

class GameplayData

  @current_question = 0
  @question_count = 0
  @questions = []
  @set_id
  @answers = {}

  def random_nums(count, range, except)
    ((0...range).to_a - [except]).shuffle.first(count)
  end

  def new_gameplay()
    cardset = Qcardset.where(:cardset_id => @set_id).first
    return if cardset == nil
    inverted = false
    inverted = true if (cardset.tags.include?(Constants::FLAG_INVERTED.to_s))
    cards = Qcard.where(:cardset_id => @set_id).first(Constants::GAMEPLAY_Q_PER_G)
    return if (cards.size < Constants::GAMEPLAY_O_PER_Q)

    terms = []
    definitions = []
    cards.each do |card|
      if inverted
        terms << card.definition
        definitions << card.term
      else
        terms << card.term
        definitions << card.definition
      end
    end

    @questions = []
    question_count = [terms.size, Constants::GAMEPLAY_Q_PER_G].min
    term_ids = random_nums(question_count, question_count, -1)
    term_ids.each do |term_id|
      question_data = {}
      
      question = terms[term_id]
      options = []

      option_ids = random_nums(Constants::GAMEPLAY_O_PER_Q - 1, terms.size, term_id)
      answer_id = rand(Constants::GAMEPLAY_O_PER_Q)
      i = 0
      option_ids.each do |option_id|
        options << definitions[term_id] if (i == answer_id)
        options << definitions[option_id]
        i = i + 1
      end
      options << definitions[term_id] if (answer_id == Constants::GAMEPLAY_O_PER_Q - 1)

      question_data[Constants::JSON_QST_QUESTION] = question
      question_data[Constants::JSON_QST_OPTIONS] = options
      question_data[Constants::JSON_QST_ANSWER_ID] = answer_id

      @questions << question_data
    end
  end

  def initialize(set_id)
    @set_id = set_id
    new_gameplay()
  end

  def to_json
    {:questions => @questions, :answers => @answers}
  end

  def is_empty
    @question_count == 0
  end

end
