---
name: android-app-reverser
description: Reverse-engineer Android APKs into production-quality Rust CLIs, API libraries, and optional FUSE filesystems. Use when analyzing Android apps, APK/XAPK files, auth flows, API clients, decompiled code, app data models, or building alternative Rust clients from mobile app behavior.
---

# Skill: Android App Reverse Engineering to Rust CLI

Reverse-engineer any Android app from APK to a production-quality Rust CLI, API library, and optional FUSE filesystem. Proven 9-phase workflow extracted from a real project.

---

## When to Use This Skill

The user wants to reverse-engineer an Android app's API, build an alternative Rust client, or understand an app's auth flow / data models / architecture.

---

## Execution Engine

This is a **phased, backlog-driven pipeline**. Do NOT dump all tasks upfront. Each phase gates the next.

### Prerequisites (before any phase)

1. Write `re/prd.md` -- the PRD persists context across agents and sessions
2. Write `AGENTS.md` for Codex, or `CLAUDE.md` for Claude Code -- point it to the PRD, backlog rules, and security rules. This is what every delegated agent reads first.
3. Init backlog: `backlog init --cli --claude --leading-zeros 4` unless the local backlog tool documents a Codex-specific flag.

These three files are the **persistence layer** that keeps delegated agents aligned.

### Phase execution loop

```
For each phase (1 through 9):
  1. POPULATE: Create backlog tasks for THIS phase only
  2. EXECUTE: Spawn or use the SWE-gardener agent for each task, sequentially
     - Agent reads AGENTS.md/CLAUDE.md and PRD first
     - Agent assigns task, sets In Progress, implements, checks ACs
     - Agent creates NEW backlog tasks for any tangents/discoveries
     - Git commit after each task
  3. GATE: When all phase N tasks are Done:
     - Run MPED-architect review (if code was written)
     - Run QA-test-runner (if tests exist)
     - Fix any issues as new tasks
     - User confirms: "proceed to phase N+1"
  4. ADVANCE: Populate backlog with phase N+1 tasks, repeat
```

### Key rules

- **One task per delegated agent, sequential** -- no multi-task parallelism
- **Every tangent becomes a backlog task** -- delegated agents must NOT chase tangents inline
- **All RE artifacts go under `re/`** -- decompilation docs, analysis, scripts
- **Git commit between tasks** -- clean history, one logical change per commit
- **Backlog is the single source of truth** -- no ad-hoc work
- **`just showcase` as regression gate** -- run after every change once CLI exists

---

## Phase 1: Project Setup

### What to Do
1. Create project directory, `git init`
2. Write a `shell.nix` with all decompilation and Rust tooling
3. Create `AGENTS.md` for Codex, or `CLAUDE.md` for Claude Code, pointing to PRD, backlog, key files
4. Create `.gitignore` covering APK files, extracted/decompiled output, secrets
5. Initialize backlog: `backlog init --cli --claude --leading-zeros 4` unless the local backlog tool documents a Codex-specific flag
6. Write a PRD (`re/prd.apk_decompile.md`) with milestones for extraction, analysis, decompilation, architecture
7. Obtain the APK using `apkeep`:
   ```bash
   # Download latest version from Google Play (needs auth token for paid/geo-restricted apps)
   apkeep -a <package.name> .

   # Download a specific version
   apkeep -a <package.name>@<version> .

   # Download from APKPure (no auth needed, good fallback)
   apkeep -a <package.name> -d apkpure .
   ```
   - apkeep may download an XAPK (ZIP of split APKs) -- handle in Phase 2
   - Verify the downloaded file: `file *.apk *.xapk`
   - If apkeep fails for a source, try another: `apkpure`, `google-play`, `f-droid`

