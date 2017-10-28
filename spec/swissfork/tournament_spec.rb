require "spec_helper"
require "swissfork/tournament"
require "swissfork/inscription"

module Swissfork
  describe Tournament do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    let(:tournament) { Tournament.new(9) }

    describe "#players" do
      before(:each) do
        tournament.add_inscription(Inscription.new(2300, "Louis Armstrong"))
        tournament.add_inscription(Inscription.new(2200, "Aretha Franklin"))
        tournament.add_inscription(Inscription.new(2400, "Django Reinhardt"))
        tournament.add_inscription(Inscription.new(2130, "Ludwig van Beethoven"))
      end

      context "the first round hasn't started yet" do
        it "hasn't defined the players yet" do
          tournament.players.should be nil
        end
      end

      context "the first round has started" do
        before(:each) { tournament.start_round }

        it "orders the players and gives them numbers" do
          tournament.players.map(&:number).should == [1, 2, 3, 4]
          tournament.players.map(&:rating).should == [2400, 2300, 2200, 2130]
        end
      end

      context "the tournament has started" do
        before(:each) { tournament.start }

        it "orders the players and gives them numbers" do
          tournament.players.map(&:number).should == [1, 2, 3, 4]
          tournament.players.map(&:rating).should == [2400, 2300, 2200, 2130]
        end
      end
    end

    describe "#non_paired_numbers=" do
      before(:each) do
        tournament.stub(players: create_players(1..12))
      end

      context "no previous rounds" do
        before(:each) do
          tournament.non_paired_numbers = [1, 2, 3, 4]
          tournament.start_round
        end

        it "excludes those players from pairing" do
          tournament.pair_numbers.should == [[5, 9], [10, 6], [7, 11], [12, 8]]
        end

        context "players were excluded in a previous round" do
          before(:each) do
            tournament.finish_round([:white_won, :black_won, :white_won, :black_won])
          end

          it "adds an unpaired game to the excluded players" do
            tournament.players[0].games[0].played?.should be false
          end

          context "not excluding anyone" do
            before(:each) { tournament.start_round }

            it "pairs all players" do
              tournament.pair_numbers.should == [[8, 5], [6, 7], [1, 3], [4, 2], [9, 12], [11, 10]]
            end
          end

          context "excluding some other players" do
            before(:each) do
              tournament.non_paired_numbers = [5, 7, 10, 12]
              tournament.start_round
            end

            it "doesn't pair those players, but pairs the ones previously excluded" do
              tournament.pair_numbers.should == [[6, 8], [1, 3], [4, 2], [9, 11]]
            end
          end
        end
      end

      context "using non-default points given to unpaired players" do
        context "the tournament uses 0.5 as default points" do
          before(:each) do
            tournament.non_paired_numbers = [1, { 2 => 0, 3 => 1 }, 4]
            tournament.start_round
            tournament.finish_round([:white_won, :black_won, :white_won, :black_won])
          end

          it "gives the unspecified players the default points" do
            tournament.players[0].points.should == 0.5
            tournament.players[3].points.should == 0.5
          end

          it "gives the specificied players the specified points" do
            tournament.players[1].points.should == 0
            tournament.players[2].points.should == 1
          end
        end

        context "it's the last round" do
          before(:each) do
            tournament.stub(last_round?: true)
            tournament.non_paired_numbers = [1, { 2 => 0.5, 3 => 1 }, 4]
            tournament.start_round
            tournament.finish_round([:white_won, :black_won, :white_won, :black_won])
          end

          it "gives the unspecified players no points" do
            tournament.players[0].points.should == 0
            tournament.players[3].points.should == 0
          end

          it "gives the specificied players the specified points" do
            tournament.players[1].points.should == 0.5
            tournament.players[2].points.should == 1
          end
        end

        context "the tournament uses 0 as default points" do
          before(:each) do
            tournament.points_given_to_unpaired_players = 0
            tournament.non_paired_numbers = [1, { 2 => 0.5, 3 => 1 }, 4]
            tournament.start_round
            tournament.finish_round([:white_won, :black_won, :white_won, :black_won])
          end

          it "gives the unspecified players the default points" do
            tournament.players[0].points.should == 0
            tournament.players[3].points.should == 0
          end

          it "gives the specificied players the specified points" do
            tournament.players[1].points.should == 0.5
            tournament.players[2].points.should == 1
          end
        end
      end
    end

    describe "topscorers management" do
      let(:players) { create_players(1..10) }

      before(:each) do
        tournament.stub(players: players)
        players[0..1].each { |player| player.stub(points: 6) }
        players[2..3].each { |player| player.stub(points: 5) }
        players[4..5].each { |player| player.stub(points: 4) }
        players[6..7].each { |player| player.stub(points: 3) }
        players[8..9].each { |player| player.stub(points: 2) }
      end

      describe "#topscorers" do
        context "not the last round" do
          before(:each) do
            7.times { tournament.rounds << double(finished?: true) }
          end

          it "returns an empty array" do
            tournament.topscorers.should == []
          end
        end

        context "last round" do
          before(:each) do
            8.times { tournament.rounds << double(finished?: true) }
          end

          it "returns the topscorers" do
            tournament.topscorers.should == players[0..3]
          end
        end
      end

      describe "absolute preference pairing" do
        before(:each) do
          players[0..1].each { |player| player.stub_preference(:white) }
          players[2..3].each { |player| player.stub_preference(:black) }
          players[4..5].each { |player| player.stub_preference(:white) }
          players[6..7].each { |player| player.stub_preference(:black) }
          players[8..9].each { |player| player.stub_preference(:white) }

          players[0..7].each { |player| player.stub_degree(:absolute) }
          players[8..9].each { |player| player.stub_degree(:mild) }
        end

        context "not the last round" do
          before(:each) do
            7.times { tournament.rounds << double(finished?: true) }
            tournament.start_round
          end

          it "doesn't pair players with same absolute preference together" do
            tournament.pair_numbers.should == [[1, 3], [2, 4], [5, 7], [6, 8], [9, 10]]
          end
        end

        context "last round" do
          before(:each) do
            8.times { tournament.rounds << double(finished?: true) }
            tournament.start_round
          end

          it "pairs topscorers with same absolute preference together" do
            tournament.pair_numbers.should == [[1, 2], [4, 3], [5, 7], [6, 8], [9, 10]]
          end
        end
      end
    end

    describe "late entries" do
      let(:inscriptions) do
        [ Inscription.new(2990, "Paul Morphy"),
          Inscription.new(2980, "José Capablanca"),
          Inscription.new(2970, "Alexander Alekhine"),
          Inscription.new(2960, "Mikhail Tal") ]
      end

      let(:late_entries) do
        [ Inscription.new(2985, "Emanuel Lasker"),
          Inscription.new(2950, "Tigran Petrosian") ]
      end

      before(:each) do
        tournament.add_inscriptions(inscriptions)

        tournament.start_round
        tournament.finish_round([:draw, :draw])

        tournament.add_late_entries(late_entries)
        tournament.start_round
      end

      it "reorders the players" do
        tournament.players.map(&:rating).should == [2990, 2985, 2980, 2970, 2960, 2950]
      end

      it "reassigns the numbers" do
        tournament.players.map(&:number).should == [1, 2, 3, 4, 5, 6]
      end

      it "assigns new ids to new players" do
        tournament.players.map(&:id).should == [1, 5, 2, 3, 4, 6]
      end

      it "pairs the new entries" do
        tournament.pairs.map { |pair| pair.players.map(&:name) }.should ==
          [["José Capablanca", "Paul Morphy"],
           ["Emanuel Lasker", "Mikhail Tal"],
           ["Alexander Alekhine", "Tigran Petrosian"]]
      end

      it "reassigns the numbers in the previous rounds" do
        tournament.rounds.first.pair_numbers.should == [[1, 4], [5, 3]]
      end
    end
  end
end
