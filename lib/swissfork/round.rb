require "swissfork/bracket"
require "simple_initialize"

module Swissfork
  class Round
    initialize_with :players

    def brackets
      players.group_by(&:points).values.map { |players| Bracket.new(players) }.sort
    end

    def pairs
      brackets.map(&:pairs).flatten
    end
  end
end
