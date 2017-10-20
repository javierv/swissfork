require "swissfork/downfloat_permit"

module Swissfork
  # This permit allows players who haven't had a
  # bye to downfloat.
  class ByePermit < DownfloatPermit
    initialize_with :players

    def number_of_downfloats
      players.count % 2
    end

  private
    def can_downfloat?(downfloats)
      !downfloats.first.had_bye?
    end
  end
end

