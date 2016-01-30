require 'test_helper'
require 'gameplay_data'
require 'utils'
require 'constants'

class GameplayDataTest < ActiveSupport::TestCase

  def setup
    @sample_setid = 415
    @sample_gid = "quizlet_" + @sample_setid.to_s
  end

  test "Should generate random gameplay data" do
    Utils.import_qcardset(@sample_gid)
    gameplay = GameplayData.new(@sample_setid)
    gameplay.new_gameplay()
    questions = gameplay.to_json[:questions].map { |item| item[Constants::JSON_QST_QUESTION] }
    assert_equal Constants::GAMEPLAY_Q_PER_G, questions.length
    assert_equal questions.size, questions.uniq.size
    assert_equal Constants::GAMEPLAY_O_PER_Q, gameplay.to_json[:questions][0][Constants::JSON_QST_OPTIONS].length
  end

end
