require "create_players_helper"
require "swissfork/moved_down_possible_pairs"

module Swissfork
  describe PossiblePairs do
    let(:pairs) { MovedDownPossiblePairs.new(players, opponents) }

    describe "#count" do
      let(:players) { create_players(1..3) }
      let(:opponents) { create_players(11..17) }

      context "no incompatibilities" do
        it "returns the number of moved down players" do
          pairs.count.should eq 3
        end
      end

      context "two players can only play against one opponent" do
        before(:each) do
          players[0..1].each_stub_opponents(opponents[0..5])
          opponents[0..5].each_stub_opponents(players[0..1])
        end

        it "returns the number of moved down players minus one" do
          pairs.count.should eq 2
        end
      end
    end

    describe "#enough_players_to_guarantee_pairing" do
      let(:players) { create_players(1..3) }
      let(:opponents) { create_players(4..10) }

      context "no incompatibilities" do
        it "returns true" do
          pairs.enough_players_to_guarantee_pairing?.should be true
        end
      end

      context "one player can play against as many players as moved down players" do
        before(:each) do
          players[0].stub_opponents(opponents[0..3])
          opponents[0..3].each_stub_opponents([players[0]])
        end

        it "returns true" do
          pairs.enough_players_to_guarantee_pairing?.should be true
        end
      end

      context "one player can play against less than the number of moved down players " do
        before(:each) do
          players[0].stub_opponents(opponents[0..4])
          opponents[0..4].each_stub_opponents([players[0]])
        end

        it "returns false" do
          pairs.enough_players_to_guarantee_pairing?.should be false
        end
      end
    end
  end
end
