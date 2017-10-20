module Swissfork
  # Handles logic related to which players can downfloat to the
  # next bracket.
  #
  # This class handles the main logic, but doesn't define the
  # condition which makes a downfloat valid or not. Subclasses
  # must be used instead.
  #
  # Subclasses must implement the method can_downfloat?, which
  # receives a group of players and returns true if they can
  # downfloat.
  class DownfloatPermit
    initialize_with :players, :number_of_downfloats

    def allowed
      @allowed ||= combinations.select do |downfloats|
        can_downfloat?(downfloats)
      end.map { |downfloats| downfloats.to_set }.to_set
    end

  private
    def combinations
      return [] if number_of_downfloats.zero?

      @combinations ||= players.combination(number_of_downfloats)
    end

    def can_downfloat?(downfloats)
      raise "Implement in subclass"
    end
  end
end
