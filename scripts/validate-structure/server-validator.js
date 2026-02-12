#!/usr/bin/env node

/**
 * Server Structure Validator
 * Enforces file placement rules from .claude/rules.md for apps/server/
 *
 * Exit codes: 0 = pass, 1 = fail with violation list
 * Called by: CI pipeline (.github/workflows/ci.yml) and pre-commit hook
 */

const fs = require("fs");
const path = require("path");

const SERVER_ROOT = path.resolve(__dirname, "../../apps/server");
const SRC_ROOT = path.join(SERVER_ROOT, "src");

const violations = [];

function addViolation(severity, file, message) {
  violations.push({ severity, file: path.relative(SERVER_ROOT, file), message });
}

function getAllFiles(dir, ext) {
  const results = [];
  if (!fs.existsSync(dir)) return results;

  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === "node_modules") continue;
      results.push(...getAllFiles(fullPath, ext));
    } else if (!ext || entry.name.endsWith(ext)) {
      results.push(fullPath);
    }
  }
  return results;
}

// Rule 1: Services must have .service.ts suffix
function checkServiceNaming() {
  const servicesDir = path.join(SRC_ROOT, "services");
  if (!fs.existsSync(servicesDir)) return;

  const tsFiles = getAllFiles(servicesDir, ".ts");
  for (const file of tsFiles) {
    const fileName = path.basename(file);
    if (fileName === "index.ts") continue;
    if (!fileName.endsWith(".service.ts")) {
      addViolation("medium", file,
        `Service files must have .service.ts suffix. Got: ${fileName}`);
    }
  }
}

// Rule 2: No route imports in service files (dependency: routes -> services -> db)
function checkServiceDependencyDirection() {
  const servicesDir = path.join(SRC_ROOT, "services");
  if (!fs.existsSync(servicesDir)) return;

  const tsFiles = getAllFiles(servicesDir, ".ts");
  for (const file of tsFiles) {
    const content = fs.readFileSync(file, "utf8");
    if (/from\s+['"].*\/routes\//.test(content) || /import\s+.*['"].*\/routes\//.test(content)) {
      addViolation("critical", file,
        `Service files must not import from routes/. Dependency direction: routes -> services -> db.`);
    }
  }
}

// Rule 3: kebab-case naming for TypeScript files (except dot-notation services)
function checkKebabCase() {
  const tsFiles = getAllFiles(SRC_ROOT, ".ts");
  for (const file of tsFiles) {
    const fileName = path.basename(file, ".ts");

    // Allow dot-notation (e.g., scoring.service)
    if (fileName.includes(".")) continue;
    // Allow index.ts
    if (fileName === "index") continue;

    if (!/^[a-z][a-z0-9-]*$/.test(fileName)) {
      addViolation("low", file,
        `TypeScript files must use kebab-case naming. Got: ${fileName}.ts`);
    }
  }
}

// Rule 4: Correct folder structure
function checkFolderStructure() {
  if (!fs.existsSync(SRC_ROOT)) return;

  const expectedDirs = ["config", "routes", "services", "db", "middleware", "types", "websocket", "utils"];
  const actualEntries = fs.readdirSync(SRC_ROOT, { withFileTypes: true });

  for (const entry of actualEntries) {
    if (!entry.isDirectory()) continue;
    if (!expectedDirs.includes(entry.name)) {
      addViolation("medium", path.join(SRC_ROOT, entry.name),
        `Unexpected directory in src/: ${entry.name}/. Expected: ${expectedDirs.join(", ")}`);
    }
  }
}

// Rule 5: No files in src/ root except index.ts
function checkSrcRoot() {
  if (!fs.existsSync(SRC_ROOT)) return;

  const entries = fs.readdirSync(SRC_ROOT, { withFileTypes: true });
  for (const entry of entries) {
    if (entry.isFile() && entry.name.endsWith(".ts") && entry.name !== "index.ts") {
      addViolation("medium", path.join(SRC_ROOT, entry.name),
        `No files in src/ root except index.ts. Move to appropriate subdirectory.`);
    }
  }
}

// Rule 6: Route files in correct location
function checkRouteLocation() {
  const routesDir = path.join(SRC_ROOT, "routes", "v1");
  if (!fs.existsSync(routesDir)) return;

  const tsFiles = getAllFiles(routesDir, ".ts");
  for (const file of tsFiles) {
    const fileName = path.basename(file);
    if (fileName === "index.ts") continue;
    // Route files should use kebab-case
    const nameWithoutExt = fileName.replace(".ts", "");
    if (!/^[a-z][a-z0-9-]*$/.test(nameWithoutExt)) {
      addViolation("low", file,
        `Route files must use kebab-case naming. Got: ${fileName}`);
    }
  }
}

// Run all checks
function main() {
  if (!fs.existsSync(SERVER_ROOT)) {
    console.log("apps/server/ not found. Skipping server validation.");
    process.exit(0);
  }

  if (!fs.existsSync(SRC_ROOT)) {
    console.log("apps/server/src/ not found. Skipping server validation.");
    process.exit(0);
  }

  console.log("Running server structure validation...\n");

  checkServiceNaming();
  checkServiceDependencyDirection();
  checkKebabCase();
  checkFolderStructure();
  checkSrcRoot();
  checkRouteLocation();

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
