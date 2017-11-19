require "simple_initialize"
require "swissfork/colour_incompatibilities"

module Swissfork
  # Given a list of players, it calculates how many pairs
  # can be generated between players with no preference
  # and players between players with no preference and players
  # with each colour
  class NoPreferenceIncompatibilities < ColourIncompatibilities
    initialize_with :players

    # Number of players with players having no colour preference
    # against players with a specific colour preference
    def violations_for(colour)
      case main_preference
      when nil then violations_with_no_main_preference_for(colour)
      when colour then violations_for_main_preference
      else violations_for_minoritary_preference
      end
    end

  private
    def number_of_no_preference_players
      players.reject(&:colour_preference).count
    end

    def violations_for_main_preference
      [
        0,
        [number_of_no_preference_players,
         number_of_compatible_players_for_main_preference].min
      ].max
    end

    def violations_for_minoritary_preference
      [
        0,
        [number_of_no_preference_players,
         number_of_compatible_players_for_minoritary_preference].min
      ].max
    end

    def violations_with_no_main_preference_for(colour)
      [number_of_compatible_players_with_preference(colour),
       (number_of_no_preference_players / 2.0).ceil].min
    end

    def number_of_compatible_players_for_main_preference
      ((number_of_no_preference_players + colour_difference.abs) / 2.0).ceil
    end

    def number_of_compatible_players_for_minoritary_preference
      ((number_of_no_preference_players - colour_difference.abs) / 2.0).ceil
    end
  end
end
