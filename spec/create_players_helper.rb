require "spec_helper"
require "swissfork/player_without_colours"

def create_players(numbers)
  numbers.map { |number| Swissfork::PlayerWithoutColours.new(number) }
end
