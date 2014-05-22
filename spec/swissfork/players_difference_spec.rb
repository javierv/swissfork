require "swissfork/players_difference"

module Swissfork
  describe PlayersDifference do
    describe "#difference" do
      context "first player has a smaller number" do
        let(:s1_player) { double(number: 1) }
        let(:s2_player) { double(number: 3) }
        let(:difference) { PlayersDifference.new(s1_player, s2_player) }

        it "returns the difference between the numbers" do
          difference.difference.should == 2
        end
      end

      context "first player has a bigger number" do
        let(:s1_player) { double(number: 7) }
        let(:s2_player) { double(number: 3) }
        let(:difference) { PlayersDifference.new(s1_player, s2_player) }

        it "returns the difference between the numbers" do
          difference.difference.should == 4
        end
      end
    end

    describe "#<=>" do
      context "different differences between players" do
        let(:s1_player) { double(number: 1) }
        let(:smaller_s2_player) { double(number: 3) }
        let(:bigger_s2_player) { double(number: 4) }

        it "the one with the smaller difference is smaller" do
          PlayersDifference.new(s1_player, smaller_s2_player).should be <
            PlayersDifference.new(s1_player, bigger_s2_player)
        end
      end

      context "same differences between players" do
        let(:smaller_s1_player) { double(number: 1) }
        let(:bigger_s2_player) { double(number: 2) }
        let(:smaller_s2_player) { double(number: 3) }
        let(:bigger_s2_player) { double(number: 4) }

        it "the one with the bigger s1 player is smaller" do
          PlayersDifference.new(smaller_s2_player, bigger_s2_player).should be < PlayersDifference.new(smaller_s1_player, smaller_s2_player)
        end
      end
    end
  end
end
