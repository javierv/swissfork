require "syntax_spec_helper"
require "swissfork"

module Swissfork
  describe Tournament do
    def late_entry(number)
      Inscription.new(tournament.inscriptions.sort[number - 2].rating, tournament.inscriptions.sort[number - 2].name + "a")
    end

    let(:tournament) { Tournament.new(8) }
    let(:inscriptions) do
      Array.new(71) { [rand(1500..2400), rand(1..100000).to_s] }.map do |rating, name|
        Inscription.new(rating, name)
      end
    end

    before(:each) do
      tournament.add_inscriptions(inscriptions)
      tournament.start
    end

    it "pairs every round correctly" do
      # First round
      tournament.start_round

      tournament.pair_numbers.should eq [[1, 36], [37, 2], [3, 38], [39, 4], [5, 40], [41, 6], [7, 42], [43, 8], [9, 44], [45, 10], [11, 46], [47, 12], [13, 48], [49, 14], [15, 50], [51, 16], [17, 52], [53, 18], [19, 54], [55, 20], [21, 56], [57, 22], [23, 58], [59, 24], [25, 60], [61, 26], [27, 62], [63, 28], [29, 64], [65, 30], [31, 66], [67, 32], [33, 68], [69, 34], [35, 70]]
      tournament.current_round.bye.number.should eq 71

      tournament.finish_round(
        %w[1 1 1 ½ 0 ½ 1 1 1 ½ 1 0 1 ½ 1 0 1 0 1 1 1 0 1 0 1 0 1 0 1 0 1 0 0 0 1]
      )

      # Second round
      [32, 47, 55, 56, 65, 67].each do |number| # Numbers they got assigned
        tournament.add_late_entry(late_entry(number))
      end
      tournament.non_paired_numbers = [34, 36, 50]
      tournament.start_round

      # Hack because the original tournament used a different criteria
      # than section E.5 to pair players without colour preferences.
      tournament.players[31].stub(colour_preference: :white)
      tournament.players[55].stub(colour_preference: :black)

      tournament.pair_numbers.should eq [[24, 1], [25, 3], [26, 7], [27, 9], [28, 11], [12, 29], [30, 13], [33, 15], [16, 31], [35, 17], [18, 38], [41, 19], [74, 21], [22, 44], [77, 23], [4, 59], [6, 46], [10, 47], [14, 55], [32, 56], [65, 40], [67, 42], [2, 51], [60, 5], [8, 61], [20, 62], [37, 63], [39, 64], [43, 66], [45, 68], [48, 69], [70, 49], [52, 71], [72, 53], [54, 73], [76, 57], [58, 75]]
      tournament.current_round.bye.should be nil

      tournament.finish_round(
        %w[0 0 0 0 ½ 0 0 1 1 0 1 ½ ½ 1 0 1 1 1 1 1 0 0 1 0 1 1 1 1 1 1 0i 0 1 1 1 0 1]
      )

      tournament.players[31].unstub(:colour_preference)
      tournament.players[55].unstub(:colour_preference)

      # Third round
      tournament.add_late_entry(late_entry(41))
      tournament.non_paired_numbers = [28, 33, 35, 59, 63, 67, 69, 78]
      tournament.start_round

      tournament.pair_numbers.should eq [[1, 16], [3, 17], [7, 18], [9, 22], [13, 23], [29, 6], [4, 32], [40, 10], [11, 36], [43, 14], [19, 75], [21, 42], [39, 2], [5, 44], [38, 8], [41, 12], [15, 46], [45, 20], [50, 24], [53, 25], [55, 26], [58, 27], [60, 30], [31, 70], [73, 37], [56, 34], [48, 66], [51, 68], [57, 52], [49, 47], [54, 71], [72, 61], [62, 74], [64, 76], [65, 77]]
      tournament.current_round.bye.should be nil

      tournament.finish_round(
        %w[1 ½ 1 1 1 0 1 0 1 ½ 0 ½ 0 1 0 0 ½ 0 0 0 0 1 1 1 0 0 1 1 0 0 0i 1 1 1 1]
      )

      # Fourth round
      tournament.non_paired_numbers = [15, 19, 21, 28, 41, 54, 65, 74]
      tournament.start_round

      tournament.pair_numbers.should eq [[9, 1], [13, 7], [75, 3], [17, 4], [6, 11], [10, 33], [2, 24], [26, 5], [8, 25], [12, 31], [14, 29], [16, 37], [18, 42], [20, 43], [22, 58], [23, 60], [32, 48], [34, 51], [47, 35], [36, 59], [52, 40], [46, 78], [27, 53], [30, 55], [62, 38], [64, 39], [44, 72], [71, 45], [70, 50], [63, 73], [67, 56], [68, 57], [69, 66], [76, 49], [61, 77]]
      tournament.current_round.bye.should be nil

      tournament.finish_round(
        %w[0 0 0 1 0 1 1 0 0 1 0 ½ ½ 0 ½ 1 1 1 1 1 1 1 ½ 1 0 0 1 0 0 1 ½ 0 1 0 1]
      )

      # Fifth round
      tournament.non_paired_numbers = [5, 19, 21, 36, 44, 52, 59, 65, 77, 78]
      tournament.start_round

      tournament.pair_numbers.should eq [[1, 7], [3, 10], [11, 17], [23, 2], [25, 9], [43, 12], [29, 13], [4, 34], [33, 6], [42, 16], [37, 18], [46, 22], [47, 28], [58, 32], [24, 75], [31, 8], [38, 14], [39, 15], [50, 20], [60, 26], [45, 30], [51, 27], [35, 53], [57, 40], [63, 41], [48, 69], [49, 64], [55, 67], [56, 71], [73, 61], [72, 62], [54, 70], [74, 68], [66, 76]]
      tournament.current_round.bye.should be nil

      tournament.finish_round(
        %w[0 1 0 0 0 0 0 1 0 1 1 0 0 1 1 0 1 0 ½ 1 1 0 0 0 ½ 1 1 1 1 1 1 1 1 0]
      )

      # Sixth round
      tournament.non_paired_numbers = [5, 9, 12, 14, 15, 19, 32, 33, 35, 44, 48, 49, 56, 62, 66, 67, 72, { 76 => 1 }]
      tournament.start_round

      tournament.pair_numbers.should eq [[7, 3], [17, 1], [2, 13], [22, 4], [6, 28], [10, 58], [37, 11], [42, 23], [8, 36], [38, 21], [24, 43], [25, 45], [52, 29], [16, 60], [18, 46], [20, 47], [75, 27], [53, 34], [40, 50], [26, 63], [59, 31], [78, 39], [41, 73], [65, 55], [30, 51], [69, 54], [74, 57], [61, 70], [71, 64], [77, 68]]
      tournament.current_round.bye.should be nil

      tournament.finish_round(
        %w[½ 0 1 ½ 0 1 0 0 1 0 ½ 0 0 1 1 1 0 1 1 1 0 1 1 1 1 0 0 1 1 0]
      )

      # Seventh round
      tournament.non_paired_numbers = [
        { 5 => 0, 14 => 0, 49 => 0, 64 => 1, 67 => 0, 74 => 0 }
      ]
      tournament.start_round

      tournament.pair_numbers.should eq [[7, 2], [1, 3], [11, 9], [28, 10], [12, 17], [4, 23], [29, 8], [13, 22], [21, 45], [27, 6], [15, 37], [40, 16], [43, 18], [20, 42], [58, 24], [53, 19], [44, 25], [26, 38], [48, 30], [31, 52], [32, 65], [60, 33], [36, 78], [34, 41], [46, 56], [57, 47], [50, 72], [54, 75], [63, 35], [39, 59], [55, 71], [76, 61], [68, 73], [51, 62], [70, 69], [77, 66]]
      tournament.current_round.bye.should be nil

      tournament.finish_round(
        %w[0 ½ 1 ½ ½ 1 0 1 ½ 0 1 ½ ½ 0 ½ 0 0 1 0 ½ 0i 0 1 1 1 0 1 0 1 1 0 0i 1 ½ 0 1]
      )

      # Eight round
      tournament.non_paired_numbers = [14, 21, 26, 28, 51, 63]
      tournament.start_round
      tournament.pair_numbers.should eq [[2, 1], [3, 11], [8, 7], [10, 12], [17, 13], [6, 4], [9, 42], [45, 15], [5, 29], [16, 36], [18, 40], [30, 19], [22, 43], [23, 58], [24, 65], [33, 25], [52, 20], [47, 27], [75, 31], [34, 46], [37, 53], [32, 50], [61, 38], [41, 60], [71, 44], [78, 48], [49, 39], [72, 54], [56, 68], [69, 57], [64, 35], [73, 55], [62, 76], [59, 74], [67, 77], [66, 70]]
      tournament.current_round.bye.should be nil
    end
  end
end
