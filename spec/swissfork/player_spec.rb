require "spec_helper"
require "swissfork/player"

module Swissfork
  describe Player do
    let(:player) { Player.new(1) }

    describe "#opponents" do
      context "no played games" do
        before(:each) { player.stub(games: []) }

        it "doesn't have opponents" do
          player.opponents.should == []
        end
      end

      context "played games" do
        before(:each) do
          3.times do |n|
            player.games << double(player: player, opponent: Player.new(n + 2))
          end
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
      let(:compatible) { Player.new(2) }
      let(:rival) { Player.new(3) }

      before(:each) do
        player.stub_opponents([rival])
      end

      it "isn't compatible with previous opponents and compatible otherwise" do
        player.compatible_players_in([rival, compatible]).should == [compatible]
      end

      context "same colour preference" do
        let(:same_preference) { Player.new(4) }
        let(:same_absolute_preference) { Player.new(5) }

        before(:each) do
          player.stub_preference(:white)
          same_preference.stub_preference(:white)
          same_absolute_preference.stub_preference(:white)

          player.stub_degree(:absolute)
          same_absolute_preference.stub_degree(:absolute)
          same_preference.stub_degree(:strong)
        end

        it "isn't compatible if they've got the same absolute colour preference" do
          player.compatible_players_in([same_preference, same_absolute_preference]).should == [same_preference]
        end

        context "the player is a topscorer" do
          before(:each) do
            player.stub(topscorer?: true)
          end

          it "is compatible with all non-opponents" do
            player.compatible_players_in([rival, same_absolute_preference]).should == [same_absolute_preference]
          end
        end

        context "the potential opponents are top-scorers" do
          before(:each) do
            rival.stub(topscorer?: true)
            same_absolute_preference.stub(topscorer?: true)
          end

          it "is compatible with all non-opponents" do
            player.compatible_players_in([rival, same_absolute_preference]).should == [same_absolute_preference]
          end
        end
      end
    end

    describe "#descended_in_the_previous_round?" do
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

    describe "#colour_difference" do
      context "no played games" do
        before(:each) do
          player.stub(colours: [nil, nil, nil])
        end

        it "returns zero" do
          player.colour_difference.should == 0
        end
      end

      context "two played games with white and one with black" do
        before(:each) do
          player.stub(colours: [:white, :black, :white])
        end

        it "returns one" do
          player.colour_difference.should == 1
        end
      end

      context "three played games with black and one with white" do
        before(:each) do
          player.stub(colours: [nil, :black, :black, :white, :black])
        end

        it "returns minus two" do
          player.colour_difference.should == -2
        end
      end
    end

    describe "#colour_preference" do
      context "no played games" do
        before(:each) do
          player.stub(colours: [nil, nil])
        end

        it "is nil" do
          player.colour_preference.should be nil
        end
      end

      context "same games played with each colour" do
        before(:each) do
          player.stub(colours: [nil, :white, :black])
        end

        it "is the opposite of the last played colour" do
          player.colour_preference.should == :white
        end
      end

      context "one more game played with one colour" do
        before(:each) do
          player.stub(colours: [:black])
        end

        it "is the colour played less times with" do
          player.colour_preference.should == :white
        end
      end

      context "two more games played with one colour" do
        before(:each) do
          player.stub(colours: [:white, :white, :black, :white])
        end

        it "is the colour played less times with" do
          player.colour_preference.should == :black
        end
      end

      context "two games played in a row with the same colour" do
        before(:each) do
          # The example is theoretically impossible, but it could happen if the
          # referee makes a mistake.
          player.stub(colours: [:black, :black, :white, :black, :black, :white, :white])
        end

        it "is is the opposite of the last colour" do
          player.colour_preference.should == :black
        end
      end
    end

    describe "#preference_degree" do
      context "no played games" do
        before(:each) do
          player.stub(colours: [nil, nil])
        end

        it "is none" do
          player.preference_degree.should == :none
        end
      end

      context "same games played with each colour" do
        before(:each) do
          player.stub(colours: [:white, :black])
        end

        it "is mild" do
          player.preference_degree.should == :mild
        end
      end

      context "one more game played with one colour" do
        before(:each) do
          player.stub(colours: [:black])
        end

        it "is strong" do
          player.preference_degree.should == :strong
        end
      end

      context "two more games played with one colour" do
        before(:each) do
          player.stub(colours: [:white, :white, :black, :white])
        end

        it "is absolute" do
          player.preference_degree.should == :absolute
        end
      end

      context "two games played in a row with the same colour" do
        before(:each) do
          player.stub(colours: [:white, :white, :black, :black])
        end

        it "is absolute" do
          player.preference_degree.should == :absolute
        end
      end
    end
  end
end
