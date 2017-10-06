require "spec_helper"
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
        let(:player) { Player.new(2).tap { |player| player.stub(points: 1) } }

        it "uses the points in descending order to compare players" do
          player.should be < Player.new(1)
          player.should be > Player.new(3).tap { |player| player.stub(points: 2) }
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

    describe "#compatible_players_in" do
      let(:player) { Player.new(2) }
      let(:compatible) { Player.new(1) }
      let(:rival) { Player.new(3) }
      before(:each) do
        player.stub_opponents([rival])
      end

      it "isn't compatible with a previous opponents and compatible otherwise" do
        player.compatible_players_in([rival, compatible]).should == [compatible]
      end
    end
  end
end
