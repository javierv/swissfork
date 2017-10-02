require "simple_initialize"

module Swissfork
  # Contains data related to a player: name, elo.
  #
  # It also contains information about the games a player has
  # played, its opponents, and results.
  #
  # Currently it's basically a stub with the minimum necessary
  # to generate pairs.
  class Player
    include Comparable

    initialize_with :number
    attr_reader :opponents, :floats

    def opponents
      @opponents ||= []
    end

    def floats
      @floats ||= []
    end

    def descended_in_the_previous_round?
      floats.last == :down
    end

    def ascended_in_the_previous_round?
      floats.last == :up
    end

    def descended_two_rounds_ago?
      floats[-2] == :down
    end

    def ascended_two_rounds_ago?
      floats[-2] == :up
    end

    def inspect
      number.to_s
    end

    def <=>(other_player)
      if points == other_player.points
        number <=> other_player.number
      else
        other_player.points <=> points
      end
    end

    def compatible_with?(player)
      player != self && !opponents.include?(player)
    end

    def compatible_players_in(players)
      players.select { |player| compatible_with?(player) }
    end

    # FIXME: Currently a stub for tests.
    def points
      0
    end
  end
end
