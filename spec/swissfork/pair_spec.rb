require "spec_helper"
require "swissfork/pair"
require "swissfork/player"

module Swissfork
  describe Pair do
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
      let(:smaller_pair) { Pair.new(1, 5) }
      let(:bigger_pair) { Pair.new(2, 3) }

      it "the pair with the smallest player is smaller" do
        smaller_pair.should be < bigger_pair
      end
    end

    describe "#players" do
      let(:higher_player) { Player.new(1) }
      let(:lower_player) { Player.new(2) }
      let(:pair) { Pair.new(higher_player, lower_player) }

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
          higher_player.stub_preference(:none)
          lower_player.stub_preference(:white)
        end

        it "respects the lower player preference" do
          pair.players.should == [lower_player, higher_player]
        end
      end
    end
  end
end
