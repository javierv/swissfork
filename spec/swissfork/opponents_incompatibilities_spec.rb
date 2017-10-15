require "spec_helper"
require "swissfork/opponents_incompatibilities"
require "swissfork/player"

module Swissfork
  describe OpponentsIncompatibilities do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    describe "#count" do
      let(:players) { create_players(1..10) }
      let(:incompatibilities) { OpponentsIncompatibilities.new(players, players) }

      context "no incompatibilities" do
        it "returns 0" do
          incompatibilities.count.should == 0
        end
      end

      context "two players have only the same possible opponent" do
        before(:each) do
          players[0..1].each { |player| player.stub_opponents(players[0..8]) }
        end

        it "returns 1" do
          incompatibilities.count.should == 1
        end
      end

      context "two players have the same two possible opponents" do
        before(:each) do
          players[0..1].each { |player| player.stub_opponents(players[0..7]) }
        end

        it "returns 0" do
          incompatibilities.count.should == 0
        end
      end

      context "four players have the same two possible opponents" do
        before(:each) do
          players[0..3].each { |player| player.stub_opponents(players[0..7]) }
        end

        it "returns 2" do
          incompatibilities.count.should == 2
        end
      end
    end
  end
end

