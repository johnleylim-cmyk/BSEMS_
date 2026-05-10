import 'dart:math';

import 'enums.dart';

class BracketTypes {
  static const winners = 'winners';
  static const losers = 'losers';
  static const grandFinals = 'grand_finals';
  static const grandFinalsReset = 'grand_finals_reset';
  static const roundRobin = 'round_robin';
}

class BracketTeam {
  final String id;
  final String name;

  const BracketTeam({required this.id, required this.name});
}

class BracketMatchSpec {
  final String key;
  final int round;
  final int matchNumber;
  final String? bracketType;
  String? team1Id;
  String? team2Id;
  String? team1Name;
  String? team2Name;
  int score1;
  int score2;
  String? winnerId;
  MatchStatus status;
  String? nextKey;
  int? nextSlot;
  String? loserNextKey;
  int? loserNextSlot;

  BracketMatchSpec({
    required this.key,
    required this.round,
    required this.matchNumber,
    required this.status,
    this.bracketType,
    this.team1Id,
    this.team2Id,
    this.team1Name,
    this.team2Name,
    this.score1 = 0,
    this.score2 = 0,
    this.winnerId,
    this.nextKey,
    this.nextSlot,
    this.loserNextKey,
    this.loserNextSlot,
  });

  String? get winnerName {
    if (winnerId == null) return null;
    if (winnerId == team1Id) return team1Name;
    if (winnerId == team2Id) return team2Name;
    return null;
  }

  Map<String, dynamic> toBracketMap(
    String matchId,
    Map<String, String> idByKey,
  ) {
    return {
      'matchId': matchId,
      'round': round,
      'matchNumber': matchNumber,
      'team1Id': team1Id,
      'team2Id': team2Id,
      'team1Name': team1Name,
      'team2Name': team2Name,
      'score1': score1,
      'score2': score2,
      'winnerId': winnerId,
      'status': status.name,
      'bracketType': bracketType,
      'nextMatchId': nextKey == null ? null : idByKey[nextKey],
      'nextMatchSlot': nextSlot,
      'loserNextMatchId': loserNextKey == null ? null : idByKey[loserNextKey],
      'loserNextMatchSlot': loserNextSlot,
    };
  }
}

class BracketGenerator {
  static List<BracketMatchSpec> generate({
    required TournamentFormat format,
    required List<BracketTeam> teams,
    Random? random,
  }) {
    _validateTeams(teams);
    final seededTeams = List<BracketTeam>.of(teams)..shuffle(random);

    switch (format) {
      case TournamentFormat.singleElimination:
        return _generateSingleElimination(seededTeams);
      case TournamentFormat.doubleElimination:
        return _generateDoubleElimination(seededTeams);
      case TournamentFormat.roundRobin:
        return _generateRoundRobin(seededTeams);
    }
  }

  static void _validateTeams(List<BracketTeam> teams) {
    if (teams.length < 2) {
      throw ArgumentError('Need at least 2 teams to generate a bracket');
    }

    final ids = <String>{};
    for (final team in teams) {
      if (team.id.trim().isEmpty || team.name.trim().isEmpty) {
        throw ArgumentError('Every selected team must have an id and name');
      }
      if (!ids.add(team.id)) {
        throw ArgumentError('A team can only appear once in a bracket');
      }
    }
  }

  static int _nextPowerOfTwo(int value) {
    var slots = 1;
    while (slots < value) {
      slots *= 2;
    }
    return slots;
  }

  static List<({BracketTeam? team1, BracketTeam? team2})> _firstRoundPairs(
    List<BracketTeam> teams,
    int slots,
  ) {
    final byes = slots - teams.length;
    final matchCount = slots ~/ 2;
    var teamIndex = 0;
    final pairs = <({BracketTeam? team1, BracketTeam? team2})>[];

    for (var i = 0; i < matchCount; i++) {
      if (i < byes) {
        pairs.add((team1: teams[teamIndex++], team2: null));
      } else {
        pairs.add((team1: teams[teamIndex++], team2: teams[teamIndex++]));
      }
    }

    return pairs;
  }

