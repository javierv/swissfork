require "simple_initialize"

module Swissfork
  class Player
    include Comparable

    initialize_with :number
    attr_reader :opponents

    def opponents
      @opponents ||= []
    end

    def <=>(other_player)
      number <=> other_player.number
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
