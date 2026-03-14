# Enterprise Upgrade Plan

## Scope

This pass focuses on backend and CI improvements that materially raise production readiness without broad rewrites:

- request correlation and structured request logging
- health and readiness endpoints with dependency status
- cleaner shutdown and database lifecycle handling
- CI workflow consolidation and stronger automated checks

## Lint Pass Scope

This second pass focuses on making `backend` lint-clean with minimal risk:

- reduce test-suite lint noise through explicit test-only ESLint policy
- fix remaining production-code lint errors in services, models, sockets, and routes
- re-enable lint as a green CI gate only after it passes locally

## Mobile Redesign Scope

This pass focuses on the Flutter app experience and runtime behavior:

- define a more intentional visual system for mobile instead of the current generic Material seed setup
- redesign the login flow, home shell, chat list, and chat thread for clearer hierarchy and better mobile ergonomics
- improve perceived performance by reducing avoidable rebuilds and preserving high-traffic screen state
- verify the redesign with Flutter static analysis

## Plan

- [x] Audit current backend runtime, middleware, and CI behavior
- [x] Add typed request context support for request correlation
- [x] Replace fragile response logging with finish/close-based request logging
- [x] Add health and readiness endpoints with uptime and database state
- [x] Track server shutdown state so readiness reflects deploy lifecycle
- [x] Refactor database connection management to expose connection health cleanly
- [x] Harden configuration for production-safe operation where practical
- [x] Consolidate CI workflows and remove redundant backend test workflow
- [x] Add or update automated tests for middleware, health behavior, and config-sensitive logic
- [x] Run verification commands and capture results
- [x] Inventory repository-wide lint failures and rank by production vs test impact
- [x] Add targeted ESLint overrides for backend test files where strict unsafe rules are not worth invasive fixture typing
- [x] Fix remaining production-code lint violations in backend source files
- [x] Re-enable lint in CI once `yarn lint` passes locally
- [x] Re-run build, lint, and tests and document results
- [x] Audit mobile theme, screen composition, and rebuild hotspots
- [x] Redesign the shared mobile theme and visual primitives
- [x] Redesign the authentication entry screen
- [x] Redesign the home shell and chat list experience
- [x] Redesign the chat conversation screen and composer
- [x] Improve provider-driven rebuild behavior where it affects performance
- [x] Run formatting and Flutter analysis and document the results

## Verification Spec

- [x] `backend` unit and integration tests pass with the new middleware and lifecycle behavior
- [x] Health endpoint returns `200` with expected metadata during normal operation
- [x] Readiness endpoint returns `200` when dependencies are healthy
- [x] Readiness logic can return non-ready status when shutdown or dependency failure is simulated in tests
- [x] Request ID is present on responses and included in request/error logging metadata
- [x] `yarn build` passes after the runtime changes
- [x] No redundant GitHub workflow remains for the same backend test responsibility
- [x] `cd backend && yarn lint` passes
- [x] `cd backend && yarn build` still passes after lint fixes
- [x] `cd backend && yarn test` still passes after lint fixes
- [x] `cd mobile && dart format lib`
- [x] `cd mobile && flutter analyze --no-fatal-infos`

## Review

- Implemented request correlation via typed `requestId` support, inbound header reuse, response header propagation, and finish/close-based request logging.
- Added `/api/health/live`, richer `/api/health`, and `/api/health/ready` endpoints with uptime, lifecycle, and MongoDB dependency state.
- Refactored runtime lifecycle so shutdown state is explicit, MongoDB health is queryable, and graceful shutdown is idempotent.
- Hardened production configuration by rejecting weak `JWT_SECRET` values in production.
- Consolidated backend CI by removing the redundant workflow and keeping the existing green checks intact.
- Verification completed:
  - `cd backend && yarn build`
  - `cd backend && yarn test`
  - targeted ESLint run over all touched runtime and test files
- Residual risk:
  - repository-wide `yarn lint` is already failing on large pre-existing TypeScript ESLint debt outside this change set, so I did not wire that into CI and knowingly break the pipeline.
- Second pass completed:
  - added test-only ESLint overrides in [`backend/.eslintrc.json`](/Users/tum/programming/personal/chat-app/backend/.eslintrc.json) for unsafe access patterns common in fixtures and response assertions
  - cleaned remaining production lint errors across routes, models, services, and socket setup
  - restored `yarn lint` to CI in [`.github/workflows/ci.yml`](/Users/tum/programming/personal/chat-app/.github/workflows/ci.yml)
- Verification completed for the lint pass:
  - `cd backend && yarn lint`
  - `cd backend && yarn build`
  - `cd backend && yarn test`
- Current status:
  - lint passes with warnings only
  - build passes
  - full backend test suite passes: `16` suites, `196` tests
- Remaining debt:
  - there are still warning-level TypeScript lint findings in [`backend/src/services/chatService.ts`](/Users/tum/programming/personal/chat-app/backend/src/services/chatService.ts), [`backend/src/sockets/chatEvents.ts`](/Users/tum/programming/personal/chat-app/backend/src/sockets/chatEvents.ts), [`backend/src/utils/logUtils.ts`](/Users/tum/programming/personal/chat-app/backend/src/utils/logUtils.ts), and [`backend/src/utils/pagination.ts`](/Users/tum/programming/personal/chat-app/backend/src/utils/pagination.ts)
  - these warnings do not block CI today, but the next quality pass should convert the remaining `any` and non-null assertions into fully typed helpers
- Mobile redesign pass completed:
  - replaced the generic theme with a more intentional teal, coral, and sand visual system for light and dark modes in [`mobile/lib/providers/theme_provider.dart`](/Users/tum/programming/personal/chat-app/mobile/lib/providers/theme_provider.dart)
  - redesigned the auth loading state, home shell, inbox header, and chat thread to create a clearer hierarchy and more distinctive mobile UX
  - preserved tab state in the home shell with `IndexedStack` and reduced broad provider rebuilds in inbox and thread flows through `context.select`
  - hardened chat initialization so socket callbacks are only bound once and room selection no longer risks null fallback crashes
- Mobile verification completed:
  - `cd mobile && dart format lib`
  - `cd mobile && flutter analyze --no-fatal-infos`
- Mobile current status:
  - formatting passed
  - static analysis completed with no warnings or errors
  - the package still has `info`-level debt in older files, mostly `print`, deprecated Flutter API usage, and minor style issues outside this redesign scope
- Mobile remaining debt:
  - replace `print`-based diagnostics in providers and services with structured logging or debug-only logging
  - clear deprecated `withOpacity` and `Radio` API usage across auth, settings, and chat-adjacent screens
  - add widget and golden tests for the redesigned auth, inbox, and thread screens before treating the mobile UI as regression-safe
