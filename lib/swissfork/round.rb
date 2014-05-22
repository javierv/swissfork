require "swissfork/bracket"
require "simple_initialize"

module Swissfork
  class Round
    initialize_with :players

    def brackets
      @brackets ||= players.group_by(&:points).values.map { |players| Bracket.new(players) }.sort
    end

    def pairs
      pairs = []
      brackets.each.with_index do |bracket, index|
        pairs = pairs + bracket.pairs

        break if index == brackets.count - 1

        if bracket.unpaired_players.any?
          bracket.unpaired_players.each do |player|
            brackets[index + 1].add_player(player)
          end
        end
      end

      pairs
    end

    # Helper method which makes tests more readable.
    def pair_numbers
      pairs.map(&:numbers)
    end
  end
end
