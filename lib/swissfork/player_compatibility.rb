module Swissfork
  # Given two players, checks whether they can play against
  # each other and if they fulfill their colour preferences.
  class PlayerCompatibility
    def initialize(*players)
      @players = players
    end
    attr_reader :players

    def opponent?
      !absolute_preferences? || different_preference? || topscorers?
    end

    def colour?
      different_preference?
    end

    def strong_colour?
      different_preference? || degrees.include?(:mild)
    end

  private
    def degrees
      players.map(&:preference_degree)
    end

    def different_preference?
      !same_preference?
    end

    def same_preference?
      preferences.all? && preferences.uniq.one?
    end

    def topscorers?
      players.map(&:topscorer?).any?
    end

    def absolute_preferences?
      degrees == [:absolute, :absolute]
    end

    def preferences
      players.map(&:colour_preference)
    end
  end
end