### shell.nix Essentials
```nix
{ pkgs ? import <nixpkgs> {} }:
let
  apkeep = pkgs.rustPlatform.buildRustPackage rec {
    pname = "apkeep";
    version = "0.18.0";
    src = pkgs.fetchFromGitHub {
      owner = "EFForg";
      repo = "apkeep";
      rev = version;
      hash = "sha256-wOpPyO2TULHoNZLfYgjwR9wbIyBQPIFxLsDMp7am8AM=";
    };
    cargoHash = "sha256-PTuhD73R0AxykkVeFEHaVnXrOTHJoRl0CxBJmeh3WgQ=";
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.openssl.dev ];
  };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    # APK acquisition
    apkeep
    # Extraction & analysis
    unzip file tree findutils binwalk binutils hexdump p7zip
    # Android tools
    android-tools apktool
    # Decompilation (Linux-only: jadx, ghidra, ilspycmd, mono)
    jdk radare2
    # Text processing
    ripgrep jq xmlstarlet
    # Rust toolchain
    rustc cargo clippy rustfmt rust-analyzer pkg-config openssl.dev
    # Project management
    just git curl wget
    # Documentation
    pandoc graphviz
    # Python (for custom scripts, no pip)
    python3 python3Packages.requests python3Packages.lxml
  ];
  shellHook = ''
    export JADX_OPTS="-Xmx4g"
    export JAVA_OPTS="-Xmx4g"
    mkdir -p extracted analysis decompiled reports
  '';
}
```

### .gitignore Essentials
```
*.apk
*.xapk
extracted/
decompiled/
decompiled_csharp/
analysis/
reports/
secrets/
*.har
*.pcap
```

### Backlog Tasks to Create
- Extract APK/XAPK recursively
- Analyze file types and structure
- Decompile DEX files with jadx
- Decompile .NET assemblies (if Xamarin)
- Document architecture and API endpoints
- "Add more backlog tasks after initial exploration" (meta-task)

### AGENTS.md/CLAUDE.md Must State
- Any new avenue, tangent, or idea discovered during work MUST be captured as a new backlog task
- Tokens, PII, and credentials go in `secrets/` (gitignored)
- Use `nix-shell --run 'tool args'` for all tool invocations
- Run `just e2e` before every commit

### Gotchas
- `apkeep` is the preferred download tool -- it supports Google Play, APKPure, and F-Droid as sources
- APKPure may serve XAPK (ZIP of split APKs) instead of a plain APK -- handle both
- Google Play downloads via apkeep may need an AAS token (`apkeep -a <pkg> -d google-play -t <token>`)
- Always verify you have the latest version; check multiple sources
- Never commit the APK or decompiled output to git

---

## Phase 2: Extract and Decompile

### What to Do
1. Write `re/apk_extract.sh` for recursive APK/XAPK extraction
2. Run jadx on DEX files: `jadx -d decompiled/jadx classes.dex`
3. Run apktool for resources/manifest: `apktool d app.apk -o decompiled/apktool`
4. If Xamarin/.NET assemblies found, use ilspycmd: `ilspycmd -d assemblies/ -o decompiled_csharp/`
5. Analyze `AndroidManifest.xml` for activities, services, permissions, intent filters
6. Document findings in `re/milestone2_analysis.md`

### Tools
- `unzip` -- APK/XAPK extraction
- `jadx` -- DEX to Java decompilation (use `-Xmx4g` for large apps)
- `apktool` -- Resource and manifest decoding
- `ilspycmd` -- .NET/Xamarin assembly decompilation
- `binwalk` -- Embedded file discovery
- `file` -- Magic number identification
- `strings` -- Quick string extraction from binaries

### Backlog Tasks
- Catalog all file types with counts and sizes
- Identify obfuscation patterns (ProGuard, R8, dotfuscator)
- Extract and document AndroidManifest.xml
- Inventory native libraries (SO files) by architecture

