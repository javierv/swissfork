require "swissfork/penultimate_bracket_handler"
require "swissfork/player"
require "swissfork/round"

module Swissfork
  describe PenultimateBracketHandler do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    describe "#move_players_to_allow_last_bracket_pairs" do
      let(:players) { create_players(1..10) }
      let(:round) { Round.new(players) }
      let(:penultimate_scoregroup) { round.scoregroups[0] }
      let(:last_scoregroup) { round.scoregroups[1] }
      let(:handler) { PenultimateBracketHandler.new(penultimate_scoregroup, last_scoregroup) }

      before(:each) do
        players[0..7].each { |player| player.stub(points: 1) }
        players[8..9].each { |player| player.stub(points: 0) }
      end

      context "no need to move players" do
        before(:each) { handler.move_players_to_allow_last_bracket_pairs }

        it "doesn't move players" do
          last_scoregroup.players.should == players[8..9]
          penultimate_scoregroup.players.should == players[0..7]
        end
      end

      context "last players from the PPB complete the pairing" do
        before(:each) do
          players[8].stub(opponents: [players[9]])
          players[9].stub(opponents: [players[8]])
          handler.move_players_to_allow_last_bracket_pairs
        end

        it "descends the last players from the previous bracket" do
          last_scoregroup.players.should == players[6..9]
        end

        it "removes players from the previous bracket" do
          penultimate_scoregroup.players.should == players[0..5]
        end
      end

      context "last players from the PPB don't complete the pairing" do
        before(:each) do
          players[6].stub(opponents: [players[8], players[9]])
          players[7].stub(opponents: [players[8], players[9]])
          players[8].stub(opponents: [players[9]] + players[6..7])
          players[9].stub(opponents: [players[8]] + players[6..7])
          handler.move_players_to_allow_last_bracket_pairs
        end

        it "descend the lowest players allowing the pair" do
          last_scoregroup.players.should == players[4..5] + players[8..9]
        end

        it "removes those players and only those players from the previous bracket" do
          penultimate_scoregroup.players.should == players[0..3] + players[6..7]
        end
      end

      context "more than one permutation needed" do
        before(:each) do
          players[5].stub(opponents: [players[8], players[9]])
          players[6].stub(opponents: [players[8]])
          players[7].stub(opponents: [players[8]])
          players[8].stub(opponents: players[6..7] + [players[9], players[5]])
          players[9].stub(opponents: [players[5], players[8]])
          handler.move_players_to_allow_last_bracket_pairs
        end

        it "descends the lowest players allowing the pair" do
          last_scoregroup.players.should == [players[4], players[7]] + players[8..9]
          penultimate_scoregroup.players.should == players[0..3] + players[5..6]
        end
      end

      context "no players allow last bracket pairs" do
        before(:each) do
          players[0..7].each { |player| player.stub(opponents: [players[8], players[9]]) }
          players[8].stub(opponents: players[0..7] + [players[9]])
          players[9].stub(opponents: players[0..7] + [players[8]])
        end

        it "returns nil" do
          handler.move_players_to_allow_last_bracket_pairs.should be nil
        end
      end
    end
  end
end
