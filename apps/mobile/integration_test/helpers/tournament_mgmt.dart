/// Tournament management helpers — create, status transitions, team assignment,
/// fixture generation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cricscores/src/features/tournaments/presentation/widgets/fixture_card.dart';

import '../config/tournament_presets.dart';
import '../core/test_utils.dart';
import 'navigation.dart';

/// Create a tournament through the UI.
///
/// After creation, lands on the Tournament Detail page (draft status).
Future<void> createTournament(
  WidgetTester tester,
  TournamentPreset preset,
  String name,
) async {
  final context = tester.element(find.byType(Navigator).last);
  GoRouter.of(context).push('/tournaments/create');
  await settle(tester);
  await visualPause(tester);

  // Fill tournament name
  final nameFields = find.byType(TextFormField);
  if (nameFields.evaluate().isNotEmpty) {
    await tester.enterText(nameFields.first, name);
    await settle(tester);
  }

  // Select format chip
  final formatLabel = switch (preset.format) {
    'group_knockout' => 'Group + KO',
    'knockout' => 'Knockout',
    'round_robin' => 'Round Robin',
    _ => 'Group + KO',
  };
  final formatChip = find.text(formatLabel);
  if (formatChip.evaluate().isNotEmpty) {
    await tester.tap(formatChip.first);
    await settle(tester);
  }

  // Set overs
  final oversPreset = find.text('${preset.overs}');
  if (oversPreset.evaluate().isNotEmpty) {
    await tester.tap(oversPreset.first);
    await settle(tester);
  } else {
    final oversInput = find.byKey(const Key('oversInput'));
    if (oversInput.evaluate().isNotEmpty) {
      await tester.enterText(oversInput.first, '${preset.overs}');
      await settle(tester);
    }
  }

  // Select ball type
  final ballTypeLabel = switch (preset.ballTypeId) {
    1 => 'Leather',
    2 => 'Tennis',
    3 => 'Tape',
    4 => 'Other',
    _ => 'Leather',
  };
  final ballChip = find.text(ballTypeLabel);
  if (ballChip.evaluate().isNotEmpty) {
    await tester.ensureVisible(ballChip.first);
    await tester.pumpAndSettle();
    await tester.tap(ballChip.first);
    await settle(tester);
  }

  // Set players per side
  await _adjustStepper(tester, stepperKey: 'playersPerSideStepper',
      targetValue: preset.playersPerSide, defaultValue: 11);

  // Set group settings if group_knockout
  if (preset.format == 'group_knockout') {
    await _adjustStepper(tester, stepperKey: 'numGroupsStepper',
        targetValue: preset.numGroups, defaultValue: 2);
    await _adjustStepper(tester, stepperKey: 'qualifyPerGroupStepper',
        targetValue: preset.qualifyPerGroup, defaultValue: 2);
  }

  // Dismiss keyboard
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pumpAndSettle();

  // Submit
  await settle(tester);
  final submitButton = find.widgetWithText(FilledButton, 'Create Tournament');
  print('    [createTournament] FilledButtons found: ${submitButton.evaluate().length}');
  if (submitButton.evaluate().isNotEmpty) {
    await tester.tap(submitButton.first);
    print('    [createTournament] Tapped FilledButton');
  } else {
    print('    [createTournament] ERROR: Submit button not found!');
    dumpVisibleTexts(tester, 'createTournament-noSubmit', 30);
  }

  await settle(tester);
  await visualPause(tester, 3000);

  final stillOnForm = find.text('Tournament Name');
  if (stillOnForm.evaluate().isNotEmpty) {
    print('    [createTournament] WARNING: Still on create form after submit!');
    dumpVisibleTexts(tester, 'createTournament STUCK', 30);
  } else {
    print('    [createTournament] Tournament created: $name');
  }
}

/// Transition tournament status via the PopupMenuButton.
///
/// [menuLabel] is the text of the menu item:
/// - 'Open Registration' (draft → registration)
/// - 'Start Tournament' (registration → live)
Future<void> transitionTournamentStatus(
  WidgetTester tester,
  String menuLabel,
) async {
  clearSnackBars(tester);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();

  final popupButton = find.byType(PopupMenuButton<String>);
  if (popupButton.evaluate().isEmpty) {
    print('    [transitionStatus] ERROR: PopupMenuButton not found!');
    return;
  }

  final popupState = tester.state<PopupMenuButtonState<String>>(popupButton.first);
  popupState.showButtonMenu();
  await tester.pumpAndSettle();
  await visualPause(tester);

  final menuItem = find.text(menuLabel);
  if (menuItem.evaluate().isNotEmpty) {
    await tester.tap(menuItem.first);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();
    print('    [transitionStatus] Tapped "$menuLabel"');
  } else {
    print('    [transitionStatus] ERROR: Menu item "$menuLabel" not found!');
    dumpVisibleTexts(tester, 'transitionStatus', 20);
  }
}

