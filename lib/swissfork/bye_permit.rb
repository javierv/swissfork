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
    def permit_condition(downfloats)
      !downfloats.first.had_bye?
    end
  end
end

