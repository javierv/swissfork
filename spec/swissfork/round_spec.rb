require "create_players_helper"
require "swissfork/round"

module Swissfork
  describe Round do
    describe "#scoregroups" do
      context "players with the same points" do
        let(:players) { create_players(1..6) }

        it "returns only one scoregroup" do
          Round.new(players).scoregroups.count.should be 1
        end
      end

      context "players with different points" do
        let(:players) { create_players(1..6) }
        let(:scoregroups) { Round.new(players).scoregroups }

        before do
          players[0].stub(points: 1)
          players[1].stub(points: 1)
          players[2].stub(points: 2)
          players[3].stub(points: 0.5)
        end

        it "returns as many scoregroups as different points" do
          scoregroups.count.should be 4
        end

        it "sorts the scoregroups by number of points" do
          scoregroups.map(&:points).should eq [2, 1, 0.5, 0]
        end

        it "groups each player to the right scoregroup" do
          scoregroups[0].players.should eq [players[2]]
          scoregroups[1].players.should eq [players[0], players[1]]
          scoregroups[2].players.should eq [players[3]]
          scoregroups[3].players.should eq [players[4], players[5]]
        end
      end
    end

    describe "#pairs" do
      let(:round) { Round.new(players) }

      context "only one bracket" do
        let(:players) { create_players(1..7) }

        it "returns the same pairs as the bracket" do
          round.pair_numbers.should eq Bracket.for(players).pair_numbers
        end
      end

      context "many brackets, all easily paired" do
        let(:players) { create_players(1..20) }

        before do
          players[0..9].each_stub(points: 1)
        end

        it "returns the combination of each brackets pairs" do
          round.pair_numbers.should eq Bracket.for(players[0..9]).pair_numbers + Bracket.for(players[10..19]).pair_numbers
        end
      end
    end

    describe "#results" do
      let(:players) { create_players(1..11) }
      let(:round) { Round.new(players) }

      context "no results yet" do
        it "returns an array full of nil" do
          round.results.should eq [nil, nil, nil, nil, nil]
        end
      end

      context "results have been set" do
        before do
          round.results = %i[white_won black_won draw black_won white_won]
        end

        it "sets the results of each pair" do
          round.pairs[0].result.should eq :white_won
          round.pairs[2].result.should eq :draw
        end

        it "assigns the bye" do
          players.last.games[0].bye?.should be true
        end
      end

      context "results aren't the same size as the round pairs" do
        it "raises an exception" do
          -> { round.results = [:white_won] }.should raise_error(IndexError)
        end
      end
    end
  end
end
