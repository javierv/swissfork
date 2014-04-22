require "swissfork/players_difference"

describe Swissfork::PlayersDifference do
  describe "#difference" do
    context "first player has a smaller number" do
      let(:s1_player) { double(:number => 1) }
      let(:s2_player) { double(:number => 3) }
      let(:difference) { Swissfork::PlayersDifference.new(s1_player, s2_player) }

      it "returns the difference between the numbers" do
        difference.difference.should == 2
      end
    end

    context "first player has a bigger number" do
      let(:s1_player) { double(:number => 7) }
      let(:s2_player) { double(:number => 3) }
      let(:difference) { Swissfork::PlayersDifference.new(s1_player, s2_player) }

      it "returns the difference between the numbers" do
        difference.difference.should == 4
      end
    end
  end

  describe "#<=>" do
    context "different differences between players" do
      let(:s1_player) { Swissfork::Player.new(1) }
      let(:smaller_s2_player) { Swissfork::Player.new(3) }
      let(:bigger_s2_player) { Swissfork::Player.new(4) }

      it "the one with the smaller difference is smaller" do
        Swissfork::PlayersDifference.new(s1_player, smaller_s2_player).should be <
          Swissfork::PlayersDifference.new(s1_player, bigger_s2_player)
      end
    end

    context "same differences between players" do
      let(:smaller_s1_player) { Swissfork::Player.new(1) }
      let(:bigger_s2_player) { Swissfork::Player.new(2) }
      let(:smaller_s2_player) { Swissfork::Player.new(3) }
      let(:bigger_s2_player) { Swissfork::Player.new(4) }

      it "the one with the bigger s1 player is smaller" do
        Swissfork::PlayersDifference.new(smaller_s2_player, bigger_s2_player).should be < Swissfork::PlayersDifference.new(smaller_s1_player, smaller_s2_player)
      end
    end
  end
end