  static List<BracketMatchSpec> _generateSingleElimination(
    List<BracketTeam> teams,
  ) {
    final slots = _nextPowerOfTwo(teams.length);
    final totalRounds = (log(slots) / log(2)).round();
    final specs = <BracketMatchSpec>[];
    final roundKeys = <List<String>>[];
    var matchNumber = 1;

    final firstRoundKeys = <String>[];
    final pairs = _firstRoundPairs(teams, slots);
    for (var i = 0; i < pairs.length; i++) {
      final pair = pairs[i];
      final isBye = pair.team1 == null || pair.team2 == null;
      final key = 'single-r1-m${i + 1}';
      specs.add(BracketMatchSpec(
        key: key,
        round: 1,
        matchNumber: matchNumber++,
        team1Id: pair.team1?.id,
        team2Id: pair.team2?.id,
        team1Name: pair.team1?.name ?? 'BYE',
        team2Name: pair.team2?.name ?? 'BYE',
        winnerId: isBye ? (pair.team1?.id ?? pair.team2?.id) : null,
        status: isBye ? MatchStatus.completed : MatchStatus.scheduled,
      ));
      firstRoundKeys.add(key);
    }
    roundKeys.add(firstRoundKeys);

    for (var round = 2; round <= totalRounds; round++) {
      final keys = <String>[];
      final matchesInRound = slots ~/ pow(2, round).toInt();
      for (var i = 0; i < matchesInRound; i++) {
        final key = 'single-r$round-m${i + 1}';
        specs.add(BracketMatchSpec(
          key: key,
          round: round,
          matchNumber: matchNumber++,
          team1Name: 'TBD',
          team2Name: 'TBD',
          status: MatchStatus.scheduled,
        ));
        keys.add(key);
      }
      roundKeys.add(keys);
    }

    _routeWinners(roundKeys, _specMap(specs));
    _applyAutoAdvancements(specs);
    return specs;
  }