### Gotchas
- jadx may fail on heavily obfuscated code -- try multiple decompilers
- XAPK bundles contain split APKs; extract the outer ZIP first, then process each inner APK
- Some apps use Xamarin (C#/.NET) instead of Java/Kotlin -- look for `assemblies/` directory with `.dll` files
- jadx needs significant heap space for large apps; set `-Xmx4g` or higher
- LZ4-compressed .NET assemblies (Xamarin) need decompression before ilspy can process them

---

## Phase 3: Static Analysis

### What to Do
1. Map the app architecture from decompiled code:
   - Package/namespace structure
   - Framework identification (Retrofit, OkHttp, Xamarin, React Native, Flutter)
   - Dependency injection patterns
2. Identify API endpoints:
   - Search for URL patterns, base URLs, route definitions
   - Look for REST client interfaces (Retrofit annotations, HttpClient calls)
   - Document the API style: REST, RPC, GraphQL, or hybrid
3. Document the auth flow:
   - OAuth2/OIDC discovery endpoints
   - Client IDs, scopes, redirect Uris
   - Token storage and refresh logic
   - Session establishment (cookies vs tokens vs both)
4. Extract data models:
   - DTOs, request/response classes
   - Enum definitions (critical for serde later)
   - Serialization annotations (JSON field names, camelCase vs snake_case)
5. Document domain concepts:
   - Core entities and their relationships
   - Business logic flows
   - Permission/role model

### Key Files to Search For
```bash
# API endpoints
rg -i 'base.?url|api.?url|endpoint' decompiled/
rg -i 'https?://' decompiled/ | grep -v 'google\|firebase\|crashlytics'

# Auth flow
rg -i 'oauth|oidc|authorize|token|pkce|client.?id' decompiled/
rg -i 'redirect.?uri|callback|login' decompiled/

# Data models
rg -i 'class.*dto|class.*request|class.*response' decompiled/

# API versioning
rg -i 'api.?version|apiversion|version=' decompiled/
```

### Backlog Tasks
- Map complete API endpoint catalog
- Document auth flow (OIDC, SAML, custom)
- Extract all data models/DTOs
- Document domain entities and relationships
- Identify API versioning scheme

### Gotchas
- The auth flow is almost always the hardest part. Apps often use:
  - OIDC with PKCE but with non-standard redirect handling
  - Intermediate redirect pages (e.g., `app-redirect.example.com`)
  - WebView cookie capture during redirect chain
  - Token-to-session exchange endpoints
- API authentication may not be what you expect:
  - Some APIs use `access_token` as a query parameter, NOT Bearer headers
  - Some require establishing a PHP/server session via cookie before data endpoints work
  - Some need both cookies AND tokens
- Enum values in the API often differ from the decompiled code's casing (camelCase vs PascalCase)
- Look for `User-Agent` strings -- some APIs check for mobile user agents
- Basic Auth credentials may be hardcoded but empty/no-op in production

---

## Phase 4: Live API Validation

### What to Do
The approach is purely static analysis + direct API testing. No proxies, emulators, or runtime capture.

1. Build a minimal Rust HTTP client from Phase 3 findings (auth flow, base URL, API style)
2. Authenticate using the OIDC/auth flow discovered in Phase 3
3. Call each discovered API endpoint and capture the actual JSON responses
4. Compare real responses against decompiled models -- fix mismatches
5. Save representative responses as test fixtures in `secrets/` (gitignored)
6. Document discrepancies between decompiled code and live API behavior

### Why This Phase Matters
Decompiled code tells you what the app *could* do. Live API responses show what it *actually* returns. The real API often:
- Returns different field names than the model classes suggest
- Omits fields the model defines
- Sends integers where the model expects strings (or vice versa)
- Uses different enum casings than the code
- Requires parameters not obvious from the code alone

### Backlog Tasks
- Implement minimal auth flow and test against live API
- Call each API endpoint and capture real JSON responses
- Compare decompiled models vs actual API responses
- Fix model mismatches discovered during validation
- Save representative responses as test fixtures

### Gotchas
- Captured responses contain PII -- store in `secrets/`
- Some APIs require a session initialization sequence before data endpoints work
- The iterative loop of "call API, see serde error, fix model, repeat" is expected and normal
- Expect to discover endpoints and parameters not visible in the decompiled code

---

## Phase 5: Rust Library (`<app>-api` crate)

### What to Do
1. Create a Cargo workspace: `<app>/Cargo.toml` with members `<app>-api` and `<app>-cli`
2. Implement the HTTP client:
   - Cookie jar (reqwest with `cookie_store(true)`)
   - Auth decoration (token injection -- query param or header, match what the app does)
   - CSRF token extraction and injection
   - User-Agent matching the mobile app
   - Basic Auth if the app uses it
3. Implement auth module:
   - OIDC discovery, PKCE challenge generation
   - Authorization URL builder
   - Token exchange and refresh
   - Token persistence (`~/.local/share/<app>/tokens.json`)
4. Implement session management:
   - Login data storage (tokens, expiry, auth level)
   - Auto-refresh before expiry (with buffer, e.g., 2 minutes)
   - Session context initialization (some APIs require a "setup" call sequence)
5. Implement data models (from decompiled DTOs + live traffic validation):
   - Use `serde` with appropriate `rename_all` (usually `camelCase`)
   - Make fields `Option<T>` liberally -- real APIs omit fields
   - Use `#[serde(default)]` for fields that may be absent
6. Implement service layer:
   - One module per domain (discovered in Phase 3)
   - Functions return typed responses
7. Write unit tests with mock HTTP (wiremock or similar)
8. Write integration/fixture tests with captured API responses

### Cargo.toml Dependencies (Typical)
```toml
[dependencies]
reqwest = { version = "0.12", features = ["cookies", "json"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
tokio = { version = "1", features = ["full"] }
url = "2"
base64 = "0.22"
chrono = { version = "0.4", features = ["serde"] }
thiserror = "2"
```

### Backlog Tasks
- HTTP client with cookie jar and auth decoration
- OIDC auth flow (PKCE, token exchange, refresh)
- Token persistence to disk
- Session management with auto-refresh
- Data models per domain (discovered in Phase 3)
- Service functions per domain
- Unit tests with mock responses
- Fix model mismatches found during integration testing

### Gotchas
- **The #1 time sink**: API returns data that doesn't match the decompiled models. Expect many rounds of "run, see serde error, fix model, repeat."
- Common serde surprises:
  - `integer where string expected` (e.g., user IDs as numbers in JSON but String in code)
  - `map where sequence expected` (API wraps arrays in an object: `{"items": [...]}`)
  - `missing field` (API omits fields the model requires -- add `#[serde(default)]`)
  - Enum casing mismatches (code says `PascalCase`, API sends `camelCase`)
- Token refresh is often bound to the original `client_id` -- store and reuse the auth level
- Some APIs require a multi-step session initialization before data endpoints work
- CSRF tokens: usually a cookie value that must be echoed as a request header on POST/PUT/DELETE

---

## Phase 6: CLI (`<app>-cli` crate)

### What to Do
1. Use `clap` with derive macros for argument parsing
2. Create subcommands per domain (based on API endpoints discovered in Phase 3):
   - `auth login`, `auth status`, `auth refresh`, `auth logout`
   - One subcommand group per domain, with `list`, `show <id>`, etc. as appropriate
3. Support human-readable (table/formatted) and `--json` output
4. Handle auth state: check for valid token, prompt login if needed
5. Add `--manual` login mode (user opens URL, pastes callback) as the reliable default
6. Create a `Justfile` with recipes: `build`, `test`, `lint`, `fmt`, `fmt-check`, `e2e`, `run`, `showcase`

### Justfile Structure
```just
build:
    cargo build --manifest-path <app>/Cargo.toml

test:
    cargo test --manifest-path <app>/Cargo.toml

lint:
    cargo clippy --manifest-path <app>/Cargo.toml -- -D warnings

fmt:
    cargo fmt --manifest-path <app>/Cargo.toml --all

fmt-check:
    cargo fmt --manifest-path <app>/Cargo.toml --all -- --check

e2e: build test lint fmt-check

run *ARGS:
    cargo run --manifest-path <app>/Cargo.toml --bin <app>-cli -- {{ARGS}}

showcase:
    #!/usr/bin/env bash
    set -uo pipefail
    run() { echo "=== $1 ==="; shift; "$@" 2>&1 || echo "(failed)"; echo; }
    A="cargo run --manifest-path <app>/Cargo.toml --bin <app>-cli --"
    run "Auth Status"    $A auth status
    # ... add non-destructive commands per domain discovered in Phase 3
```

### Backlog Tasks
- CLI scaffold with clap subcommands
- Auth commands (login, status, refresh, logout)
- Commands per domain
- Human-readable output formatting
- JSON output mode
- Showcase recipe in Justfile

### Gotchas
- Global flags (e.g., `--profile`) can collide with subcommand flags -- use distinct names
- Pagination: many APIs page results. Add `--all` flag that fetches all pages, plus `--limit N`
- Login redirect: localhost callback servers often don't work with mobile-app-only redirect Uris. The `--manual` mode (paste URL from browser) is more reliable.
- Always run `just e2e` before committing

---

## Phase 7: Integration Testing

### What to Do
1. Write E2E tests that run against the live API (gated behind `#[ignore]`)
2. Store auth tokens in `secrets/auth_token` or env vars
3. Create a showcase smoke test that exercises all read-only commands
4. Document how to set up auth for testing
5. Run showcase after every significant change to catch regressions

### Test Strategy
```
Unit tests:       Mock HTTP, test serde, test business logic
Fixture tests:    Captured JSON responses, test deserialization
E2E live tests:   Real API calls (#[ignore], need auth token)
Showcase:         Just recipe running all non-destructive CLI commands
```

### Backlog Tasks
- E2E test framework with token management
- Fixture tests from captured API responses
- Showcase smoke test recipe
- Test each domain's API calls against live service

### Gotchas
- Live tests need a valid auth session. Document the setup clearly.
- Auth tokens expire. Implement auto-refresh in the test harness.
- Some API responses change over time. Test structure, not content.
- Run tests sequentially against live APIs -- parallel requests may trigger rate limiting

---

## Phase 8: Advanced Features (Opt-in)

This phase is optional. Ask the user which advanced features they want before creating tasks.

### Possible Features
- **FUSE filesystem** (`fuser` crate) -- mount the API as a filesystem with one directory per domain, lazy media download, cached directory listings
- **Offline caching** with TTL
- **Webhook/notification listeners**
- **Export to standard formats** (iCal, vCard, CSV, etc.)
- **Batch operations** (bulk download, export)

### FUSE-Specific Gotchas (if selected)
- FUSE on Linux needs `fuse3`; on macOS needs `macfuse-stubs` for compilation + macFUSE at runtime
- File creation timestamps should use the API's datetime, converted to local timezone
- Long filenames cause issues; truncate and add ID suffix for uniqueness
- `readdir` must not block on network; cache directory listings aggressively

---

## Phase 9: Security and Cleanup

### What to Do
1. PII scan: search tracked files and git history for real names, IDs, institution names
2. Scrub git history if PII was committed: use `git-filter-repo`
3. Move all reverse engineering artifacts under `re/` folder
4. Write README: scope, how to build, how to authenticate, where tokens are stored
5. Add LICENSE (MIT or similar)
6. Final review of `.gitignore`
7. Create a PII scan skill/script for pre-push verification

### PII Scanning Approach
```bash
# Search tracked files
git ls-files -z | xargs -0 grep -il '<pii-term>'

# Search git history
git log -p --all | grep -i '<pii-term>'

# If PII found in history, scrub with git-filter-repo
git filter-repo --replace-text <(echo '<real-value>==>REDACTED') --force
```

### Backlog Tasks
- PII scan of tracked files and git history
- Scrub PII from git history (git-filter-repo)
- Consolidate reverse engineering files under `re/`
- Write README
- Add LICENSE
- Create pre-push PII scan hook/skill

### Gotchas
- PII in the repo during development is OK -- create low-priority backlog tasks for scrubbing before public release
- PII scan terms should be stored outside the repo (e.g., `~/.claude/projects/`)
- `git-filter-repo` rewrites history -- coordinate with any remote
- Test fixtures often contain real data from captured responses -- anonymize before publishing
- HAR files and network captures contain tokens and PII -- must be gitignored

---

## Meta-Workflow: Agent Orchestration

See "Execution Engine" above for the full loop. This section covers agent roles and recovery.

### Agent Roles
- **User**: Sets direction, gates phases, handles manual steps (login, auth)
- **SWE-gardener**: Implements one backlog task. Reads AGENTS.md/CLAUDE.md + PRD first. Creates new tasks for discoveries.
- **MPED-architect**: Reviews code at phase gates. Run in parallel with QA.
- **QA-test-runner**: Runs `just e2e` + `just showcase`. Run in parallel with MPED.

### Key Principles
- **Backlog is the single source of truth**: All work items tracked in backlog. Nothing ad-hoc.
- **Do not run parallel commands**: When exploring a live API, run one command at a time to observe results clearly.
- **Showcase as regression test**: After every change, run the showcase recipe to verify nothing broke.
- **Delegated agents for large output**: Any tool that generates large output (API responses, file listings) should be delegated to a separate agent to protect the context window.

### Delegated Agent Instructions Template
```
"Read AGENTS.md/CLAUDE.md and PRD. Then: backlog task <N> --plain.
Assign to yourself, set In Progress. Implement. Check ACs.
Create new backlog tasks for any tangents. Do NOT commit."
```

### Common User Commands (Pattern)
```
"read prd and AGENTS.md/CLAUDE.md, then look at open backlog tasks"
"implement task N using SWE-gardener as delegated agent"
"run mped-architect and qa-test-runner in parallel"
"git commit, then proceed to next task"
"create backlog tasks for [observations from testing]"
"fix one by one, delegated agent per task, git commit between tasks"
```

### When Things Go Wrong
- **API returns unexpected data**: Create a backlog task for the model mismatch. Fix in a dedicated task, not inline.
- **Auth flow doesn't work**: Go back to Phase 4 (live traffic capture) to get ground truth. Compare against decompiled code.
- **Tests fail after changes**: Fix before committing. If the fix is non-trivial, create a new task.
- **PII leaked into git**: Create low-priority backlog tasks for scrubbing. Use `git-filter-repo` before publishing to public remote.

---

## Quick Start

When a user says "I want to reverse-engineer [Android App X]":

### Step 0: Bootstrap (do this FIRST, before any phase)
1. Ask for the app's package name (e.g., `com.example.app`)
2. Create project directory, `git init`
3. Write `re/prd.md` -- project requirements, milestones, scope
4. Write `AGENTS.md` for Codex, or `CLAUDE.md` for Claude Code -- point it to PRD, backlog rules, `re/` folder convention, security rules
5. Write `shell.nix`, `.gitignore`
6. Init backlog: `backlog init --cli --claude --leading-zeros 4` unless the local backlog tool documents a Codex-specific flag
7. Git commit

### Then follow the phase loop:
1. Create backlog tasks for Phase 1 (setup, APK acquisition)
2. Execute tasks sequentially via SWE-gardener delegated agents
3. Obtain APK and begin Phase 2
4. After extraction/decompilation: create Phase 3 analysis tasks
5. After static analysis: create Phase 4 traffic capture tasks
6. After live traffic: create Phase 5 Rust library tasks
7. After Rust library: create Phase 6 CLI tasks
8. After CLI: create Phase 7 integration test tasks
9. After working CLI: create Phase 8 advanced feature tasks
10. Before publishing: create Phase 9 cleanup tasks (PII scan, README, LICENSE)

At each gate, the user decides whether to proceed, add more tasks, or skip ahead.

---

## Time Estimates (from Real Project)

| Phase | AI Time | Human Time (prompts) |
|-------|---------|---------------------|
| Setup + Extract + Decompile | 2-4 hours | 15 minutes |
| Static Analysis | 4-8 hours | 30 minutes |
| Live Traffic Capture | 2-4 hours | 30 minutes (login) |
| Rust Library | 8-16 hours | 1 hour |
| CLI | 4-8 hours | 30 minutes |
| Integration Testing | 2-4 hours | 15 minutes |
| Advanced Features (FUSE) | 4-8 hours | 30 minutes |
| Security + Cleanup | 2-4 hours | 30 minutes |
| **Total** | **~28-56 hours** | **~4 hours** |

Equivalent manual effort: estimated 3-6 developer-months.
