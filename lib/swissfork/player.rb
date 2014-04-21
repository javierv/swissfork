module Swissfork
  class Player
    attr_reader :opponents
    attr_reader :number

    def initialize(number)
      @number = number
    end

    def opponents
      @opponents ||= []
    end
  end
end
