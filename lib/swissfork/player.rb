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
      [:down, :bye].include?(floats.last)
    end

    def ascended_in_the_previous_round?
      floats.last == :up
    end

    def colour_preference
      nil # TODO
    end

    def descended_two_rounds_ago?
      [:down, :bye].include?(floats[-2])
    end

    def ascended_two_rounds_ago?
      floats[-2] == :up
    end

    def inspect
      number.to_s
    end

    def <=>(other_player)
      # Comparing the arrays results in better performance.
      [other_player.points, number] <=> [points, other_player.number]
    end

    def compatible_players_in(players)
      # TODO: We might need to change this defintion when we add absolute
      # color preferences. Or, if we're lucky, we might not.
      players - (opponents + [self])
    end

    # FIXME: Currently a stub for tests.
    def points
      0
    end

    def had_bye?
      # TODO.
    end
  end
end
