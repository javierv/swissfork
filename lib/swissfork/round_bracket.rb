require "simple_initialize"

module Swissfork
  # Holds information about a bracket and the rest of the
  # brackets we need to pair.
  #
  # Sometimes a bracket needs to know about other brackets;
  # for example, in criterias C.4 (penultimate bracket) and
  # C.7 (maximize pairs in the next bracket).
  class RoundBracket
    require "swissfork/penultimate_bracket_handler"

    initialize_with :bracket, :brackets

    def pairs
      if penultimate?
        if handler.normal_pairing_is_ok?
          bracket.pairs
        else
          handler.move_players_to_allow_last_bracket_pairs && bracket.pairs
        end
      else
        bracket.pairs
      end
    end

    def points
      bracket.points
    end

    def leftovers
      bracket.leftovers
    end

    def players
      bracket.players
    end

    def move_leftovers_to_next_bracket
      next_bracket.add_players(leftovers)
      players.reject! { |player| leftovers.include?(player) }
    end

    def mark_established_pairs_as_impossible
      bracket.mark_established_pairs_as_impossible
    end

    def last?
      bracket == brackets.last
    end

  private
    def next_bracket
      brackets[brackets.index(bracket) + 1]
    end

    def penultimate?
      brackets.count > 1 && bracket == brackets[-2]
    end

    def handler
      PenultimateBracketHandler.new(bracket, next_bracket)
    end
  end
end
