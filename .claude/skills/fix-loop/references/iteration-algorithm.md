# Fix Loop — Iteration Algorithm

## Full Loop Mode Pseudocode

```
INPUT: failure_output, failure_context, files_of_interest, retest_command, max_iterations, max_attempts_per_issue

session_id = generate_timestamp_id()
mkdir {log_dir}/{session_id}/
issue_queue = parse_discrete_issues(failure_output)
attempt_counts = {}  // issue_key -> count
iteration = 0
all_fixes = []

WHILE iteration < max_iterations AND issue_queue is not empty:
    iteration++
    current_issue = issue_queue[0]
    issue_key = fingerprint(current_issue)

    IF attempt_counts[issue_key] >= max_attempts_per_issue:
        mark current_issue as UNRESOLVED
        remove from queue
        CONTINUE

    attempt_counts[issue_key]++
    attempt = attempt_counts[issue_key]

    // STEP 1: DETERMINE THINKING LEVEL
    IF force_thinking_level:
        level = force_thinking_level
    ELSE IF attempt == 1:
        level = "normal"
    ELSE IF attempt <= 3:
        level = "thinkhard"
    ELSE:
        level = "ultrathink"

    // STEP 2: ANALYZE
    IF level == "normal":
        analysis = direct_analysis(current_issue, files_of_interest)
    ELSE:
        analysis = launch_debugger_agent(
            failure_output = current_issue.output,
            files = files_of_interest,
            prior_attempts = get_prior_logs(session_id, issue_key),
            thinking_level = level
        )

    // STEP 3: APPLY FIX
    proposed_fix = derive_fix(analysis)

    IF violates_prohibited_actions(proposed_fix):
        mark UNRESOLVED("Only fix violates prohibited action")
        CONTINUE

    apply_fix(proposed_fix)
    all_fixes.append(proposed_fix)

    // STEP 4: CODE REVIEW GATE
    review = launch_code_reviewer_agent(
        fix = proposed_fix,
        context = current_issue
    )

    IF review.verdict == "Critical":
        revert_fix(proposed_fix)
        all_fixes.pop()
        // Re-attempt with rejection context on next iteration
        CONTINUE

    // STEP 5: BUILD (if build_command provided)
    IF build_command:
        build_retries = 0
        WHILE build_retries < 3:
            result = run(build_command)
            IF result.success: BREAK
            build_retries++
        IF build_retries >= 3:
            revert_fix(proposed_fix)
            all_fixes.pop()
            mark current_issue as FAILED_BUILD
            CONTINUE

    // STEP 6: RETEST
    result = run(retest_command, timeout=retest_timeout)

    IF result.success:
        mark current_issue as RESOLVED
        remove from queue
        // Check if fix introduced NEW failures
        new_issues = parse_new_issues(result.output)
        issue_queue.extend(new_issues)
    ELSE:
        // Parse updated failure — may have shifted
        issue_queue[0] = parse_remaining_issue(result.output)

    // STEP 7: LOG ITERATION
    write_iteration_log(session_id, iteration, current_issue, proposed_fix, review, result)

END WHILE

// DETERMINE OUTCOME
IF all issues RESOLVED:
    status = "RESOLVED"
ELSE IF some RESOLVED:
    status = "PARTIALLY_RESOLVED"
ELSE IF iteration >= max_iterations:
    status = "MAX_ITERATIONS_EXCEEDED"
ELSE:
    status = "UNRESOLVED"

// CLEAR FLAGS (on RESOLVED only)
IF status == "RESOLVED" AND clear_flags:
    FOR flag in clear_flags:
        clear_workflow_state_flag(flag)

RETURN { status, iterations: iteration, fixes: all_fixes, unresolved: remaining_queue }
```

## Single Fix Mode Pseudocode

```
INPUT: failure_output, failure_context, files_of_interest

// Same as Full Loop Steps 1-4 (analyze, fix, review, build)
// But only ONE pass — no retest loop

// STEP 1: DETERMINE THINKING LEVEL
level = force_thinking_level OR derive_from(attempt_number)

// STEP 2: ANALYZE
analysis = analyze(level, failure_output, files_of_interest, previous_attempts_summary)

// STEP 3: APPLY FIX
proposed_fix = derive_fix(analysis)
IF violates_prohibited_actions: RETURN { fix_applied: false, reason: "prohibited" }
apply_fix(proposed_fix)

// STEP 4: CODE REVIEW
review = launch_code_reviewer_agent(fix, context)
IF review.verdict == "Critical":
    revert_fix(proposed_fix)
    RETURN { fix_applied: false, reverted: true, review: review }

// STEP 5: BUILD (optional)
IF build_command:
    result = run(build_command)
    IF !result.success: revert, RETURN { fix_applied: false, build_failed: true }

RETURN { fix_applied: true, fix: proposed_fix, review: review, build: "PASSED" }
// Caller is responsible for retesting
```

## CricApp-Specific Build Commands

| Platform | Build Command | Test Command |
|----------|--------------|-------------|
| Flutter | `cd apps/mobile && dart run build_runner build --delete-conflicting-outputs` | `cd apps/mobile && flutter test {test_path}` |
| Flutter (full) | `cd apps/mobile && flutter analyze` | `cd apps/mobile && flutter test` |
| Server | `cd apps/server && bunx tsc --noEmit` | `cd apps/server && bun test {test_path}` |

## Error Pattern → Likely Root Cause (CricApp-Specific)

| Error Pattern | Likely Root Cause | Fix Strategy |
|--------------|-------------------|-------------|
| `type 'Null' is not a subtype of type` | Missing null check or incorrect Freezed model | Add null guard or fix model definition |
| `RangeError (index)` | Off-by-one in innings/over/delivery indexing | Check boundary conditions in scoring logic |
| `StateError: Bad state` | Riverpod notifier disposed or not initialized | Check provider lifecycle, add mounted check |
| `MissingPluginException` | Drift/SQLite not initialized in test | Add `TestWidgetsFlutterBinding.ensureInitialized()` |
| `Expected: X, Actual: Y` (assertion) | Logic error in delivery processing | Trace through 10-step pipeline |
| `Connection refused` | Server not running for integration test | Start server or mock the endpoint |
| `Build runner error` | Stale generated files | Run `build_runner build --delete-conflicting-outputs` |
| `Type check error` (TypeScript) | Drizzle schema mismatch | Check schema definition types |
