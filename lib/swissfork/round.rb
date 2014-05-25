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
        bracket.move_unpaired_players_to(brackets[index + 1]) unless bracket == brackets.last
      end

      pairs
    end

    # Helper method which makes tests more readable.
    def pair_numbers
      pairs.map(&:numbers)
    end
  end
end
