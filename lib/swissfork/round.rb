require "swissfork/bracket"

module Swissfork
  class Round
    attr_reader :players

    def initialize(players)
      @players = players
    end

    def brackets
      players.group_by(&:points).values.map { |players| Bracket.new(players) }.sort
    end
  end
end