  static List<BracketMatchSpec> _generateDoubleElimination(
    List<BracketTeam> teams,
  ) {
    final slots = _nextPowerOfTwo(teams.length);
    final winnersRounds = (log(slots) / log(2)).round();
    final specs = <BracketMatchSpec>[];
    final specByKey = <String, BracketMatchSpec>{};
    final winnersLoserFlows = <int, List<_Flow>>{};
    var matchNumber = 1;

    BracketMatchSpec addSpec(BracketMatchSpec spec) {
      specs.add(spec);
      specByKey[spec.key] = spec;
      return spec;
    }

    final firstRoundWinnerFlows = <_Flow>[];
    final firstRoundLoserFlows = <_Flow>[];
    final pairs = _firstRoundPairs(teams, slots);

    for (var i = 0; i < pairs.length; i++) {
      final pair = pairs[i];
      final isBye = pair.team1 == null || pair.team2 == null;
      final key = 'winners-r1-m${i + 1}';
      addSpec(BracketMatchSpec(
        key: key,
        round: 1,
        matchNumber: matchNumber++,
        bracketType: BracketTypes.winners,
        team1Id: pair.team1?.id,
        team2Id: pair.team2?.id,
        team1Name: pair.team1?.name ?? 'BYE',
        team2Name: pair.team2?.name ?? 'BYE',
        winnerId: isBye ? (pair.team1?.id ?? pair.team2?.id) : null,
        status: isBye ? MatchStatus.completed : MatchStatus.scheduled,
      ));
      firstRoundWinnerFlows.add(_Flow.winner(key));
      if (!isBye) {
        firstRoundLoserFlows.add(_Flow.loser(key));
      }
    }

    winnersLoserFlows[1] = firstRoundLoserFlows;
    var previousWinnerFlows = firstRoundWinnerFlows;

    for (var round = 2; round <= winnersRounds; round++) {
      final nextWinnerFlows = <_Flow>[];
      final loserFlows = <_Flow>[];

      for (var i = 0; i < previousWinnerFlows.length; i += 2) {
        final key = 'winners-r$round-m${(i ~/ 2) + 1}';
        _createMatchFromFlows(
          key: key,
          round: round,
          matchNumber: matchNumber++,
          bracketType: BracketTypes.winners,
          first: previousWinnerFlows[i],
          second: previousWinnerFlows[i + 1],
          addSpec: addSpec,
          specByKey: specByKey,
        );
        nextWinnerFlows.add(_Flow.winner(key));
        loserFlows.add(_Flow.loser(key));
      }

      winnersLoserFlows[round] = loserFlows;
      previousWinnerFlows = nextWinnerFlows;
    }

    final winnersChampion = previousWinnerFlows.single;
    final losersChampion = winnersRounds == 1
        ? winnersLoserFlows[1]!.single
        : _buildLosersBracket(
            winnersRounds: winnersRounds,
            firstLosers: winnersLoserFlows[1] ?? const [],
            winnersLoserFlows: winnersLoserFlows,
            initialRound: winnersRounds + 1,
            initialMatchNumber: matchNumber,
            addSpec: addSpec,
            specByKey: specByKey,
          );

    matchNumber = specs.isEmpty
        ? matchNumber
        : specs.map((spec) => spec.matchNumber).reduce(max) + 1;
    final finalsRound = specs.map((spec) => spec.round).reduce(max) + 1;
    final grandFinal = _createMatchFromFlows(
      key: 'grand-finals',
      round: finalsRound,
      matchNumber: matchNumber,
      bracketType: BracketTypes.grandFinals,
      first: winnersChampion,
      second: losersChampion,
      addSpec: addSpec,
      specByKey: specByKey,
      team1Label: 'Winners Champion',
      team2Label: 'Losers Champion',
    );
    matchNumber++;

    final resetFinal = addSpec(BracketMatchSpec(
      key: 'grand-finals-reset',
      round: finalsRound + 1,
      matchNumber: matchNumber,
      bracketType: BracketTypes.grandFinalsReset,
      team1Name: 'If Needed',
      team2Name: 'If Needed',
      status: MatchStatus.scheduled,
    ));
    grandFinal.nextKey = resetFinal.key;
    grandFinal.nextSlot = 1;

    _applyAutoAdvancements(specs);
    return specs;
  }

  static _Flow _buildLosersBracket({
    required int winnersRounds,
    required List<_Flow> firstLosers,
    required Map<int, List<_Flow>> winnersLoserFlows,
    required int initialRound,
    required int initialMatchNumber,
    required BracketMatchSpec Function(BracketMatchSpec spec) addSpec,
    required Map<String, BracketMatchSpec> specByKey,
  }) {
    var round = initialRound;
    var matchNumber = initialMatchNumber;

    var result = _playFlowRound(
      flows: firstLosers,
      round: round,
      matchNumber: matchNumber,
      keyPrefix: 'losers-r$round-',
      addSpec: addSpec,
      specByKey: specByKey,
    );
    var current = result.flows;
    if (result.createdMatches > 0) {
      round++;
      matchNumber += result.createdMatches;
    }

    for (var winnersRound = 2; winnersRound <= winnersRounds; winnersRound++) {
      final incoming = winnersLoserFlows[winnersRound] ?? const <_Flow>[];
      result = _playParallelFlows(
        firstFlows: current,
        secondFlows: incoming,
        round: round,
        matchNumber: matchNumber,
        keyPrefix: 'losers-r$round-',
        addSpec: addSpec,
        specByKey: specByKey,
      );
      current = result.flows;
      if (result.createdMatches > 0) {
        round++;
        matchNumber += result.createdMatches;
      }

      if (winnersRound < winnersRounds) {
        result = _playFlowRound(
          flows: current,
          round: round,
          matchNumber: matchNumber,
          keyPrefix: 'losers-r$round-',
          addSpec: addSpec,
          specByKey: specByKey,
        );
        current = result.flows;
        if (result.createdMatches > 0) {
          round++;
          matchNumber += result.createdMatches;
        }
      }
    }

    while (current.length > 1) {
      result = _playFlowRound(
        flows: current,
        round: round,
        matchNumber: matchNumber,
        keyPrefix: 'losers-r$round-',
        addSpec: addSpec,
        specByKey: specByKey,
      );
      current = result.flows;
      if (result.createdMatches > 0) {
        round++;
        matchNumber += result.createdMatches;
      } else {
        break;
      }
    }

    if (current.length != 1) {
      throw StateError('Could not build a valid losers bracket');
    }
    return current.single;
  }

