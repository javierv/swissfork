require "swissfork/pair"

describe Swissfork::Pair do
  describe "==" do
    let(:s1_player) { double }
    let(:s2_player) { double }
    let(:pair) { Swissfork::Pair.new(s1_player, s2_player) }

    context "pairs with different players" do
      it "returns false" do
        pair.should_not == Swissfork::Pair.new(double, double)
        pair.should_not == Swissfork::Pair.new(s1_player, double)
        pair.should_not == Swissfork::Pair.new(double, s2_player)
      end
    end

    context "a pair with the same players" do
      it "returns true" do
        pair.should == Swissfork::Pair.new(s1_player, s2_player)
      end
    end

    context "a completely different object" do
      it "returns false" do
        pair.should_not == 3
      end
    end
  end
end
