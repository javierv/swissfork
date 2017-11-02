require "swissfork/possible_pairs"

module Swissfork
  class ColourPossiblePairs < PossiblePairs
    def enough_players_to_guarantee_pairing?
      minimum_number_of_compatible_players >= players.count / 2
    end

  private
    def minimum_number_of_compatible_players
      compatibility_list.values.map(&:count).min.to_i
    end

    def opponents_for(player)
      super(player).select do |opponent|
        !player.colour_preference || !opponent.colour_preference ||
          player.colour_preference != opponent.colour_preference
      end
    end

    def incompatibilities_for(player)
      if players_with_incompatible_colour.count > players.count % 2
        colour_incompatibilities
      else
        super(player)
      end
    end

    # Checks players who can only play against players with the
    # same colour preference.
    def colour_incompatibilities
      incompatibilities = 0

      until players_with_incompatible_colour.empty?
        remove_with_possible_opponent(players_with_incompatible_colour.first)
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

    def possible_pairs
      @possible_pairs ||= PossiblePairs.new(players)
    end

    def reset
      super
      possible_pairs.reset
    end
  end
end
