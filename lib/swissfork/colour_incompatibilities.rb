require "simple_initialize"
require "swissfork/colour_possible_pairs"
require "swissfork/strong_colour_possible_pairs"

module Swissfork
  # Given a list of players, it calculates how many pairs
  # fulfilling colour preferences can be generated.
  class ColourIncompatibilities
    initialize_with :players, :number_of_possible_pairs

    def violations
      @violations ||=
        [number_of_possible_pairs - ColourPossiblePairs.new(players).count, 0].max
    end

    def strong_violations
      @strong_violations ||=
        [number_of_possible_pairs - StrongColourPossiblePairs.new(players).count, 0].max
    end

    def main_preference
      @main_preference ||=
        if colour_difference > 0
          :white
        elsif colour_difference < 0
          :black
        end
    end

    # Number of pairs with players having the same colour preference
    # for a specific colour
    def violations_for(colour)
      if minoritary_preference
        if colour == minoritary_preference
          minoritary_violations
        else
          violations - minoritary_violations
        end
      else
        violations / 2
      end
    end

  private
    def minoritary_violations
      ColourPossiblePairs.new(players).colour_incompatibilities_for(minoritary_preference) / 2
    end

    def minoritary_preference
      case main_preference
      when :black then :white
      when :white then :black
      end
    end

    def colour_difference
      if compatible_players_difference.zero?
        players_with_preference(:white).count - players_with_preference(:black).count
      else
        compatible_players_difference
      end
    end

    def compatible_players_difference
      @compatible_players_difference ||=
        number_of_compatible_players_with_preference(:white) -
        number_of_compatible_players_with_preference(:black)
    end

    def players_with_main_mild_preference
      players_with_preference(main_preference).select do |player|
        player.preference_degree == :mild
      end
    end

    def players_with_preference(colour)
      players.select { |player| player.colour_preference == colour }
    end

    def number_of_compatible_players_with_preference(colour)
      players_with_preference(colour).count -
        ColourPossiblePairs.new(players).colour_incompatibilities_for(colour)
    end
  end
end