  static _FlowRoundResult _playFlowRound({
    required List<_Flow> flows,
    required int round,
    required int matchNumber,
    required String keyPrefix,
    required BracketMatchSpec Function(BracketMatchSpec spec) addSpec,
    required Map<String, BracketMatchSpec> specByKey,
  }) {
    final nextFlows = <_Flow>[];
    var createdMatches = 0;
    var nextMatchNumber = matchNumber;

    for (var i = 0; i < flows.length; i += 2) {
      final first = flows[i];
      final second = i + 1 < flows.length ? flows[i + 1] : null;
      if (second == null) {
        nextFlows.add(first);
        continue;
      }

      final key = '$keyPrefix${createdMatches + 1}';
      _createMatchFromFlows(
        key: key,
        round: round,
        matchNumber: nextMatchNumber++,
        bracketType: BracketTypes.losers,
        first: first,
        second: second,
        addSpec: addSpec,
        specByKey: specByKey,
      );
      nextFlows.add(_Flow.winner(key));
      createdMatches++;
    }

    return _FlowRoundResult(nextFlows, createdMatches);
  }

  static _FlowRoundResult _playParallelFlows({
    required List<_Flow> firstFlows,
    required List<_Flow> secondFlows,
    required int round,
    required int matchNumber,
    required String keyPrefix,
    required BracketMatchSpec Function(BracketMatchSpec spec) addSpec,
    required Map<String, BracketMatchSpec> specByKey,
  }) {
    final nextFlows = <_Flow>[];
    var createdMatches = 0;
    var nextMatchNumber = matchNumber;
    final length = max(firstFlows.length, secondFlows.length);

    for (var i = 0; i < length; i++) {
      final first = i < firstFlows.length ? firstFlows[i] : null;
      final second = i < secondFlows.length ? secondFlows[i] : null;
      if (first == null && second == null) continue;
      if (first == null || second == null) {
        nextFlows.add(first ?? second!);
        continue;
      }

      final key = '$keyPrefix${createdMatches + 1}';
      _createMatchFromFlows(
        key: key,
        round: round,
        matchNumber: nextMatchNumber++,
        bracketType: BracketTypes.losers,
        first: first,
        second: second,
        addSpec: addSpec,
        specByKey: specByKey,
      );
      nextFlows.add(_Flow.winner(key));
      createdMatches++;
    }

    return _FlowRoundResult(nextFlows, createdMatches);
  }

  static List<BracketMatchSpec> _generateRoundRobin(List<BracketTeam> teams) {
    final competitors = <BracketTeam?>[...teams];
    if (competitors.length.isOdd) {
      competitors.add(null);
    }

    final specs = <BracketMatchSpec>[];
    var matchNumber = 1;
    final competitorCount = competitors.length;
    final half = competitorCount ~/ 2;

    for (var round = 1; round < competitorCount; round++) {
      for (var i = 0; i < half; i++) {
        final team1 = competitors[i];
        final team2 = competitors[competitorCount - 1 - i];
        if (team1 == null || team2 == null) continue;

        specs.add(BracketMatchSpec(
          key: 'round-robin-r$round-m${i + 1}',
          round: round,
          matchNumber: matchNumber++,
          bracketType: BracketTypes.roundRobin,
          team1Id: team1.id,
          team2Id: team2.id,
          team1Name: team1.name,
          team2Name: team2.name,
          status: MatchStatus.scheduled,
        ));
      }

      final fixed = competitors.first;
      final rotating = competitors.sublist(1);
      rotating.insert(0, rotating.removeLast());
      competitors
        ..clear()
        ..add(fixed)
        ..addAll(rotating);
    }

    return specs;
  }

