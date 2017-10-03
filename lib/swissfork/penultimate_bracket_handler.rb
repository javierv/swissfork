require "simple_initialize"

module Swissfork
  # Handles the logic to move players in the penultimate bracket.
  #
  # This is a special case described in FIDE Ducth System,
  # sections A.9 and C.4. The basic idea is: when the pairing
  # of the remaining players isn't possible, we need to use
  # players from the last paired bracket.
  class PenultimateBracketHandler
    initialize_with :penultimate_scoregroup, :last_scoregroup

    def move_players_to_allow_last_bracket_pairs
      while(true)
        begin
          players_to_move = permutations.next.last(leftovers.count)
        rescue StopIteration
          return nil
        end

        duplicate_scoregroup = last_scoregroup.dup
        duplicate_scoregroup.add_players(players_to_move)

        break if duplicate_scoregroup.leftovers.count <= 1
      end

      last_scoregroup.add_players(players_to_move)
      penultimate_scoregroup.remove_players(players_to_move)
    end

  private
    def permutations
      @permutations ||= compatible_players.permutation
    end

    def compatible_players
      penultimate_scoregroup.players.select do |player|
        leftovers.any? { |leftover| player.compatible_with?(leftover) }
      end
    end

    def leftovers
      last_scoregroup.dup.leftovers
    end
  end
end
