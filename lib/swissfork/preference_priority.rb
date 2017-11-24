require "simple_initialize"

module Swissfork
  # Compares players to find out whose preference is stronger,
  # following criterias E.1 to E.4.
  class PreferencePriority
    include Comparable
    initialize_with :player

    def <=>(preference)
      if strength == preference.strength
        return 0 unless colour

        if last_different_colour_preference(preference)
          last_different_colour_preference(preference)
        else
          player <=> preference.player
        end
      else
        strength <=> preference.strength
      end
    end

  protected
    def strength
      [colour_index, degree, -1 * difference.abs]
    end

    def colours
      player.colours.compact
    end

  private
    def difference
      player.colour_difference
    end

    def colour_index
      [:white, :black, nil].index(colour)
    end

    def colour
      player.colour_preference
    end

    def degree
      [:absolute, :strong, :mild, nil].index(player.preference_degree)
    end

    def last_different_colour_preference(preference)
      last_order = colours.zip(preference.colours).select do |colours|
        colours.compact.uniq.size > 1
      end.last

      if last_order
        if last_order[0] == colour
          1
        else
          -1
        end
      end
    end
  end
end
