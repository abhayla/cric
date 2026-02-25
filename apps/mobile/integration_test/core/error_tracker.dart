/// Tracks errors during test execution.
///
/// On first error, logs where it stopped so the test can be resumed.
library;

class ErrorTracker {
  final List<String> errors = [];
  String? lastSuccessfulStep;
  int matchesCompleted = 0;
  int teamsCreated = 0;

  void recordSuccess(String step) {
    lastSuccessfulStep = step;
  }

  void recordTeamCreated(String teamName) {
    teamsCreated++;
    lastSuccessfulStep = 'Team created: $teamName ($teamsCreated total)';
  }

  void recordMatchCompleted(String description) {
    matchesCompleted++;
    lastSuccessfulStep = 'Match $matchesCompleted: $description';
  }

  void recordError(String step, Object error) {
    final msg = '[ERROR at $step] $error';
    errors.add(msg);
    print('\n${'=' * 60}');
    print('TEST STOPPED — ERROR DETECTED');
    print('Step: $step');
    print('Error: $error');
    print('Last successful step: $lastSuccessfulStep');
    print('Teams created: $teamsCreated');
    print('Matches completed: $matchesCompleted');
    print('${'=' * 60}\n');
  }

  bool get hasError => errors.isNotEmpty;

  void printSummary() {
    print('\n=== ERROR TRACKER SUMMARY ===');
    print('Teams created: $teamsCreated');
    print('Matches completed: $matchesCompleted');
    print('Last successful step: $lastSuccessfulStep');
    if (errors.isNotEmpty) {
      print('Errors (${errors.length}):');
      for (final e in errors) {
        print('  $e');
      }
    } else {
      print('No errors.');
    }
  }
}
