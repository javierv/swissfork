module Swissfork
  class Player
    include Comparable

    attr_reader :opponents
    attr_reader :number

    def initialize(number)
      @number = number
    end

    def opponents
      @opponents ||= []
    end

    def <=>(other_player)
      number <=> other_player.number
    end
  end
end
