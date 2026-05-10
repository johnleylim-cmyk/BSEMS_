import 'dart:math';

import 'package:bsems/core/bracket_generator.dart';
import 'package:bsems/core/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<BracketTeam> teams(int count) {
    return [
      for (var i = 1; i <= count; i++)
        BracketTeam(id: 'team-$i', name: 'Team $i'),
    ];
  }

  test('single elimination avoids BYE vs BYE and advances byes', () {
    final specs = BracketGenerator.generate(
      format: TournamentFormat.singleElimination,
      teams: teams(5),
      random: Random(1),
    );

    expect(
      specs.where(
        (match) => match.team1Name == 'BYE' && match.team2Name == 'BYE',
      ),
      isEmpty,
    );

    final byeMatches = specs.where(
      (match) =>
          match.round == 1 &&
          match.status == MatchStatus.completed &&
          match.winnerId != null,
    );
    expect(byeMatches.length, 3);

    final secondRound = specs.where((match) => match.round == 2).toList();
    expect(
      secondRound.any(
        (match) => match.team1Id != null || match.team2Id != null,
      ),
      isTrue,
    );
  });

  test('single elimination routes every non-final winner to a valid slot', () {
    final specs = BracketGenerator.generate(
      format: TournamentFormat.singleElimination,
      teams: teams(8),
      random: Random(1),
    );

    final specByKey = {for (final spec in specs) spec.key: spec};
    final finalRound = specs.map((match) => match.round).reduce(max);

    for (final match in specs.where((match) => match.round < finalRound)) {
      expect(
        match.nextKey,
        isNotNull,
        reason: '${match.key} has no next match',
      );
      expect(
        specByKey.containsKey(match.nextKey),
        isTrue,
        reason: '${match.key} points to an unknown next match',
      );
      expect([1, 2], contains(match.nextSlot));
    }
  });

  test('two-team double elimination routes both players to grand finals', () {
    final specs = BracketGenerator.generate(
      format: TournamentFormat.doubleElimination,
      teams: teams(2),
      random: Random(1),
    );

    final winnersFinal = specs.singleWhere(
      (match) => match.bracketType == BracketTypes.winners,
    );
    final grandFinal = specs.singleWhere(
      (match) => match.bracketType == BracketTypes.grandFinals,
    );
    final resetFinal = specs.singleWhere(
      (match) => match.bracketType == BracketTypes.grandFinalsReset,
    );

    expect(winnersFinal.nextKey, grandFinal.key);
    expect(winnersFinal.nextSlot, 1);
    expect(winnersFinal.loserNextKey, grandFinal.key);
    expect(winnersFinal.loserNextSlot, 2);
    expect(grandFinal.nextKey, resetFinal.key);
  });

  test('double elimination with byes creates no empty bye matches', () {
    final specs = BracketGenerator.generate(
      format: TournamentFormat.doubleElimination,
      teams: teams(5),
      random: Random(1),
    );

    expect(
      specs.where(
        (match) => match.team1Name == 'BYE' && match.team2Name == 'BYE',
      ),
      isEmpty,
    );
    expect(
      specs.where((match) => match.bracketType == BracketTypes.losers),
      isNotEmpty,
    );
    expect(
      specs.where((match) => match.bracketType == BracketTypes.grandFinals),
      hasLength(1),
    );
    expect(
      specs.where((match) => match.bracketType == BracketTypes.grandFinalsReset),
      hasLength(1),
    );
  });

  test('double elimination routes winners and losers through valid slots', () {
    final specs = BracketGenerator.generate(
      format: TournamentFormat.doubleElimination,
      teams: teams(8),
      random: Random(1),
    );

    final specByKey = {for (final spec in specs) spec.key: spec};
    final routedSlots = <String>{};

    void expectRoute(
      BracketMatchSpec match,
      String? targetKey,
      int? targetSlot,
      String label,
    ) {
      expect(targetKey, isNotNull, reason: '${match.key} has no $label route');
      expect(
        specByKey.containsKey(targetKey),
        isTrue,
        reason: '${match.key} points to an unknown $label target',
      );
      expect([1, 2], contains(targetSlot));
      expect(
        routedSlots.add('$targetKey:$targetSlot'),
        isTrue,
        reason: '${match.key} reuses an occupied bracket slot',
      );
    }

    for (final match in specs) {
      if (match.bracketType == BracketTypes.grandFinalsReset) {
        expect(match.nextKey, isNull);
        expect(match.loserNextKey, isNull);
        continue;
      }

      if (match.bracketType == BracketTypes.grandFinals) {
        expect(match.nextKey, isNotNull);
        expect(
          specByKey[match.nextKey]!.bracketType,
          BracketTypes.grandFinalsReset,
        );
      } else {
        expectRoute(match, match.nextKey, match.nextSlot, 'winner');
      }

      if (match.bracketType == BracketTypes.winners) {
        expectRoute(match, match.loserNextKey, match.loserNextSlot, 'loser');
      } else {
        expect(match.loserNextKey, isNull);
        expect(match.loserNextSlot, isNull);
      }
    }
  });

  test('round robin creates every matchup once across rounds', () {
    final specs = BracketGenerator.generate(
      format: TournamentFormat.roundRobin,
      teams: teams(5),
      random: Random(1),
    );

    expect(specs, hasLength(10));
    expect(
      specs.every((match) => match.bracketType == BracketTypes.roundRobin),
      isTrue,
    );

    final pairKeys = specs.map((match) {
      final ids = [match.team1Id!, match.team2Id!]..sort();
      return ids.join(':');
    }).toSet();
    expect(pairKeys, hasLength(10));
  });
}
