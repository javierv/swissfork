require "simple_initialize"

module Swissfork
  # Given a list of players, it calculates how many pairs
  # fulfilling colour preferences can be generated.
  class ColourIncompatibilities
    initialize_with :players, :number_of_possible_pairs

    def violations
      [number_of_possible_pairs - players_with_preference(minoritary_preference).count - players_with_no_preference.count, 0].max
    end

    def strong_violations
      [violations - players_with_main_mild_preference.count, 0].max
    end

    def main_preference
      @main_preference ||=
        if colour_difference > 0
          :white
        elsif colour_difference < 0
          :black
        else
          :white # TODO: make it nil.
        end
    end

    def minoritary_preference
      case main_preference
      when :black then :white
      when :white then :black
      end
    end

  private
    def colour_difference
      players_with_preference(:white).count - players_with_preference(:black).count
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
  end
end