  static void _routeWinners(
    List<List<String>> roundKeys,
    Map<String, BracketMatchSpec> specByKey,
  ) {
    for (var roundIndex = 0; roundIndex < roundKeys.length - 1; roundIndex++) {
      final currentRound = roundKeys[roundIndex];
      final nextRound = roundKeys[roundIndex + 1];
      for (var i = 0; i < currentRound.length; i++) {
        final spec = specByKey[currentRound[i]]!;
        spec.nextKey = nextRound[i ~/ 2];
        spec.nextSlot = i.isEven ? 1 : 2;
      }
    }
  }

  static BracketMatchSpec _createMatchFromFlows({
    required String key,
    required int round,
    required int matchNumber,
    required String bracketType,
    required _Flow first,
    required _Flow second,
    required BracketMatchSpec Function(BracketMatchSpec spec) addSpec,
    required Map<String, BracketMatchSpec> specByKey,
    String team1Label = 'TBD',
    String team2Label = 'TBD',
  }) {
    final spec = addSpec(BracketMatchSpec(
      key: key,
      round: round,
      matchNumber: matchNumber,
      bracketType: bracketType,
      team1Name: team1Label,
      team2Name: team2Label,
      status: MatchStatus.scheduled,
    ));

    _routeFlowToSlot(first, spec.key, 1, specByKey);
    _routeFlowToSlot(second, spec.key, 2, specByKey);
    return spec;
  }

  static void _routeFlowToSlot(
    _Flow flow,
    String targetKey,
    int targetSlot,
    Map<String, BracketMatchSpec> specByKey,
  ) {
    final source = specByKey[flow.sourceKey];
    if (source == null) {
      throw StateError('Unknown bracket source: ${flow.sourceKey}');
    }

    switch (flow.type) {
      case _FlowType.winner:
        source.nextKey = targetKey;
        source.nextSlot = targetSlot;
        break;
      case _FlowType.loser:
        source.loserNextKey = targetKey;
        source.loserNextSlot = targetSlot;
        break;
    }
  }

  static void _applyAutoAdvancements(List<BracketMatchSpec> specs) {
    final specByKey = _specMap(specs);
    for (final spec in specs) {
      if (spec.status != MatchStatus.completed || spec.winnerId == null) {
        continue;
      }
      final target = spec.nextKey == null ? null : specByKey[spec.nextKey];
      final targetSlot = spec.nextSlot;
      final name = spec.winnerName;
      if (target == null || targetSlot == null || name == null) continue;

      if (targetSlot == 1) {
        target.team1Id = spec.winnerId;
        target.team1Name = name;
      } else {
        target.team2Id = spec.winnerId;
        target.team2Name = name;
      }
    }
  }

  static Map<String, BracketMatchSpec> _specMap(List<BracketMatchSpec> specs) {
    return {for (final spec in specs) spec.key: spec};
  }
}

enum _FlowType { winner, loser }

class _Flow {
  final _FlowType type;
  final String sourceKey;

  const _Flow._(this.type, this.sourceKey);

  factory _Flow.winner(String sourceKey) {
    return _Flow._(_FlowType.winner, sourceKey);
  }

  factory _Flow.loser(String sourceKey) {
    return _Flow._(_FlowType.loser, sourceKey);
  }
}

class _FlowRoundResult {
  final List<_Flow> flows;
  final int createdMatches;

  const _FlowRoundResult(this.flows, this.createdMatches);
}
