require "simple_initialize"
require "swissfork/bracket"

module Swissfork
  class Round
    initialize_with :players

    def brackets
      @brackets ||= players.group_by(&:points).values.map { |players| Bracket.new(players) }.sort
    end

    def pairs
      while(!pairings_completed?)
        brackets.each.with_index do |bracket, index|
          if bracket.pairs
            if impossible_pairs.include?(established_pairs + bracket.pairs)
              bracket.mark_established_pairs_as_impossible
              break
            else
              established_pairs.push(*bracket.pairs)

              unless bracket == brackets.last
                bracket.move_unpaired_players_to(brackets[index + 1])
              end
            end
          else
            mark_established_pairs_as_impossible
            reset_pairs
            break
          end
        end
      end

      established_pairs
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
    end

    def impossible_pairs
      @impossible_pairs ||= []
    end

    def established_pairs
      @established_pairs ||= []
    end

    def reset_pairs
      @established_pairs = []
      @brackets = nil
    end
  end
end
