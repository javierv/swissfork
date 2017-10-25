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
    end
  end
end
