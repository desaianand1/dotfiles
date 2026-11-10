## General Rules

- Comments: only Why/Intent/rationale — never tautological implementation descriptions. No purple prose.
- Tests: arrange/act/assert, atomic, behavior-based. Cover happy path + edge cases, not trivial behaviors.

## Commits

- Strict conventional commits: `feat`, `fix`, `perf`, `refactor`, `chore`, `build`, `ci`, `docs`, `test`, `style`.
- `feat!` / `BREAKING CHANGE:` only for end-user-affecting breaking changes in feature code.
- Subject: concise, imperative. Body (optional): why/intent/rationale — never reference PRDs/specs/plans.
- Never add `Co-Authored-By` or mention Claude/AI. No body is fine for self-explanatory changes.

## Code Style

- No `as any` casts — fix dependency mismatches at source.
- Validation messages: ≤5 words, imperative ("Enter a street address").
- Reuse existing constants, maps, components, utils — don't duplicate.
- No per-feature abstractions for simple patterns. Three similar lines > premature abstraction.

## Security

- Never commit secrets, credentials, API keys, or .env files.
- Validate at system boundaries (user input, external APIs). Trust internal code.
- Follow OWASP top 10 awareness for web applications.
