require 'test_helper'
require 'question'

class QuestionTest < ActiveSupport::TestCase

  test "Should generate random multi-choice question" do
    question_msg = Question.make_random(Question::QTYPE_MULTI_CHOICE, -1, 0)
    assert_not_nil question_msg
    question = question_msg[Constants::JSON_QST_QUESTION]
    options = question_msg[Constants::JSON_QST_OPTIONS]
    answer_id = question_msg[Constants::JSON_QST_ANSWER_ID]
    answer = options[answer_id]
    assert_equal true, (question.length > 0)
    assert_equal true, (options.length > 1)
    card = Card.where(:front => question, :back => answer).first
    assert_not_nil card
  end

  test "Should generate random direct input question" do
    question_msg = Question.make_random(Question::QTYPE_DIRECT_INPUT, -1, 0)
    question = question_msg[Constants::JSON_QST_QUESTION]
    hidden_chars = question_msg[Constants::JSON_QST_OPTIONS]
    answer = question_msg[Constants::JSON_QST_ANSWER_ID]
    assert_not_nil question_msg
  end

end
