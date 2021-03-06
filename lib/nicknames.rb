require "securerandom"

module Nicknames

  def self.haikunate(token_range = 9999, delimiter = "-")
    seed = random_seed
    build(seed, token_range, delimiter)
  end

  def self.build(seed, token_range, delimiter)
    sections = [
      adjectives[seed % adjectives.length],
      nouns[seed % nouns.length],
      token(token_range)
    ]
    sections.compact.join(delimiter)
  end

  def self.random_seed
    SecureRandom.random_number(4096)
  end

  def self.token(range)
    SecureRandom.random_number(range) if range > 0
  end

  def self.adjectives
    %w(
      autumn hidden bitter misty silent empty dry dark summer
      icy delicate quiet white cool spring winter patient
      twilight dawn crimson wispy weathered blue billowing
      broken cold damp falling frosty green long late lingering
      bold little morning muddy old red rough still small
      sparkling throbbing shy wandering withered wild black
      young holy solitary fragrant aged snowy proud floral
      restless divine polished ancient purple lively nameless
    )
  end

  def self.nouns
    %w(
      waterfall river breeze moon rain wind sea morning
      snow lake sunset pine shadow leaf dawn glitter forest
      hill cloud meadow sun glade bird brook butterfly
      bush dew dust field fire flower firefly feather grass
      haze mountain night pond darkness snowflake silence
      sound sky shape surf thunder violet water wildflower
      wave water resonance sun wood dream cherry tree fog
      frost voice paper frog smoke star
    )
  end

end
