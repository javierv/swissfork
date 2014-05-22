require "swissfork/player"

module Swissfork
  describe Player do
    describe "#opponents" do
      let(:player) { Player.new(1) }

      context "new player" do
        it "doesn't have opponents" do
          player.opponents.should == []
        end
      end

      context "adding opponents" do
        before(:each) do
          3.times { |n| player.opponents << Player.new(n + 2) }
        end

        it "returns the added opponents" do
          player.opponents.map(&:number).should == [2, 3, 4]
        end
      end
    end

    describe "#<=>" do
      context "players with different points" do
        let(:player) { Player.new(2).tap { |player| player.stub(:points).and_return(1) } }

        it "uses the points in descending order to compare players" do
          player.should be < Player.new(1)
          player.should be > Player.new(3).tap { |player| player.stub(:points).and_return(2) }
        end
      end

      context "players with the same points" do
        let(:player) { Player.new(2) }

        it "uses the number to compare players" do
          player.should be < Player.new(3)
          player.should be > Player.new(1)
        end
      end
    end

    describe "#compatible_with" do
      let(:player) { Player.new(2) }
      before(:each) do
        player.stub(:opponents).and_return([Player.new(3)])
      end

      it "isn't compatible with a previous opponents" do
        player.compatible_with?(player.opponents.first).should be false
      end

      it "is compatible with players not in its opponents list" do
        player.compatible_with?(Player.new(1)).should be true
      end
    end
  end
end