/// Add a team to a tournament from the tournament detail page.
Future<void> addTeamToTournament(
  WidgetTester tester,
  String teamName, {
  String? groupName,
}) async {
  clearSnackBars(tester);
  await tester.pump(const Duration(milliseconds: 300));

  // Switch to Teams tab
  await switchToTab(tester, 2);

  // Tap "Add Team" button
  final addTeamButton = find.widgetWithText(FilledButton, 'Add Team');
  if (addTeamButton.evaluate().isEmpty) {
    print('    [addTeamToTournament] ERROR: "Add Team" button not found!');
    dumpVisibleTexts(tester, 'addTeam-noButton', 30);
    return;
  }
  final button = tester.widget<FilledButton>(addTeamButton.first);
  button.onPressed?.call();
  await settle(tester);
  await visualPause(tester, 500);

  // Wait for bottom sheet
  final sheetFound = await waitForFinder(tester, find.byType(BottomSheet),
      timeoutMs: 3000, intervalMs: 200);

  if (!sheetFound) {
    print('    [addTeamToTournament] ERROR: Bottom sheet did not open!');
    dumpVisibleTexts(tester, 'addTeam-noSheet', 30);
    return;
  }

  // Select group chip if provided
  if (groupName != null) {
    final groupChip = find.text('Group $groupName');
    if (groupChip.evaluate().isNotEmpty) {
      await tester.tap(groupChip.first);
      await settle(tester);
      print('    [addTeamToTournament] Selected group: $groupName');
    } else {
      print('    [addTeamToTournament] WARNING: Group chip "Group $groupName" not found');
    }
  }

  // Find and tap team name — scroll if needed
  var teamOption = find.text(teamName);
  if (teamOption.evaluate().isEmpty) {
    final scrollables = find.byType(Scrollable);
    if (scrollables.evaluate().length >= 2) {
      try {
        await tester.scrollUntilVisible(
          find.text(teamName), 200,
          scrollable: scrollables.last, maxScrolls: 20,
        );
      } catch (_) {}
      teamOption = find.text(teamName);
    }
  }

  if (teamOption.evaluate().isNotEmpty) {
    await tester.ensureVisible(teamOption.first);
    await tester.pumpAndSettle();
    await tester.tap(teamOption.first);
    await settle(tester);
    await visualPause(tester, 1000);
    print('    [addTeamToTournament] Tapped team: $teamName');
  } else {
    print('    [addTeamToTournament] ERROR: Team "$teamName" not found in bottom sheet!');
    dumpVisibleTexts(tester, 'addTeam-noTeam', 40);
    await tester.tapAt(Offset.zero);
    await settle(tester);
    return;
  }

  // Wait for sheet to dismiss
  await waitForFinderGone(tester, find.byType(BottomSheet),
      timeoutMs: 3000, intervalMs: 200);
  await settle(tester);
  print('    [addTeamToTournament] Added $teamName${groupName != null ? ' to Group $groupName' : ''}');
}

/// Generate fixtures on the tournament detail page.
Future<void> generateFixtures(WidgetTester tester) async {
  clearSnackBars(tester);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();

  // Switch to Overview tab
  await switchToTab(tester, 0);

  // TECH DEBT: SliverAppBar blocks hit testing in integration tests.
  // Invoke onPressed directly instead of tapping. See Flutter issue:
  // https://github.com/flutter/flutter/issues/83838
  final generateButton = find.widgetWithText(FilledButton, 'Generate Fixtures');
  if (generateButton.evaluate().isNotEmpty) {
    final button = tester.widget<FilledButton>(generateButton.first);
    if (button.onPressed != null) {
      print('    [generateFixtures] Invoking onPressed directly');
      button.onPressed!();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pumpAndSettle();
      print('    [generateFixtures] Generate Fixtures triggered');
    } else {
      print('    [generateFixtures] ERROR: Button found but onPressed is null');
    }
  } else {
    print('    [generateFixtures] ERROR: "Generate Fixtures" button not found!');
    dumpVisibleTexts(tester, 'generateFixtures', 30);
  }

  // Verify fixtures were actually created by checking Fixtures tab
  await switchToTab(tester, 1);
  await settle(tester);
  final fixtureCards = find.byType(FixtureCard);
  expect(fixtureCards, findsAtLeast(1),
      reason: 'Fixtures tab should show at least one FixtureCard after generation');
  print('    [generateFixtures] Verified: ${fixtureCards.evaluate().length} FixtureCards on Fixtures tab');
}

/// Adjust a stepper widget to a target value.
Future<void> _adjustStepper(
  WidgetTester tester, {
  required String stepperKey,
  required int targetValue,
  required int defaultValue,
}) async {
  final stepper = find.byKey(Key(stepperKey));
  if (stepper.evaluate().isEmpty) {
    print('    [adjustStepper] WARNING: Stepper "$stepperKey" not found');
    return;
  }

  await tester.ensureVisible(stepper.first);
  await tester.pumpAndSettle();

  final diff = targetValue - defaultValue;
  if (diff == 0) return;

  final iconToTap = diff > 0 ? Icons.add : Icons.remove;
  final tapsNeeded = diff.abs();

  final buttons = find.descendant(
    of: stepper,
    matching: find.byIcon(iconToTap),
  );

  if (buttons.evaluate().isEmpty) {
    print('    [adjustStepper] WARNING: ${diff > 0 ? "+" : "-"} button not found in "$stepperKey"');
    return;
  }

  for (var i = 0; i < tapsNeeded; i++) {
    await tester.tap(buttons.first);
    await tester.pump();
  }
  await settle(tester);
  print('    [adjustStepper] $stepperKey: $defaultValue → $targetValue');
}
