require "swissfork/downfloat_permit"

module Swissfork
  # Handles which moved down players can downfloat.
  class MovedDownPermit
    initialize_with :players, :number_of_downfloats, :initial_candidates

    def allowed
      groups.each do |player_group|
        break if found_downfloats >= number_of_downfloats

        downfloats_in_this_group = number_of_downfloats_in(player_group)

        candidates.reject! do |downfloats|
          (downfloats & player_group).size < downfloats_in_this_group
        end

        @found_downfloats += downfloats_in_this_group
      end

      candidates.to_set
    end

  private

    def number_of_downfloats_in(player_group)
      candidates.map { |downfloats| (downfloats & player_group).size }.max
    end

    def groups
      players.reverse.group_by(&:points).values
    end

    def found_downfloats
      @found_downfloats ||= 0
    end

    def candidates
      @candidates ||= initial_candidates.select do |downfloats|
        (downfloats & players).size == number_of_downfloats
      end
    end
  end
end
