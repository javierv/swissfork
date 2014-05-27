require "simple_initialize"
require "swissfork/exchanged_bracket"

module Swissfork
  class Round
    initialize_with :players

    def brackets
      @brackets ||= players.group_by(&:points).values.map { |players| Bracket.new(players) }.sort
    end

    def pairs
      pairs = []
      pairing_complete = false

      while(!pairing_complete)
        brackets.each.with_index do |bracket, index|
          if bracket.pairs
            if impossible_pairs.include?(pairs + bracket.pairs)
              bracket.mark_established_pairs_as_impossible
              break
            else
              pairs = pairs + bracket.pairs

              if bracket == brackets.last
                pairing_complete = true
              else
                bracket.move_unpaired_players_to(brackets[index + 1])
              end
            end
          else
            mark_pairs_as_impossible(pairs)
            reset_pairs
            pairs = []
            break
          end
        end
      end

      pairs
    end

    # Helper method which makes tests more readable.
    def pair_numbers
      pairs.map(&:numbers)
    end

  private
    def mark_pairs_as_impossible(pairs)
      impossible_pairs << pairs
    end

    def impossible_pairs
      @impossible_pairs ||= []
    end

    def reset_pairs
      @brackets = nil
    end
  end
end
