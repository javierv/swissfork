require "swissfork/possible_pairs"

module Swissfork
  # Class with the common methods needed to calculate the number
  # of pairs fulfiling colour preferences.
  #
  # This class shouldn't be used directly. Use ColourPossiblePairs
  # or StrongColourPossiblePairs instead.
  class GenericColourPossiblePairs < PossiblePairs
    def enough_players_to_guarantee_pairing?
      minimum_number_of_compatible_players >= players.count / 2
    end

    def colour_incompatibilities_for(colour)
      reset
      current_colour_incompatibilities(colour)
    end

  private
    def minimum_number_of_compatible_players
      compatibility_list.values.map(&:count).min.to_i
    end

    def incompatibilities_for(player)
      if players_with_incompatible_colour.count > players.count % 2
        current_colour_incompatibilities
      else
        super(player)
      end
    end

    # Checks players who can only play against players with the
    # same colour preference.
    #
    # If no colour is specified, returns the total number of
    # incompatibilities.
    def current_colour_incompatibilities(colour = nil)
      incompatibilities = 0

      until players_with_incompatible_colour_with_preference(colour).empty?
        remove_with_possible_opponent(players_with_incompatible_colour_with_preference(colour).first)
        incompatibilities += 2
      end

      incompatibilities
    end

    def remove_with_possible_opponent(player)
      remove_from_list(
        [player,
         possible_pairs.opponent_with_less_opponents_for(player)]
      )
    end

    def remove_from_list(players)
      super
      possible_pairs.remove_from_list(players)
    end

    def players_with_incompatible_colour
      possible_pairs.compatibility_list.select do |player, opponents|
        !opponents.empty? && compatibility_list[player].empty?
      end.map { |player, opponents| player }
    end

    def players_with_incompatible_colour_with_preference(colour)
      if colour
        players_with_incompatible_colour.select do |player|
          player.colour_preference == colour
        end
      else
        players_with_incompatible_colour
      end
    end

    def possible_pairs
      @possible_pairs ||= PossiblePairs.new(players)
    end

    def reset
      super
      possible_pairs.reset
    end
  end
end
