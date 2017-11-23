require "create_players_helper"
require "swissfork/moved_down_best_quality_calculator"

module Swissfork
  describe MovedDownBestQualityCalculator do
    let(:players) { create_players(1..10) }
    let(:moved_down_players) { players[0..2] }
    let(:resident_players) { players[3..9] }

    let(:quality_calculator) do
      MovedDownBestQualityCalculator.new(moved_down_players, resident_players)
    end

    describe "#moved_down_compatible_pairs" do
      context "all moved down players can be paired" do
        before(:each) do
          players[0].stub_opponents(players[1..2])
          players[1].stub_opponents([players[0], players[2]])
          players[2].stub_opponents(players[0..1])
        end

        it "returns the number of moved down players" do
          quality_calculator.moved_down_compatible_pairs.should eq 3
        end
      end

      context "there are more moved down players than resident players" do
        let(:players) { create_players(1..5) }

        before(:each) do
          players[0..2].each_stub(points: 1.5)
          players[3..4].each_stub(points: 1)
          players[0].stub_opponents(players[1..2])
          players[1].stub_opponents([players[0], players[2]])
          players[2].stub_opponents(players[0..1])
        end

        it "returns the number of resident players" do
          quality_calculator.moved_down_compatible_pairs.should eq 2
        end
      end

      context "one of the moved down players can't be paired" do
        before(:each) do
          players[0].stub_opponents(players[1..9])
          players[1].stub_opponents([players[0], players[2]])
          players[2].stub_opponents(players[0..1])
          players[3..9].each_stub_opponents([players[0]])
        end

        it "doesn't count that player as pairable" do
          quality_calculator.moved_down_compatible_pairs.should eq 2
        end
      end

      context "two of the moved down players can't be paired" do
        before(:each) do
          players[0..1].each_stub_opponents(players[0..9])
          players[2].stub_opponents(players[0..1])
          players[3..9].each_stub_opponents(players[0..1])
        end

        it "doesn't count those players as pairable" do
          quality_calculator.moved_down_compatible_pairs.should eq 1
        end
      end

      context "two players can only be paired to the same opponent" do
        before(:each) do
          players[0..1].each_stub_opponents(players[0..8])
          players[2].stub_opponents(players[0..1])
          players[3..8].each_stub_opponents(players[0..1])
        end

        it "counts only one of those players as pairable" do
          quality_calculator.moved_down_compatible_pairs.should eq 2
        end
      end

      context "three players can only be paired to the same two opponents" do
        let(:players) { create_players(1..8) }

        before(:each) do
          players[0..2].each_stub_opponents(players[0..7])
          players[3..7].each_stub_opponents(players[0..2])
        end

        it "counts only two of those players as pairable" do
          quality_calculator.possible_pairs.should eq 2
        end
      end
    end

    describe "#allowed_downfloats" do
      def players_sets(*indices_groups)
        Set.new indices_groups.map do |indices|
          Set.new(indices.map { |index| players[index] })
        end
      end

      let(:moved_down_players) { players[0..3] }
      let(:resident_players) { players[4..9] }

      before(:each) do
        players[0..1].each_stub(points: 3)
        players[2..3].each_stub(points: 2)
        players[4..9].each_stub(points: 1)
      end

      context "one downfloat needed" do
        before(:each) { quality_calculator.stub(required_moved_down_downfloats: 1) }

        context "only one player can downfloat" do
          before(:each) do
            quality_calculator.stub(allowed_homogeneous_downfloats:
              players_sets([0, 5, 8], [4, 7, 9], [7, 0, 9], [5, 6, 8]))
          end

          it "returns the downfloats including that player" do
            quality_calculator.allowed_downfloats.should eq players_sets([0, 5, 8], [7, 0, 9])
          end

          context "all players can downfloat" do
            before(:each) do
              quality_calculator.stub(allowed_homogeneous_downfloats:
                players_sets([0, 5, 8], [1, 7, 9], [2, 7, 9], [3, 6, 8]))
            end

            it "returns downfloats including players with less points" do
              quality_calculator.allowed_downfloats.should eq players_sets([2, 7, 9], [3, 6, 8])
            end
          end
        end
      end

      context "three downfloats needed" do
        before(:each) { quality_calculator.stub(required_moved_down_downfloats: 3) }

        context "only combinations includes both players with more points" do
          before(:each) do
            quality_calculator.stub(allowed_homogeneous_downfloats:
              players_sets([0, 1, 2, 4], [1, 7, 8, 9], [0, 1, 3, 9], [1, 2, 6, 8])
            )
          end

          it "returns downfloats having three moved down players" do
            quality_calculator.allowed_downfloats.should eq players_sets([0, 1, 2, 4], [0, 1, 3, 9])
          end
        end

        context "combinations include both players with less points" do
          before(:each) do
            quality_calculator.stub(allowed_homogeneous_downfloats:
              players_sets([0, 1, 2, 4], [1, 7, 8, 9], [0, 2, 3, 9], [1, 2, 3, 8])
            )
          end

          it "returns downfloats having both players with less points" do
            quality_calculator.allowed_downfloats.should eq players_sets([0, 2, 3, 9], [1, 2, 3, 8])
          end
        end

        context "combinations include all players" do
          before(:each) do
            quality_calculator.stub(allowed_homogeneous_downfloats:
              players_sets([0, 1, 2, 4], [0, 1, 2, 3], [0, 2, 3, 9], [1, 2, 3, 8])
            )
          end

          it "returns downfloats having both players with less points" do
            quality_calculator.allowed_downfloats.should eq players_sets([0, 2, 3, 9], [1, 2, 3, 8])
          end
        end
      end
    end
  end
end
