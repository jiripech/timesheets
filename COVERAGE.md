# Test Coverage

## Unit Tests

Unit tests live in `spec/timesheets_spec.rb` and are run with RSpec (`bundle exec rspec`).

### Covered

#### `minutes_from_note(note)`

| # | Input | Expected Output | Notes |
|---|-------|----------------|-------|
| 1 | `"add 1d 2h 30m of time spent"` | `1590` | Day + hour + minute combination |
| 2 | `"sub 1h of time spent"` | `-60` | Subtraction with hours |
| 3 | `"add 45m of time spent"` | `45` | Addition with minutes only |
| 4 | `"sub 1d of time spent"` | `-1440` | Subtraction with days |
| 5 | `""` | `0` | Empty string guard |
| 6 | `"just a random comment"` | `0` | Returns 0 when no digit-unit patterns match |

### Not Covered by Unit Tests

The following are **not** covered by unit tests:

| Item | Reason |
|------|--------|
| `put_time_estimation(stats)` | Requires a GitLab API object (live or mocked) |
| `put_time_spent(stats)` | Requires a GitLab API object (live or mocked) |
| Main script block (`if __FILE__ == $0`) | Requires GitLab API, file I/O, and environment variables |
| GitLab API integration | Network-dependent; covered by E2E tests |
| CSV generation and field delimiter | File I/O; covered by E2E tests |
| Environment variable reading | Covered by E2E tests |
| Markdown (`Timesheets.md`) output | Covered by E2E tests |
| `minutes_from_note` with only days (`"add 2d"`) | Edge case – no `h`/`m` component |
| `minutes_from_note` with only hours (`"add 3h"`) | Edge case – no `d`/`m` component |

> **Note:** `minutes_from_note` does not validate that its input matches the time-spent pattern (`/\A(sub\|add).*of time spent/i`). It relies on the caller to pre-filter notes with that regex (as the main script does). Passing an arbitrary string that happens to contain digit–unit patterns (e.g. `"worked 2h"`) will return a non-zero value. This is acceptable given the current usage but worth noting.

## End-to-End Tests

E2E tests live in `.github/workflows/e2e.yml`.

### Required GitHub Environment: `Test`

| Name | Type | Description |
|------|------|-------------|
| `GITLAB_ISSUE` | Variable | Issue IID in the test project used for posting test notes |
| `OUTFILE` | Variable | Filename for the generated CSV output |
| `FIELD_DELIMITER` | Variable | CSV field delimiter character |
| `GITLAB_API_ENDPOINT` | Secret | GitLab API base URL (e.g. `https://gitlab.com/api/v4`) |
| `GITLAB_API_PRIVATE_TOKEN` | Secret | GitLab personal access token with API scope |
| `GITLAB_GROUP` | Secret | GitLab group identifier passed to `Timesheets.rb` |
| `GITLAB_PROJECT_URL` | Secret | Full URL of the test GitLab project (used to locate the test issue) |

### Test Scenarios

| Job | Environment | Description |
|-----|-------------|-------------|
| `e2e-happy-path` | `Test` | Posts a time-entry note to the configured GitLab issue, runs `Timesheets.rb`, validates CSV structure and data, then removes the test note. |
| `e2e-missing-endpoint` | *(none)* | Runs the script without `GITLAB_API_ENDPOINT` set and asserts it exits with a non-zero code. |
| `e2e-invalid-credentials` | *(none)* | Runs the script with a syntactically valid but incorrect API token against the public GitLab API and asserts it exits with a non-zero code (HTTP 401). |
