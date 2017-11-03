require "simple_initialize"
require "swissfork/possible_pairs"
require "swissfork/ok_permit"

module Swissfork
  # Checks what's the best possible quality which can be obtained
  # given some players and the number of players who are going to
  # downfloat.
  class BestQualityCalculator
    initialize_with :players

    def possible_pairs
      [pairs_after_downfloats, compatible_pairs].min
    end

    def required_downfloats
      @required_downfloats ||= players.count - compatible_pairs * 2
    end

    # Sets the required number of downfloats in order to fulfil criterion C.4
    def required_downfloats=(number)
      @required_downfloats = [number, players.count - possible_pairs * 2].max
    end

    def pairs_after_downfloats
      (players.count - required_downfloats) / 2
    end

    def downfloat_permit
      @downfloat_permit ||= OkPermit.new(players, required_downfloats)
    end

    attr_writer :downfloat_permit

    def allowed_downfloats
      downfloat_permit.allowed
    end

  private
    # Criterion C.5
    def compatible_pairs
      @compatible_pairs ||= PossiblePairs.new(players).count
    end
  end
end
