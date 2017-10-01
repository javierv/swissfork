require "simple_initialize"
require "swissfork/bracket"

module Swissfork
  # Generates the pairs of a whole round.
  #
  # Its only useful public method is #pairs. All the other
  # public methods are public so they can be easily tested.
  class Round
    require "swissfork/penultimate_bracket_handler"
    require "swissfork/last_bracket"

    initialize_with :players

    def brackets
      @brackets ||= basic_brackets.tap do |brackets|
        brackets[-1] = LastBracket.new(brackets.last.players)
      end
    end

    def pairs
      while(!pairings_completed?)
        brackets.each.with_index do |bracket, index|
          if bracket.pairs
            if impossible_pairs.include?(established_pairs + bracket.pairs)
              bracket.mark_established_pairs_as_impossible
              redo
            elsif brackets.count > 1 && bracket == brackets[-2]
              pairs = LastBracket.new(bracket.leftovers + brackets.last.players).pairs

              if !pairs || pairs.empty?
                bracket.mark_established_pairs_as_impossible
                if PenultimateBracketHandler.new(bracket.players, brackets.last).move_players_to_allow_last_bracket_pairs
                  redo
                else
                  mark_established_pairs_as_impossible
                  break
                end
              else
                established_pairs.push(*bracket.pairs)
                bracket.move_leftovers_to(brackets[index + 1])
              end
            else
              established_pairs.push(*bracket.pairs)

              if bracket == brackets.last
                mark_established_pairs_as_impossible unless pairings_completed?
              else
                bracket.move_leftovers_to(brackets[index + 1])
              end
            end
          else
            mark_established_pairs_as_impossible
            break
          end
        end
      end

      established_pairs.sort
    end

    # Helper method which makes tests more readable.
    def pair_numbers
      pairs.map(&:numbers)
    end

  private
    def pairings_completed?
      established_pairs.count == (players.count / 2.0).truncate
    end

    def mark_established_pairs_as_impossible
      impossible_pairs << established_pairs
      reset_pairs
    end

    def impossible_pairs
      @impossible_pairs ||= []
    end

    def established_pairs
      @established_pairs ||= []
    end

    def reset_pairs
      @established_pairs = nil
      @brackets = nil
    end

    def scoregroups
      players.group_by(&:points).values
    end

    def basic_brackets
      scoregroups.map { |players| Bracket.new(players) }.sort
    end
  end
end
