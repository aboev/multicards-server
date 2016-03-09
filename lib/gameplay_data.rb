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
    inverted = true if (cardset.flags.include?(Constants::FLAG_INVERTED.to_s))
    cards = Qcard.where(:cardset_id => @set_id).first(Constants::GAMEPLAY_Q_PER_G)
    return if (cards.size < Constants::GAMEPLAY_O_PER_Q)

    terms = []
    definitions = []
    cards.each do |card|
      term = card.term
      definition = cardset.has_images ? card.get_metacard : card.definition
      if inverted
        terms << definition
        definitions << term
      else
        terms << term
        definitions << definition
      end
    end

    udefinitions, termDefMap = filter_unique(terms, definitions)

    @questions = []
    question_count = [terms.size, Constants::GAMEPLAY_Q_PER_G].min
    option_count = [Constants::GAMEPLAY_O_PER_Q, udefinitions.size].min
    term_ids = random_nums(question_count, question_count, -1)
    i = 0
    term_ids.each do |term_id|
      question_data = {}
      
      question = terms[term_id]
      options = []

      except = termDefMap[term_id]
      option_ids = random_nums(option_count - 1, udefinitions.size, except)
      answer_id = rand(option_count)
      j = 0

      option_ids.each do |option_id|
        options << udefinitions[termDefMap[term_id]] if (j == answer_id)
        options << udefinitions[option_id]
        j = j + 1
      end
      options << udefinitions[termDefMap[term_id]] if (answer_id == option_count - 1)

      question_data[Constants::JSON_QST_QUESTION] = question
      question_data[Constants::JSON_QST_OPTIONS] = options
      question_data[Constants::JSON_QST_ANSWER_ID] = answer_id
      question_data[Constants::JSON_QST_ID] = i

      @questions << question_data
      i = i + 1
    end
  end

  def filter_unique(terms, definitions)
    set = {}
    map = {}
    udefinitions = []
    termDefinitionMap = []
    for i in 0...terms.length
      term = terms[i]
      definition = definitions[i]

      if set[definition] == nil
        udefinitions << definition
        map[definition] = udefinitions.length - 1
        set[definition] = 1
      end
      termDefinitionMap[i] = map[definition]
    end
    return udefinitions, termDefinitionMap 
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
