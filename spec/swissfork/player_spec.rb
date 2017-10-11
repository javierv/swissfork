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

    describe "#descended_in_the_previous_round?" do
      let(:player) { Player.new(1) }

      context "first round" do
        before(:each) { player.stub(floats: []) }

        it "returns false" do
          player.descended_in_the_previous_round?.should be false
        end
      end

      context "downfloated in the previous round" do
        before(:each) { player.stub(floats: [nil, :up, :down]) }

        it "returns true" do
          player.descended_in_the_previous_round?.should be true
        end
      end

      context "had a bye in the previous round" do
        before(:each) { player.stub(floats: [:up, nil, :bye]) }

        it "returns true" do
          player.descended_in_the_previous_round?.should be true
        end
      end

      context "downfloated two rounds ago" do
        before(:each) { player.stub(floats: [:up, :down, nil]) }

        it "returns false" do
          player.descended_in_the_previous_round?.should be false
        end
      end

      context "had a bye two rounds ago" do
        before(:each) { player.stub(floats: [:bye, :down, :up]) }

        it "returns false" do
          player.descended_in_the_previous_round?.should be false
        end
      end
    end
  end
end
