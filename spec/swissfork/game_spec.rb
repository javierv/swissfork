require "spec_helper"
require "swissfork/game"
require "swissfork/player"

module Swissfork
  describe Game do
    let(:game) { Game.new(player, pair) }
    let(:player) { Player.new(1) }
    let(:opponent) { Player.new(2) }
    let(:pair) { black_pair }
    let(:white_pair) { double(players: [player, Player.new(3)]) }
    let(:black_pair) { double(players: [opponent, player]) }

    describe "#opponent" do
      context "played with white" do
        let(:pair) { white_pair }

        it "returns the opponent" do
          game.opponent.number.should eq 3
        end
      end

      context "played with black" do
        it "returns the opponent" do
          game.opponent.number.should eq 2
        end
      end
    end

    describe "#colour" do
      context "played game" do
        before { game.stub(played?: true) }

        context "played with white" do
          let(:pair) { white_pair }

          it "returns white" do
            game.colour.should eq :white
          end
        end

        context "played with black" do
          it "returns black" do
            game.colour.should eq :black
          end
        end
      end

      context "non-played game" do
        before { game.stub(played?: false) }

        it "returns nil" do
          game.colour.should be nil
        end
      end
    end

    describe "#float" do
      context "played game" do
        before { game.stub(played?: true) }

        context "both players had the same points" do
          before do
            pair.stub(points_before_playing: { 1 => 1, 2 => 1 })
          end

          it "returns nil" do
            game.float.should be nil
          end
        end

        context "the opponent had more points" do
          before do
            pair.stub(points_before_playing: { 1 => 1, 2 => 2 })
          end

          it "counts as upfloat" do
            game.float.should eq :up
          end
        end

        context "the opponent had less points" do
          before do
            pair.stub(points_before_playing: { 1 => 2, 2 => 1 })
          end

          it "counts as downfloat" do
            game.float.should eq :down
          end
        end
      end

      context "non-played game" do
        before { game.stub(played?: false) }

        context "the player didn't get a bye" do
          before { game.stub(bye?: false) }

          it "returns nil" do
            game.float.should be nil
          end
        end

        context "the player got a bye" do
          before { game.stub(bye?: true) }

          it "counts as a bye" do
            game.float.should eq :bye
          end
        end
      end
    end

    describe "#bye?" do
      # Tests for specific results are in the results section
      context "played game" do
        before do
          game.stub(played?: true)
        end

        it "returns false" do
          game.bye?.should be false
        end
      end
    end

    describe "#points_received" do
      # Tests for specific results are in the results section
      context "the player won" do
        before { game.stub(won?: true) }

        it "returns a floating number" do
          game.points_received.should eql 1.0
        end
      end

      context "the player lost" do
        before { game.stub(won?: false, draw?: false) }

        it "returns a floating number" do
          game.points_received.should eql 0.0
        end
      end
    end

    describe "results" do
      context "black won" do
        before { game.stub(result: :black_won) }

        it "counts as played" do
          game.played?.should be true
        end

        it "makes the player the winner" do
          game.winner.should eq player
        end

        it "gives the player the points the winner gets" do
          game.points_received.should eq 1
        end
      end

      context "white won" do
        before { game.stub(result: :white_won) }

        it "counts as played" do
          game.played?.should be true
        end

        it "makes the opponent the winner" do
          game.winner.should eq opponent
        end

        it "gives the player the points the loser gets" do
          game.points_received.should eq 0
        end
      end

      context "draw" do
        before { game.stub(result: :draw) }

        it "counts as played" do
          game.played?.should be true
        end

        it "makes nobody the winner" do
          game.winner.should be nil
        end

        it "gives the player the points given to a draw" do
          game.points_received.should eq 0.5
        end
      end

      context "black gets a forfeit win" do
        before { game.stub(result: :black_won_by_forfeit) }

        it "doesn't count as played" do
          game.played?.should be false
        end

        it "makes the player the winner" do
          game.winner.should eq player
        end

        it "gives the player the points the winner gets" do
          game.points_received.should eq 1
        end

        it "counts as a bye" do
          game.bye?.should be true
        end
      end

      context "white gets a forfeit win" do
        before { game.stub(result: :white_won_by_forfeit) }

        it "doesn't count as played" do
          game.played?.should be false
        end

        it "doesn't add the opponent to opponents" do
          player.add_game(game)
          player.opponents.should be_empty
        end

        it "makes the opponent the winner" do
          game.winner.should eq opponent
        end

        it "gives the player the points the loser gets" do
          game.points_received.should eq 0
        end

        it "doesn't count as a bye" do
          game.bye?.should be false
        end
      end
    end
  end
end
