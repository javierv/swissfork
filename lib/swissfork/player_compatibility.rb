module Swissfork
  # Given two players, checks whether they can play against
  # each other and if they fulfill their colour preferences.
  class PlayerCompatibility
    def initialize(*players)
      @players = players
    end
    attr_reader :players

    def opponent?
      !same_absolute_preference? || topscorers?
    end

    def colour?
      different_preference?
    end

    def strong_colour?
      different_preference? || degrees.include?(:mild)
    end

    def same_absolute_high_difference?
      same_absolute_preference? && high_differences?
    end

    def same_colour_three_times?
      same_absolute_preference? && !high_differences?
    end

    def same_preference?
      preferences.all? && preferences.uniq.one?
    end

    def white_preferences?
      preferences == %i[white white]
    end

    def black_preferences?
      preferences == %i[black black]
    end

    def same_strong_preference?
      strong_preferences? && same_preference?
    end

    def no_preference_against_colour?(colour)
      preferences.to_set == [colour, nil].to_set
    end

    def no_preferences?
      preferences.none?
    end

  private

    def degrees
      players.map(&:preference_degree)
    end

    def different_preference?
      !same_preference?
    end

    def topscorers?
      players.map(&:topscorer?).any?
    end

    def strong_preferences?
      (degrees - %i[absolute strong]).empty?
    end

    def absolute_preferences?
      degrees == %i[absolute absolute]
    end

    def preferences
      players.map(&:colour_preference)
    end

    def same_absolute_preference?
      absolute_preferences? && same_preference?
    end

    def colour_differences
      players.map(&:colour_difference)
    end

    def high_differences?
      colour_differences.all? { |difference| difference.abs > 1 }
    end
  end
end
