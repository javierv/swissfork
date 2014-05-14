require "swissfork/player"

describe Swissfork::Player do
  describe "#opponents" do
    let(:player) { Swissfork::Player.new(1) }

    context "new player" do
      it "doesn't have opponents" do
        player.opponents.should == []
      end
    end

    context "adding opponents" do
      before(:each) do
        3.times { |n| player.opponents << Swissfork::Player.new(n + 2) }
      end

      it "returns the added opponents" do
        player.opponents.map(&:number).should == [2, 3, 4]
      end
    end
  end

  describe "#<=>" do
    let(:player) { Swissfork::Player.new(2) }

    it "uses the number to compare players" do
      player.should be < Swissfork::Player.new(3)
      player.should be > Swissfork::Player.new(1)
    end
  end

  describe "#compatible_with" do
    let(:player) { Swissfork::Player.new(2) }
    before(:each) do
      player.stub(:opponents).and_return([Swissfork::Player.new(3)])
    end

    it "isn't compatible with a previous opponents" do
      player.compatible_with?(player.opponents.first).should be false
    end

    it "is compatible with players not in its opponents list" do
      player.compatible_with?(Swissfork::Player.new(1)).should be true
    end
  end
end
