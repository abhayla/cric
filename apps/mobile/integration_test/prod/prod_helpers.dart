/// Shared utilities for production E2E tests.
///
/// Unlike test-environment helpers that use `/api/v1/test/*` endpoints,
/// these helpers use **regular authenticated prod API endpoints** to create
/// teams, tournaments, and manage fixtures. Data is never deleted.
library;

import 'dart:math';

import 'package:cricscores/src/core/constants/app_constants.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cricscores/src/features/scoring/presentation/widgets/innings_transition_modal.dart';
import 'package:cricscores/src/features/scoring/presentation/widgets/match_complete_modal.dart';

import '../helpers/data_generators.dart';
import '../helpers/delivery_record.dart';
import '../helpers/match_flow_helpers.dart';
import '../helpers/tournament_flow_helpers.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Constants — 16 Teams, 96 Players
// ═══════════════════════════════════════════════════════════════════════════

/// All 16 team definitions with 6 players each.
final List<TeamData> prodTeams = [
  TeamData(name: 'Bangalore Titans', players: [
    PlayerData(name: 'Rajesh Kumar', role: 'all_rounder'),
    PlayerData(name: 'Amit Sharma', role: 'all_rounder'),
    PlayerData(name: 'Vikram Singh', role: 'all_rounder'),
    PlayerData(name: 'Sanjay Reddy', role: 'all_rounder'),
    PlayerData(name: 'Ravi Yadav', role: 'all_rounder'),
    PlayerData(name: 'Suresh Menon', role: 'all_rounder'),
  ]),
  TeamData(name: 'Hyderabad Kings', players: [
    PlayerData(name: 'Arjun Rao', role: 'all_rounder'),
    PlayerData(name: 'Nikhil Verma', role: 'all_rounder'),
    PlayerData(name: 'Vinay Kulkarni', role: 'all_rounder'),
    PlayerData(name: 'Harish Shetty', role: 'all_rounder'),
    PlayerData(name: 'Ajay Chauhan', role: 'all_rounder'),
    PlayerData(name: 'Tarun Bhat', role: 'all_rounder'),
  ]),
  TeamData(name: 'Mumbai Warriors', players: [
    PlayerData(name: 'Rohan Patil', role: 'all_rounder'),
    PlayerData(name: 'Aditya Joshi', role: 'all_rounder'),
    PlayerData(name: 'Pranav Desai', role: 'all_rounder'),
    PlayerData(name: 'Kunal Sawant', role: 'all_rounder'),
    PlayerData(name: 'Sachin Tendulkar Jr', role: 'all_rounder'),
    PlayerData(name: 'Yash Bhosale', role: 'all_rounder'),
  ]),
  TeamData(name: 'Chennai Strikers', players: [
    PlayerData(name: 'Karthik Iyer', role: 'all_rounder'),
    PlayerData(name: 'Ashwin Rajan', role: 'all_rounder'),
    PlayerData(name: 'Varun Chakravarthy', role: 'all_rounder'),
    PlayerData(name: 'Deepak Natarajan', role: 'all_rounder'),
    PlayerData(name: 'Ganesh Subramanian', role: 'all_rounder'),
    PlayerData(name: 'Surya Narayanan', role: 'all_rounder'),
  ]),
  TeamData(name: 'Delhi Dynamos', players: [
    PlayerData(name: 'Mohit Taneja', role: 'all_rounder'),
    PlayerData(name: 'Virat Kohli Jr', role: 'all_rounder'),
    PlayerData(name: 'Shubham Gill Jr', role: 'all_rounder'),
    PlayerData(name: 'Naveen Dhaliwal', role: 'all_rounder'),
    PlayerData(name: 'Ishant Mehra', role: 'all_rounder'),
    PlayerData(name: 'Prithvi Chahar', role: 'all_rounder'),
  ]),
  TeamData(name: 'Kolkata Knights', players: [
    PlayerData(name: 'Sourav Ghosh', role: 'all_rounder'),
    PlayerData(name: 'Anirban Das', role: 'all_rounder'),
    PlayerData(name: 'Debashish Roy', role: 'all_rounder'),
    PlayerData(name: 'Subhajit Mondal', role: 'all_rounder'),
    PlayerData(name: 'Rishav Chatterjee', role: 'all_rounder'),
    PlayerData(name: 'Arko Banerjee', role: 'all_rounder'),
  ]),
  TeamData(name: 'Pune Gladiators', players: [
    PlayerData(name: 'Aniket Kulkarni', role: 'all_rounder'),
    PlayerData(name: 'Siddharth Pawar', role: 'all_rounder'),
    PlayerData(name: 'Rohit Kale', role: 'all_rounder'),
    PlayerData(name: 'Tejas Deshpande', role: 'all_rounder'),
    PlayerData(name: 'Omkar Shinde', role: 'all_rounder'),
    PlayerData(name: 'Pratik Jadhav', role: 'all_rounder'),
  ]),
  TeamData(name: 'Jaipur Royals', players: [
    PlayerData(name: 'Manish Shekhawat', role: 'all_rounder'),
    PlayerData(name: 'Yuvraj Rathore', role: 'all_rounder'),
    PlayerData(name: 'Lalit Yadav Jr', role: 'all_rounder'),
    PlayerData(name: 'Hemant Sharma', role: 'all_rounder'),
    PlayerData(name: 'Divyanshu Meena', role: 'all_rounder'),
    PlayerData(name: 'Rahul Chahar Jr', role: 'all_rounder'),
  ]),
  TeamData(name: 'Lucknow Lions', players: [
    PlayerData(name: 'Aman Mishra', role: 'all_rounder'),
    PlayerData(name: 'Shivam Tiwari', role: 'all_rounder'),
    PlayerData(name: 'Abhishek Pandey', role: 'all_rounder'),
    PlayerData(name: 'Rajan Srivastava', role: 'all_rounder'),
    PlayerData(name: 'Gaurav Awasthi', role: 'all_rounder'),
    PlayerData(name: 'Vivek Dubey', role: 'all_rounder'),
  ]),
  TeamData(name: 'Ahmedabad Avengers', players: [
    PlayerData(name: 'Parth Patel', role: 'all_rounder'),
    PlayerData(name: 'Darshan Shah', role: 'all_rounder'),
    PlayerData(name: 'Jignesh Mistry', role: 'all_rounder'),
    PlayerData(name: 'Chirag Thakkar', role: 'all_rounder'),
    PlayerData(name: 'Ketan Bhatt', role: 'all_rounder'),
    PlayerData(name: 'Mihir Raval', role: 'all_rounder'),
  ]),
  TeamData(name: 'Chandigarh Chargers', players: [
    PlayerData(name: 'Gurpreet Singh', role: 'all_rounder'),
    PlayerData(name: 'Harmanpreet Brar', role: 'all_rounder'),
    PlayerData(name: 'Jaspreet Bumrah Jr', role: 'all_rounder'),
    PlayerData(name: 'Mandeep Sandhu', role: 'all_rounder'),
    PlayerData(name: 'Ravinder Gill', role: 'all_rounder'),
    PlayerData(name: 'Tejvir Dhillon', role: 'all_rounder'),
  ]),
  TeamData(name: 'Indore Infernos', players: [
    PlayerData(name: 'Ayush Tiwari', role: 'all_rounder'),
    PlayerData(name: 'Rishabh Jain', role: 'all_rounder'),
    PlayerData(name: 'Nitin Agrawal', role: 'all_rounder'),
    PlayerData(name: 'Harsh Malviya', role: 'all_rounder'),
    PlayerData(name: 'Devendra Chouhan', role: 'all_rounder'),
    PlayerData(name: 'Rahul Patidar Jr', role: 'all_rounder'),
  ]),
  TeamData(name: 'Vizag Vikings', players: [
    PlayerData(name: 'Prashanth Reddy', role: 'all_rounder'),
    PlayerData(name: 'Sai Krishna', role: 'all_rounder'),
    PlayerData(name: 'Venkat Rao', role: 'all_rounder'),
    PlayerData(name: 'Ravi Teja', role: 'all_rounder'),
    PlayerData(name: 'Anil Kumar', role: 'all_rounder'),
    PlayerData(name: 'Sudheer Babu', role: 'all_rounder'),
  ]),
  TeamData(name: 'Kochi Tuskers', players: [
    PlayerData(name: 'Arun Lal', role: 'all_rounder'),
    PlayerData(name: 'Vishnu Nair', role: 'all_rounder'),
    PlayerData(name: 'Sreejith Menon', role: 'all_rounder'),
    PlayerData(name: 'Jobin Joseph', role: 'all_rounder'),
    PlayerData(name: 'Aswin Das', role: 'all_rounder'),
    PlayerData(name: 'Midhun Pillai', role: 'all_rounder'),
  ]),
  TeamData(name: 'Guwahati Gladiators', players: [
    PlayerData(name: 'Bikash Sarma', role: 'all_rounder'),
    PlayerData(name: 'Rajdeep Bora', role: 'all_rounder'),
    PlayerData(name: 'Pranjal Hazarika', role: 'all_rounder'),
    PlayerData(name: 'Debojit Das', role: 'all_rounder'),
    PlayerData(name: 'Manash Kalita', role: 'all_rounder'),
    PlayerData(name: 'Rituraj Gogoi', role: 'all_rounder'),
  ]),
  TeamData(name: 'Ranchi Rhinos', players: [
    PlayerData(name: 'Akash Kumar', role: 'all_rounder'),
    PlayerData(name: 'Saurabh Singh', role: 'all_rounder'),
    PlayerData(name: 'Vikash Mahto', role: 'all_rounder'),
    PlayerData(name: 'Dheeraj Tiwary', role: 'all_rounder'),
    PlayerData(name: 'Amit Oraon', role: 'all_rounder'),
    PlayerData(name: 'Pankaj Sahu', role: 'all_rounder'),
  ]),
];

