require "spec_helper"
require "swissfork/bye_game"

module Swissfork
  describe ByeGame do
    let(:game) { ByeGame.new(double) }

    it "counts as a bye" do
      game.bye?.should be true
      game.float.should eq :bye
    end

    it "doesn't count as played" do
      game.played?.should be false
    end

    it "doesn't assign a colour" do
      game.colour.should be nil
    end

    it "implements the same interface a regular game does" do
      -> { game.opponent }.should_not raise_error
      -> { game.winner }.should_not raise_error
      -> { game.pair }.should_not raise_error
    end

    describe "#points_received" do
      it "gives the points assigned by the tournament" do
        game.points_received.should be 1.0
      end

      context "points specified in the initialize method" do
        let(:game) { ByeGame.new(double, points: 0.5) }

        it "gives it the ponts assigned manually" do
          game.points_received.should eq 0.5
        end
      end
    end
  end
end
