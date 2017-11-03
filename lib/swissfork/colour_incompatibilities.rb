require "simple_initialize"
require "swissfork/colour_possible_pairs"

module Swissfork
  # Given a list of players, it calculates how many pairs
  # fulfilling colour preferences can be generated.
  class ColourIncompatibilities
    initialize_with :players, :number_of_possible_pairs

    def violations
      return 0 unless main_preference

      [number_of_possible_pairs - players_with_preference(minoritary_preference).count - players_with_no_preference.count, 0].max
    end

    def strong_violations
      return 0 unless main_preference

      [violations - players_with_main_mild_preference.count, 0].max
    end

    def main_preference
      @main_preference ||=
        if colour_difference > 0
          :white
        elsif colour_difference < 0
          :black
        end
    end

    def violations_for(colour, total_violations)
      if minoritary_preference
        if colour == minoritary_preference
          minoritary_violations
        else
          total_violations - minoritary_violations
        end
      else
        total_violations / 2
      end
    end

    def minoritary_violations
      ColourPossiblePairs.new(players).colour_incompatibilities_for(minoritary_preference) / 2
    end

    def minoritary_preference
      case main_preference
      when :black then :white
      when :white then :black
      end
    end

  private
    def colour_difference
      [number_of_compatible_players_with_preference(:white),
       players_with_preference(:white).count] <=>
      [number_of_compatible_players_with_preference(:black),
       players_with_preference(:black).count]
    end

    def players_with_main_mild_preference
      players_with_preference(main_preference).select do |player|
        player.preference_degree == :mild
      end
    end

    def players_with_no_preference
      players.reject(&:colour_preference)
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
