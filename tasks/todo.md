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
