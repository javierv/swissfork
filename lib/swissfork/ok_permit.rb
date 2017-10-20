require "swissfork/downfloat_permit"

module Swissfork
  # This permit allows every possible downfloat combination.
  class OkPermit < DownfloatPermit

  private
    def can_downfloat?(downfloats)
      true
    end
  end
end
