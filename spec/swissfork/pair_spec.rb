require "spec_helper"
require "swissfork/pair"
require "swissfork/player"

module Swissfork
  describe Pair do
    def create_players(numbers)
      numbers.map { |number| Player.new(number) }
    end

    describe "==" do
      let(:s1_player) { double }
      let(:s2_player) { double }
      let(:pair) { Pair.new(s1_player, s2_player) }

      context "pairs with different players" do
        it "returns false" do
          pair.should_not == Pair.new(double, double)
          pair.should_not == Pair.new(s1_player, double)
          pair.should_not == Pair.new(double, s2_player)
        end
      end

      context "a pair with the same players" do
        it "returns true" do
          pair.should == Pair.new(s1_player, s2_player)
        end
      end

      context "a pair with the same players in different order" do
        it "returns true" do
          pair.should == Pair.new(s2_player, s1_player)
        end
      end
    end

    describe "<=>" do
      let(:players) { create_players(1..5) }
      let(:pair_with_first_player) { Pair.new(players[0], players[4]) }
      let(:pair_with_second_player) { Pair.new(players[1], players[2]) }

      before(:each) { players.each { |player| player.stub(points: 3) } }

      context "all players have the same points" do
        it "the pair with the smallest player is smaller" do
          pair_with_first_player.should be < pair_with_second_player
        end
      end

      context "one player has more points, but the sum is smaller" do
        before(:each) do
          players[0].stub(points: 1)
          players[4].stub(points: 4)
        end

        it "the pair with the player with more points is smaller" do
          pair_with_first_player.should be < pair_with_second_player
        end
      end

      context "one player has less points" do
        before(:each) { players[0].stub(points: 2) }

        it "the pair with more points is smaller" do
          pair_with_second_player.should be < pair_with_first_player
        end
      end
    end

    describe "#players" do
      let(:higher_player) { Player.new(1) }
      let(:lower_player) { Player.new(2) }
      let(:pair) { Pair.new(lower_player, higher_player) }

      context "different colour preference" do
        before(:each) do
          higher_player.stub_preference(:black)
          lower_player.stub_preference(:white)
        end

        context "the lower player has a stronger preference" do
          before(:each) do
            higher_player.stub_degree(:strong)
            lower_player.stub_degree(:absolute)
          end

          it "respects both players preference" do
            pair.players.should == [lower_player, higher_player]
          end
        end
      end

      context "both preferences are black" do
        before(:each) do
          higher_player.stub_preference(:black)
          lower_player.stub_preference(:black)
        end

        context "same preference degree" do
          before(:each) do
            higher_player.stub_degree(:strong)
            lower_player.stub_degree(:strong)
          end

          it "gives the preference to the higher player" do
            pair.players.should == [lower_player, higher_player]
          end
        end

        context "both players have an absolute preference" do
          before(:each) do
            higher_player.stub_degree(:absolute)
            lower_player.stub_degree(:absolute)
          end

          context "both have the same colour difference" do
            before(:each) do
              higher_player.stub(colour_difference: 2)
              lower_player.stub(colour_difference: 2)
            end

            it "gives the preference to the higher player" do
              pair.players.should == [lower_player, higher_player]
            end
          end

          context "the lower player has a wider difference" do
            before(:each) do
              higher_player.stub(colour_difference: 0)
              lower_player.stub(colour_difference: 1)
            end

            it "gives the preference to the lower player" do
              pair.players.should == [higher_player, lower_player]
            end
          end
        end

        context "the lower player has a stronger preference" do
          before(:each) do
            higher_player.stub_degree(:strong)
            lower_player.stub_degree(:absolute)
          end

          it "gives the preference to the lower player" do
            pair.players.should == [higher_player, lower_player]
          end
        end
      end

      context "both preferences are white" do
        before(:each) do
          higher_player.stub_preference(:white)
          lower_player.stub_preference(:white)
        end

        context "same preference degree" do
          before(:each) do
            higher_player.stub_degree(:strong)
            lower_player.stub_degree(:strong)
          end

          it "gives the preference to the higher player" do
            pair.players.should == [higher_player, lower_player]
          end
        end

        context "the lower player has a stronger preference" do
          before(:each) do
            higher_player.stub_degree(:strong)
            lower_player.stub_degree(:absolute)
          end

          it "gives the preference to the lower player" do
            pair.players.should == [lower_player, higher_player]
          end
        end
      end

      context "the higher player doesn't have a colour preference" do
        before(:each) do
          higher_player.stub_preference(nil)
          lower_player.stub_preference(:white)
        end

        it "respects the lower player preference" do
          pair.players.should == [lower_player, higher_player]
        end

        context "the lower player doesn't have a preference either" do
          before(:each) do
            lower_player.stub_preference(nil)
          end

          context "the higher player has an odd number" do
            it "gives the higher player the initial colour" do
              pair.players.should == [higher_player, lower_player]
            end
          end

          context "the higher player has an even number" do
            before(:each) do
              higher_player.stub(number: 2)
              lower_player.stub(number: 3)
            end

            it "gives the higher player the opposite of the initial colour" do
              pair.players.should == [lower_player, higher_player]
            end
          end

          context "both players have an odd number" do
            before(:each) do
              higher_player.stub(number: 1)
              lower_player.stub(number: 3)
            end

            it "gives the higher player the initial colour" do
              pair.players.should == [higher_player, lower_player]
            end
          end

          context "both players have an even number" do
            before(:each) do
              higher_player.stub(number: 2)
              lower_player.stub(number: 4)
            end

            it "gives the higher player the opposite of the initial colour" do
              pair.players.should == [lower_player, higher_player]
            end
          end
        end
      end

      context "same preference and different colour history" do
        before(:each) do
          higher_player.stub_preference(:white)
          lower_player.stub_preference(:white)

          higher_player.stub(colours: [:black, :white, :white, :black])
          lower_player.stub(colours: [:white, :black, :white, :black])
        end

        it "alternates colour to the most recent time they were different" do
          pair.players.should == [lower_player, higher_player]
        end

        context "the last different time happened before one got a bye" do
          before(:each) do
            higher_player.stub(colours: [nil, :black, :white, :black, :white])
            lower_player.stub(colours: [:white, :black, :black, nil, :white])
          end

          it "alternates colour to the most recent time they were different" do
            pair.players.should == [lower_player, higher_player]
          end
        end

        context "the colour history is the same if we reorder the byes" do
          before(:each) do
            higher_player.stub(colours: [:white, :black, :white, :black, :white, :black])
            lower_player.stub(colours: [nil, :white, :black, :white, :black, nil])
          end

          it "gives priority to the higher player" do
            pair.players.should == [higher_player, lower_player]
          end
        end

        context "the higher player has stronger preference" do
          before(:each) do
            higher_player.stub_degree(:strong)
          end

          it "gives priority to the higher player" do
            pair.players.should == [higher_player, lower_player]
          end
        end
      end
    end

    describe "#same_strong_preference" do
      let(:s1_player) { double }
      let(:s2_player) { double }
      let(:pair) { Pair.new(s1_player, s2_player) }

      context "different colour preference" do
        before(:each) do
          pair.stub(same_colour_preference?: false)
        end

        it "returns false" do
          pair.same_strong_preference?.should be false
        end
      end

      context "same colour preference" do
        before(:each) do
          pair.stub(same_colour_preference?: true)
        end

        context "both players have strong preference" do
          before(:each) do
            s1_player.stub_degree(:strong)
            s2_player.stub_degree(:strong)
          end

          it "returns true" do
            pair.same_strong_preference?.should be true
          end
        end

        context "one player has mild preference" do
          before(:each) do
            s1_player.stub_degree(:mild)
            s2_player.stub_degree(:strong)
          end

          it "returns false" do
            pair.same_strong_preference?.should be false
          end
        end

        context "one player has absolute preference" do
          before(:each) do
            s1_player.stub_degree(:absolute)
            s2_player.stub_degree(:strong)
          end

          it "returns true" do
            pair.same_strong_preference?.should be true
          end
        end
      end
    end

    describe "#result=" do
      let(:s1_player) { Player.new(1) }
      let(:s2_player) { Player.new(2) }
      let(:pair) { Pair.new(s1_player, s2_player) }

      before(:each) do
        pair.result = :white_won
      end

      it "assigns the result" do
        pair.result.should == :white_won
      end

      it "adds a game to every player" do
        s1_player.games[0].opponent.should == s2_player
        s1_player.games[0].winner.should == s1_player
        s2_player.games[0].opponent.should == s1_player
        s2_player.games[0].winner.should == s1_player
      end
    end
  end
end