/// Team names in order for easy index lookup.
final List<String> prodTeamNames = prodTeams.map((t) => t.name).toList();

// ═══════════════════════════════════════════════════════════════════════════
// Prod API Client — Authenticated, No Test Endpoints
// ═══════════════════════════════════════════════════════════════════════════

/// Authenticated API client for production endpoints.
///
/// Obtains a Firebase ID token from the currently logged-in user and
/// attaches it to every request as `Authorization: Bearer <token>`.
class ProdApiClient {
  ProdApiClient._();

  late final Dio _dio;
  String? _cachedToken;
  DateTime? _tokenExpiry;

  /// Initialize the client. Must be called after Firebase login.
  static Future<ProdApiClient> create() async {
    final client = ProdApiClient._();
    await client._init();
    return client;
  }

  Future<void> _init() async {
    final baseUrl = AppConstants.apiBaseUrl;
    print('[ProdApiClient] Using API base: $baseUrl');

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));

    // Verify connectivity
    await _getToken();
    print('[ProdApiClient] Authenticated and ready');
  }

  /// Get a fresh Firebase ID token (caches for 50 minutes).
  Future<String?> _getToken() async {
    final now = DateTime.now();
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        now.isBefore(_tokenExpiry!)) {
      return _cachedToken;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('[ProdApiClient] WARNING: No Firebase user logged in!');
      return null;
    }

    _cachedToken = await user.getIdToken(true);
    _tokenExpiry = now.add(const Duration(minutes: 50));
    return _cachedToken;
  }

  // ── Teams ────────────────────────────────────────────────────────────

  /// List all teams for the current user.
  Future<List<Map<String, dynamic>>> listTeams({int page = 1, int limit = 50}) async {
    final response = await _dio.get('/teams', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return (response.data['teams'] as List).cast<Map<String, dynamic>>();
  }

  /// Create a team. Returns the team object.
  Future<Map<String, dynamic>> createTeam(String name) async {
    final response = await _dio.post('/teams', data: {'name': name});
    return response.data['team'] as Map<String, dynamic>;
  }

  /// Get team detail including roster.
  Future<Map<String, dynamic>> getTeam(String teamId) async {
    final response = await _dio.get('/teams/$teamId');
    return response.data as Map<String, dynamic>;
  }

  /// Add a player to a team roster. Returns the roster entry.
  Future<Map<String, dynamic>> addPlayerToTeam(
    String teamId,
    String playerId, {
    String? role,
  }) async {
    final response = await _dio.post('/teams/$teamId/players', data: {
      'playerId': playerId,
      'role': role,
    });
    return response.data['rosterEntry'] as Map<String, dynamic>;
  }

  // ── Players ──────────────────────────────────────────────────────────

  /// Create a player. Returns the player object.
  Future<Map<String, dynamic>> createPlayer(
    String displayName, {
    String? playerRole,
    String? phone,
  }) async {
    final response = await _dio.post('/players', data: {
      'displayName': displayName,
      if (playerRole != null) 'playerRole': playerRole,
      if (phone != null) 'phone': phone,
    });
    return response.data['player'] as Map<String, dynamic>;
  }

  // ── Tournaments ──────────────────────────────────────────────────────

  /// Create a tournament. Returns the tournament object.
  Future<Map<String, dynamic>> createTournament({
    required String name,
    required String format,
    required int oversPerMatch,
    int ballTypeId = 2,
    int playersPerSide = 6,
    int numGroups = 1,
    int qualifyPerGroup = 2,
    int wideRuns = 1,
    int noBallRuns = 1,
  }) async {
    final response = await _dio.post('/tournaments', data: {
      'name': name,
      'format': format,
      'oversPerMatch': oversPerMatch,
      'ballTypeId': ballTypeId,
      'playersPerSide': playersPerSide,
      'numGroups': numGroups,
      'qualifyPerGroup': qualifyPerGroup,
      'wideRuns': wideRuns,
      'noBallRuns': noBallRuns,
    });
    return response.data['tournament'] as Map<String, dynamic>;
  }

  /// List tournaments.
  Future<List<Map<String, dynamic>>> listTournaments({int page = 1, int limit = 50}) async {
    final response = await _dio.get('/tournaments', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return (response.data['tournaments'] as List).cast<Map<String, dynamic>>();
  }

  /// Add a team to a tournament.
  Future<void> addTeamToTournament(
    String tournamentId,
    String teamId, {
    String? groupName,
  }) async {
    await _dio.post('/tournaments/$tournamentId/teams', data: {
      'teamId': teamId,
      if (groupName != null) 'groupName': groupName,
    });
  }

  /// Transition tournament status.
  Future<void> updateTournamentStatus(String tournamentId, String status) async {
    await _dio.put('/tournaments/$tournamentId/status', data: {
      'status': status,
    });
  }

  /// Generate fixtures.
  Future<List<Map<String, dynamic>>> generateFixtures(String tournamentId) async {
    final response = await _dio.post('/tournaments/$tournamentId/fixtures/generate');
    return (response.data['fixtures'] as List).cast<Map<String, dynamic>>();
  }

  /// Get fixtures for a tournament.
  Future<List<Map<String, dynamic>>> getFixtures(
    String tournamentId, {
    String? roundType,
    String? groupName,
  }) async {
    final response = await _dio.get(
      '/tournaments/$tournamentId/fixtures',
      queryParameters: {
        if (roundType != null) 'roundType': roundType,
        if (groupName != null) 'groupName': groupName,
      },
    );
    return (response.data['fixtures'] as List).cast<Map<String, dynamic>>();
  }

  /// Get tournament standings.
  Future<List<Map<String, dynamic>>> getStandings(
    String tournamentId, {
    String? groupName,
  }) async {
    final response = await _dio.get(
      '/tournaments/$tournamentId/standings',
      queryParameters: {
        if (groupName != null) 'groupName': groupName,
      },
    );
    return (response.data['standings'] as List).cast<Map<String, dynamic>>();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Team Setup via UI
// ═══════════════════════════════════════════════════════════════════════════

/// Create all 16 teams via UI navigation.
///
/// Uses the existing `createTeam` and `addPlayersToRoster` helpers from
/// tournament_flow_helpers.dart. Skips teams that already exist (checks
/// by navigating to Teams tab and looking for the name).
Future<void> createAllTeamsViaUI(WidgetTester tester) async {
  for (var i = 0; i < prodTeams.length; i++) {
    final team = prodTeams[i];
    print('\n[TEAM ${i + 1}/${prodTeams.length}] Creating: ${team.name}');

    // Navigate to Teams tab
    await navigateToTeams(tester);
    await settle(tester);

    // Check if team already exists (scroll through list)
    final existing = find.text(team.name);
    if (existing.evaluate().isNotEmpty) {
      print('  [SKIP] ${team.name} already exists');
      continue;
    }

    // Create team
    await createTeam(tester, team);

    // Add players to roster (we're now on Team Detail page)
    await addPlayersToRoster(tester, team.players);

    // Navigate back to teams list for next iteration
    await goBack(tester);
    await settle(tester);

    print('  [DONE] ${team.name} created with ${team.players.length} players');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tournament Fixture Scoring via UI
// ═══════════════════════════════════════════════════════════════════════════

/// Group assignments for 4 groups x 4 teams (T1, T2).
const Map<String, List<int>> fourGroupAssignments = {
  'A': [0, 1, 2, 3],     // Bangalore, Hyderabad, Mumbai, Chennai
  'B': [4, 5, 6, 7],     // Delhi, Kolkata, Pune, Jaipur
  'C': [8, 9, 10, 11],   // Lucknow, Ahmedabad, Chandigarh, Indore
  'D': [12, 13, 14, 15], // Vizag, Kochi, Guwahati, Ranchi
};

/// Group assignments for 2 groups x 8 teams (T5).
const Map<String, List<int>> twoGroupAssignments = {
  'A': [0, 1, 2, 3, 4, 5, 6, 7],
  'B': [8, 9, 10, 11, 12, 13, 14, 15],
};

/// Create a tournament via API, add teams with groups, generate fixtures.
/// Returns the tournament ID.
Future<String> setupTournamentViaApi({
  required ProdApiClient api,
  required String name,
  required String format,
  required int oversPerMatch,
  int ballTypeId = 2,
  int playersPerSide = 6,
  int numGroups = 1,
  int qualifyPerGroup = 2,
  Map<String, List<int>>? groupAssignments,
  List<int>? teamIndices,
}) async {
  print('\n[TOURNAMENT SETUP] $name ($format, ${oversPerMatch}ov)');

  // 1. Create tournament
  final tournament = await api.createTournament(
    name: name,
    format: format,
    oversPerMatch: oversPerMatch,
    ballTypeId: ballTypeId,
    playersPerSide: playersPerSide,
    numGroups: numGroups,
    qualifyPerGroup: qualifyPerGroup,
  );
  final tournamentId = tournament['id'] as String;
  print('  Created tournament: $tournamentId');

  // 2. Get team IDs by listing user's teams and matching names
  final allTeams = await api.listTeams(limit: 50);
  final teamNameToId = <String, String>{};
  for (final team in allTeams) {
    teamNameToId[team['name'] as String] = team['id'] as String;
  }

  // 3. Add teams with group assignments
  if (groupAssignments != null) {
    for (final entry in groupAssignments.entries) {
      final groupName = entry.key;
      for (final teamIdx in entry.value) {
        final teamName = prodTeamNames[teamIdx];
        final teamId = teamNameToId[teamName];
        if (teamId == null) {
          print('  WARNING: Team "$teamName" not found! Skipping.');
          continue;
        }
        await api.addTeamToTournament(tournamentId, teamId, groupName: groupName);
        print('  Added $teamName to Group $groupName');
      }
    }
  } else if (teamIndices != null) {
    for (final teamIdx in teamIndices) {
      final teamName = prodTeamNames[teamIdx];
      final teamId = teamNameToId[teamName];
      if (teamId == null) {
        print('  WARNING: Team "$teamName" not found! Skipping.');
        continue;
      }
      await api.addTeamToTournament(tournamentId, teamId);
      print('  Added $teamName');
    }
  } else {
    // Add all 16 teams (no groups)
    for (var i = 0; i < prodTeamNames.length; i++) {
      final teamName = prodTeamNames[i];
      final teamId = teamNameToId[teamName];
      if (teamId != null) {
        await api.addTeamToTournament(tournamentId, teamId);
        print('  Added $teamName');
      }
    }
  }

  // 4. Transition to registration then live
  await api.updateTournamentStatus(tournamentId, 'registration');
  print('  Status: draft -> registration');

  // 5. Generate fixtures
  final fixtures = await api.generateFixtures(tournamentId);
  print('  Generated ${fixtures.length} fixtures');

  // 6. Transition to live
  await api.updateTournamentStatus(tournamentId, 'live');
  print('  Status: registration -> live');

  return tournamentId;
}

/// Score all fixtures in a tournament via UI.
///
/// For each fixture:
/// 1. Navigate to tournament > Fixtures tab > tap fixture
/// 2. Match Setup > Proceed to Toss
/// 3. Random toss winner/decision
/// 4. Auto-select playing XI (6 = roster size)
/// 5. Select openers + bowler
/// 6. Score both innings with random deliveries
/// 7. Match complete > back to tournament
Future<void> scoreAllFixtures({
  required WidgetTester tester,
  required ProdApiClient api,
  required String tournamentId,
  required int totalOvers,
  int playersPerSide = 6,
  Random? random,
}) async {
  final rng = random ?? Random();

  // Get all fixtures
  final fixtures = await api.getFixtures(tournamentId);
  final pendingFixtures = fixtures
      .where((f) => f['matchId'] == null) // Only unplayed fixtures
      .toList();

  print('\n[SCORING] ${pendingFixtures.length} fixtures to play '
      '(${fixtures.length} total)');

  for (var i = 0; i < pendingFixtures.length; i++) {
    final fixture = pendingFixtures[i];
    final homeTeam = fixture['homeTeamName'] as String? ?? 'TBD';
    final awayTeam = fixture['awayTeamName'] as String? ?? 'TBD';
    final roundType = fixture['roundType'] as String? ?? 'group';

    // Skip fixtures with TBD teams (knockout rounds where winner not yet decided)
    if (homeTeam == 'TBD' || awayTeam == 'TBD') {
      print('\n[MATCH ${i + 1}/${pendingFixtures.length}] SKIP: $homeTeam vs $awayTeam '
          '($roundType) — waiting for results');
      continue;
    }

    print('\n[MATCH ${i + 1}/${pendingFixtures.length}] $homeTeam vs $awayTeam '
        '($roundType)');

    // Play this fixture via UI
    await _playFixtureViaUI(
      tester: tester,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      totalOvers: totalOvers,
      playersPerSide: playersPerSide,
      random: rng,
    );

    print('  [COMPLETE] Match ${i + 1} done');

    // After playing group matches, re-fetch fixtures to get updated
    // knockout fixtures with resolved team names
    if (i < pendingFixtures.length - 1) {
      final updated = await api.getFixtures(tournamentId);
      final remaining = updated.where((f) => f['matchId'] == null).toList();
      // Update pendingFixtures with resolved team names
      for (var j = i + 1; j < pendingFixtures.length; j++) {
        final fixId = pendingFixtures[j]['id'];
        final resolved = remaining.firstWhere(
          (f) => f['id'] == fixId,
          orElse: () => pendingFixtures[j],
        );
        pendingFixtures[j] = resolved;
      }
    }
  }

  // Re-check: there may be new knockout fixtures now
  final allFixtures = await api.getFixtures(tournamentId);
  final stillPending = allFixtures.where((f) => f['matchId'] == null).toList();
  if (stillPending.isNotEmpty) {
    print('\n[SCORING] ${stillPending.length} more fixtures resolved after group stage');
    for (var i = 0; i < stillPending.length; i++) {
      final fixture = stillPending[i];
      final homeTeam = fixture['homeTeamName'] as String? ?? 'TBD';
      final awayTeam = fixture['awayTeamName'] as String? ?? 'TBD';
      final roundType = fixture['roundType'] as String? ?? 'knockout';

      if (homeTeam == 'TBD' || awayTeam == 'TBD') {
        print('\n[KNOCKOUT ${i + 1}] SKIP: $homeTeam vs $awayTeam — TBD');
        continue;
      }

      print('\n[KNOCKOUT ${i + 1}/${stillPending.length}] $homeTeam vs $awayTeam '
          '($roundType)');

      await _playFixtureViaUI(
        tester: tester,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        totalOvers: totalOvers,
        playersPerSide: playersPerSide,
        random: rng,
      );

      print('  [COMPLETE] Knockout match ${i + 1} done');
    }

    // Final check for any remaining (e.g., final after semis)
    final finalCheck = await api.getFixtures(tournamentId);
    final remaining = finalCheck.where((f) => f['matchId'] == null).toList();
    for (final f in remaining) {
      final home = f['homeTeamName'] as String? ?? 'TBD';
      final away = f['awayTeamName'] as String? ?? 'TBD';
      if (home == 'TBD' || away == 'TBD') continue;

      print('\n[FINAL] $home vs $away');
      await _playFixtureViaUI(
        tester: tester,
        homeTeam: home,
        awayTeam: away,
        totalOvers: totalOvers,
        playersPerSide: playersPerSide,
        random: rng,
      );
    }
  }
}

/// Play a single fixture through the UI.
Future<void> _playFixtureViaUI({
  required WidgetTester tester,
  required String homeTeam,
  required String awayTeam,
  required int totalOvers,
  required int playersPerSide,
  required Random random,
}) async {
  // 1. Navigate to fixture and tap it
  await tapFixtureCard(tester, homeTeamName: homeTeam, awayTeamName: awayTeam);
  await settle(tester);

  // 2. Complete match setup (teams pre-selected from fixture)
  await completeMatchSetup(tester);

  // 3. Random toss: pick winner and decision
  final tossWinner = random.nextBool() ? homeTeam : awayTeam;
  final chooseBat = random.nextBool();
  final battingTeam = chooseBat ? tossWinner : (tossWinner == homeTeam ? awayTeam : homeTeam);
  final bowlingTeam = battingTeam == homeTeam ? awayTeam : homeTeam;

  // Get player names for batting and bowling teams
  final battingTeamData = prodTeams.firstWhere((t) => t.name == battingTeam);
  final bowlingTeamData = prodTeams.firstWhere((t) => t.name == bowlingTeam);

  final opener1 = battingTeamData.players[0].name;
  final opener2 = battingTeamData.players[1].name;
  final openingBowler = bowlingTeamData.players[0].name;

  print('  Toss: $tossWinner wins, chooses to ${chooseBat ? "Bat" : "Field"}');
  print('  Batting: $battingTeam ($opener1, $opener2)');
  print('  Bowling: $bowlingTeam ($openingBowler)');

  // 4. Complete toss wizard
  await completeTossWizard(
    tester,
    tossWinnerName: tossWinner,
    battingOpener1: opener1,
    battingOpener2: opener2,
    openingBowler: openingBowler,
    playersPerSide: playersPerSide,
    chooseBat: chooseBat,
  );

  // 5. Score first innings
  final matchRecord = MatchRecord(matchId: 'fixture');
  final bowlingPlayerNames = bowlingTeamData.players.map((p) => p.name).toList();
  final battingPlayerNames = battingTeamData.players.map((p) => p.name).toList();

  print('  [Innings 1] $battingTeam batting...');
  await playRandomInnings(
    tester: tester,
    matchRecord: matchRecord,
    inningsNumber: 1,
    totalOvers: totalOvers,
    playersPerSide: playersPerSide,
    bowlerNames: bowlingPlayerNames,
    batterNames: battingPlayerNames,
    random: random,
  );
  print('  [Innings 1] ${matchRecord.firstInningsRuns}/${matchRecord.firstInningsWickets}');

  // 6. Handle innings transition
  await settle(tester);
  final transitionModal = find.byType(InningsTransitionModal);
  if (transitionModal.evaluate().isNotEmpty) {
    // Second innings: bowling team now bats
    final inn2Opener1 = bowlingTeamData.players[0].name;
    final inn2Opener2 = bowlingTeamData.players[1].name;
    final inn2Bowler = battingTeamData.players[0].name;

    await completeInningsTransition(
      tester,
      striker: inn2Opener1,
      nonStriker: inn2Opener2,
      bowler: inn2Bowler,
    );

    // 7. Score second innings
    final battingPlayerNames2 = bowlingTeamData.players.map((p) => p.name).toList();
    final bowlingPlayerNames2 = battingTeamData.players.map((p) => p.name).toList();

    print('  [Innings 2] $bowlingTeam batting (target: ${matchRecord.firstInningsRuns + 1})...');
    await playRandomInnings(
      tester: tester,
      matchRecord: matchRecord,
      inningsNumber: 2,
      totalOvers: totalOvers,
      playersPerSide: playersPerSide,
      bowlerNames: bowlingPlayerNames2,
      batterNames: battingPlayerNames2,
      random: random,
    );
    print('  [Innings 2] ${matchRecord.secondInningsRuns}/${matchRecord.secondInningsWickets}');
  }

  // 8. Handle match complete modal
  await settle(tester);
  await _dismissMatchCompleteModal(tester);

  // 9. Navigate back to tournament
  await navigateToHome(tester);
  await settle(tester);

  // Navigate back to tournament page
  await navigateToTournaments(tester);
  await settle(tester);

  print('  Result: ${matchRecord.firstInningsRuns}/${matchRecord.firstInningsWickets} '
      'vs ${matchRecord.secondInningsRuns}/${matchRecord.secondInningsWickets}');
}

/// Dismiss the match complete modal (may have "View Scorecard" or "Back to Home").
Future<void> _dismissMatchCompleteModal(WidgetTester tester) async {
  // Wait for MatchCompleteModal to appear
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byType(MatchCompleteModal).evaluate().isNotEmpty) break;
  }

  if (find.byType(MatchCompleteModal).evaluate().isEmpty) {
    // Modal didn't appear — match may have ended differently
    print('    [matchComplete] No MatchCompleteModal found');
    return;
  }

  // Try "Back to Home" first
  final backHome = find.text('Back to Home');
  if (backHome.evaluate().isNotEmpty) {
    await tester.tap(backHome.first);
    await settle(tester);
    return;
  }

  // Try "Done" button
  final done = find.text('Done');
  if (done.evaluate().isNotEmpty) {
    await tester.tap(done.first);
    await settle(tester);
    return;
  }

  // Fallback: tap any FilledButton
  final buttons = find.byType(FilledButton);
  if (buttons.evaluate().isNotEmpty) {
    await tester.tap(buttons.first);
    await settle(tester);
  }
}

