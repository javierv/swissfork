require "simple_initialize"

module Swissfork
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
      !opponents.include?(player)
    end

    # FIXME: Currently a stub for tests.
    def points
      0
    end
  end
end
