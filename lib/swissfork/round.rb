require "simple_initialize"
require "swissfork/bracket"

module Swissfork
  # Generates the pairs of a whole round.
  #
  # Its only useful public method is #pairs. All the other
  # public methods are public so they can be easily tested.
  class Round
    require "swissfork/round_bracket"

    initialize_with :players

    def brackets
      @brackets ||= basic_brackets.map do |bracket|
        RoundBracket.new(bracket, basic_brackets)
      end
    end

    def pairs
      while(!pairings_completed?)
        brackets.each.with_index do |bracket, index|
          if bracket.pairs
            if impossible_pairs.include?(established_pairs + bracket.pairs)
              bracket.mark_established_pairs_as_impossible
              redo
            else
              established_pairs.push(*bracket.pairs)
              bracket.move_leftovers_to_next_bracket unless bracket.last?
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
      @basic_brackets = nil
    end

    def scoregroups
      players.group_by(&:points).values
    end

    def basic_brackets
      @basic_brackets ||= scoregroups.map { |players| Bracket.new(players) }.sort
    end
  end
end
