require "spec_helper"
require "swissfork/round"
require "swissfork/player"

module Swissfork
  describe Round do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    let(:round) { Round.new(players) }

    describe "#bye" do
      context "even number of players" do
        let(:players) { create_players(1..10) }

        it "returns nil" do
          round.bye.should == nil
        end
      end

      context "odd number of players" do
        let(:players) { create_players(1..11) }

        it "returns the unpaired player" do
          round.bye.number.should == 11
        end
      end
    end
  end
end
