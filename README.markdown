Swissfork
=========

Swissfork is a library to manage tournaments using the Swiss pairing system.

It currently offers a basic API to create tournaments and generate pairings. The test tournaments specs (found under spec/swissfork/tournaments/) show simple ways to manage a tournament.

Only one pairing algorithm is implemented so far, the [FIDE Dutch System](http://www.fide.com/fide/handbook.html?id=170&view=article).

Swissfork's development is still in alpha stage and its use in professional tournaments is not recommended.

About the Dutch System algorithm
--------------------------------

The 2016 revision of FIDE Dutch System simplifies the algorithm explanations by reducing the number of mathematical calculations and parameter definitions. It also removes the concept of backtracking to the previous bracket by introducing the completion criteria in the penultimate bracket.

However, it still shares drawbacks with its predecessor. Particularly, it suggests trying all possible combinations until we find the best one, making the algorithm O(n!) and impractical to implement.

Swissfork tries to implement the algorithm as faithfully as possible, producing the same results, but improving its performance.

Some of the differences are:

1. Swissfork doesn't use transpositions the way they're described in D.1. Instead, it pairs the first player in S1 with the first *compatible* opponent in S2, and keeps doing the same with the rest of the players in S1. This method leads to the same results we would generate by using transpositions.
2. In order to avoid millions of exchanges looking for a perfect candidate which might not exist, Swissfork tries to calculate in advance the best possible pair quality which can be obtained in a bracket.
3. The document provided by FIDE mentions the Collapsed Last Bracket, but it doesn't say how to pair it. It can't be paired like a heterogeneous bracket because some moved down players will be paired against each other, and it can't be paired like a homogeneous bracket because moved down players need to be paired first. Swissfork solves this issue by applying the Completion Criterion (C.4) to every bracket, not just the penultimate one.

However, Swissfork doesn't currently offer a practical solution in some edge cases. For example, in tournaments with many rounds where all matches end in a draw, there could be situations where we need to exchange a dozen players in order to find a perfect candidate. A weighted matching implementation will probably be added to overcome these issues

TODO
----

1. Import and export files coded in the FIDE Data Exchange Format.
2. Pairings checker.
3. Tie-break systems and standings.
4. Refine the API.
5. Random Tournament Generator.
6. Support more pairing algorithms.
