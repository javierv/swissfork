require "swissfork/pair"

module Swissfork
  describe Pair do
    describe "==" do
      let(:s1_player) { double }
      let(:s2_player) { double }
      let(:pair) { Pair.new(s1_player, s2_player) }

      context "pairs with different players" do
        it "returns false" do
          pair.should_not == Pair.new(double, double)
          pair.should_not == Pair.new(s1_player, double)
          pair.should_not == Pair.new(double, s2_player)
        end
      end

      context "a pair with the same players" do
        it "returns true" do
          pair.should == Pair.new(s1_player, s2_player)
        end
      end

      context "a completely different object" do
        it "returns false" do
          pair.should_not == 3
        end
      end
    end

    describe "<=>" do
      let(:smaller_pair) { Pair.new(1, 5) }
      let(:bigger_pair) { Pair.new(2, 3) }

      it "the pair with the smallest player is smaller" do
        smaller_pair.should be < bigger_pair
      end
    end
  end
end
