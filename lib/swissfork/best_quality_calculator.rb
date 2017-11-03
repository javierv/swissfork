require "simple_initialize"
require "swissfork/possible_pairs"
require "swissfork/colour_possible_pairs"
require "swissfork/colour_incompatibilities"
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

    # Criterion C.10
    def colour_violations
      @colour_violations ||= [possible_pairs - ColourPossiblePairs.new(players).count, 0].max
    end

    # Criterion C.11
    def strong_colour_violations
      colour_incompatibilities.strong_violations
    end

    def incompatible_colours?(player, opponent)
      # TODO: fix when we improve the colour violations calcs.
      colour_violations > 0 &&
          player.colour_preference == colour_incompatibilities.minoritary_preference &&
          opponent.colour_preference != colour_incompatibilities.main_preference
    end

    def allowed_failures
      @allowed_failures ||= {
        colour_preference_violation?: colour_violations,
        strong_colour_preference_violation?: strong_colour_violations,
        same_downfloats_as_previous_round?: same_downfloats_as_previous_round_violations
      }.tap { |failures| failures.default = 0 }
    end

    def failing_criteria
      @failing_criteria ||= []
    end

    def reset_failing_criteria
      @failing_criteria = nil
    end

  private
    # Criterion C.5
    def compatible_pairs
      @compatible_pairs ||= PossiblePairs.new(players).count
    end

    def colour_incompatibilities
      @colour_incompatibilities ||= ColourIncompatibilities.new(players, possible_pairs)
    end

    def resident_players
      players
    end

    # TODO: add tests.
    def same_downfloats_as_previous_round_violations
      [required_downfloats - resident_players.reject(&:descended_in_the_previous_round?).count, 0].max
    end
  end
end
