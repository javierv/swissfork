require "simple_initialize"
require "swissfork/bracket"

module Swissfork
  # Generates the pairs of a whole round.
  #
  # Its only useful public method is #pairs. All the other
  # public methods are public so they can be easily tested.
  class Round
    require "swissfork/scoregroup"

    initialize_with :players

    def scoregroups
      @scoregroups ||= player_groups.map { |players| Scoregroup.new(players, self) }.sort
    end

    def pairs
      while(!pairings_completed?)
        scoregroups.each.with_index do |scoregroup, index|
          if scoregroup.pairs
            if impossible_pairs.include?(established_pairs + scoregroup.pairs)
              scoregroup.mark_established_downfloats_as_impossible
              redo
            else
              established_pairs.push(*scoregroup.pairs)
              scoregroup.move_leftovers_to_next_scoregroup unless scoregroup.last?
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
      @scoregroups = nil
    end

    def player_groups
      players.group_by(&:points).values
    end
  end
end
