#!/usr/bin/env node

/**
 * Flutter Structure Validator
 * Enforces file placement rules from .claude/rules.md for apps/mobile/
 *
 * Exit codes: 0 = pass, 1 = fail with violation list
 * Called by: CI pipeline (.github/workflows/ci.yml) and pre-commit hook
 */

const fs = require("fs");
const path = require("path");

const MOBILE_ROOT = path.resolve(__dirname, "../../apps/mobile");
const LIB_ROOT = path.join(MOBILE_ROOT, "lib");
const SRC_ROOT = path.join(LIB_ROOT, "src");
const FEATURES_ROOT = path.join(SRC_ROOT, "features");

const violations = [];

function addViolation(severity, file, message) {
  violations.push({ severity, file: path.relative(MOBILE_ROOT, file), message });
}

function getAllFiles(dir, ext) {
  const results = [];
  if (!fs.existsSync(dir)) return results;

  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      results.push(...getAllFiles(fullPath, ext));
    } else if (!ext || entry.name.endsWith(ext)) {
      results.push(fullPath);
    }
  }
  return results;
}

function isGeneratedFile(fileName) {
  return /\.(g|freezed|gr)\.dart$/.test(fileName);
}

// Rule 1: No files directly in lib/ except main.dart
function checkLibRoot() {
  if (!fs.existsSync(LIB_ROOT)) return;

  const entries = fs.readdirSync(LIB_ROOT, { withFileTypes: true });
  for (const entry of entries) {
    if (entry.isFile() && entry.name.endsWith(".dart") && entry.name !== "main.dart") {
      addViolation("critical", path.join(LIB_ROOT, entry.name),
        `No files directly in lib/ except main.dart. Move to lib/src/ subdirectory.`);
    }
  }
}

// Rule 2: snake_case naming for all Dart files (excluding generated)
function checkSnakeCase() {
  const dartFiles = getAllFiles(LIB_ROOT, ".dart");
  for (const file of dartFiles) {
    const fileName = path.basename(file);
    if (isGeneratedFile(fileName)) continue;

    const nameWithoutExt = fileName.replace(".dart", "");
    if (!/^[a-z][a-z0-9_]*$/.test(nameWithoutExt)) {
      addViolation("low", file, `Dart files must use snake_case naming. Got: ${fileName}`);
    }
  }
}

// Rule 3: No widgets in core/
function checkNoWidgetsInCore() {
  const coreDir = path.join(SRC_ROOT, "core");
  if (!fs.existsSync(coreDir)) return;

  const dartFiles = getAllFiles(coreDir, ".dart");
  for (const file of dartFiles) {
    const content = fs.readFileSync(file, "utf8");
    if (/class\s+\w+\s+extends\s+(Stateless|Stateful)Widget/.test(content)) {
      addViolation("high", file,
        `No widgets in core/. Move to shared/widgets/ or feature presentation/widgets/.`);
    }
  }
}

// Rule 4: No cross-feature data/ or domain/ imports
function checkCrossFeatureImports() {
  if (!fs.existsSync(FEATURES_ROOT)) return;

  const featureDirs = fs.readdirSync(FEATURES_ROOT, { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => d.name);

  for (const feature of featureDirs) {
    const featureDir = path.join(FEATURES_ROOT, feature);
    const dartFiles = getAllFiles(featureDir, ".dart");

    for (const file of dartFiles) {
      if (isGeneratedFile(path.basename(file))) continue;

      const content = fs.readFileSync(file, "utf8");
      const importRegex = /import\s+['"].*features\/([^/]+)\/(data|domain)\//g;
      let match;

      while ((match = importRegex.exec(content)) !== null) {
        if (match[1] !== feature) {
          addViolation("high", file,
            `Cross-feature import: imports from '${match[1]}/${match[2]}/'. Features communicate through shared/ only.`);
        }
      }
    }
  }
}

// Rule 5: Feature modules have required subdirectories
function checkFeatureCompleteness() {
  if (!fs.existsSync(FEATURES_ROOT)) return;

  const requiredSubdirs = [
    "domain/entities",
    "data/datasources",
    "data/repositories",
    "presentation/pages",
    "presentation/notifiers",
  ];

  const featureDirs = fs.readdirSync(FEATURES_ROOT, { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => d.name);

  for (const feature of featureDirs) {
    const featureDir = path.join(FEATURES_ROOT, feature);

    // Check for providers.dart
    if (!fs.existsSync(path.join(featureDir, "providers.dart"))) {
      addViolation("medium", featureDir,
        `Feature '${feature}' missing providers.dart`);
    }

    for (const subdir of requiredSubdirs) {
      const subdirPath = path.join(featureDir, subdir);
      if (!fs.existsSync(subdirPath)) {
        addViolation("medium", featureDir,
          `Feature '${feature}' missing required subdirectory: ${subdir}/`);
      }
    }
  }
}

// Run all checks
function main() {
  if (!fs.existsSync(MOBILE_ROOT)) {
    console.log("apps/mobile/ not found. Skipping Flutter validation.");
    process.exit(0);
  }

  if (!fs.existsSync(LIB_ROOT)) {
    console.log("apps/mobile/lib/ not found. Skipping Flutter validation.");
    process.exit(0);
  }

  console.log("Running Flutter structure validation...\n");

  checkLibRoot();
  checkSnakeCase();
  checkNoWidgetsInCore();
  checkCrossFeatureImports();
  checkFeatureCompleteness();

  if (violations.length === 0) {
    console.log("All checks passed.");
    process.exit(0);
  }

  console.log(`Found ${violations.length} violation(s):\n`);

  const bySeverity = { critical: [], high: [], medium: [], low: [] };
  for (const v of violations) {
    bySeverity[v.severity].push(v);
  }

  for (const severity of ["critical", "high", "medium", "low"]) {
    if (bySeverity[severity].length === 0) continue;
    console.log(`[${severity.toUpperCase()}]`);
    for (const v of bySeverity[severity]) {
      console.log(`  ${v.file}: ${v.message}`);
    }
    console.log("");
  }

  process.exit(1);
}

main();
