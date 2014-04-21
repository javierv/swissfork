require "swissfork/player"

describe Swissfork::Player do
  describe "#opponents" do
    let(:player) { Swissfork::Player.new }

    context "new player" do
      it "doesn't have opponents" do
        player.opponents.should == []
      end
    end

    context "adding opponents" do
      before(:each) do
        3.times { player.opponents << Swissfork::Player.new }
      end

      it "returns the added opponents" do
        player.opponents.count.should == 3
      end
    end
  end
end
