# DNS Performance Test Improvement Plan

## Goals
- [x] Fix hanging/timeout issues and improve reliability.
- [x] Add domain selection menu (RU, Global, All).
- [x] Create user documentation.
- [x] Remove dependency on `bc` (switched to `awk`).
- [x] Improve output alignment and coloring.

## Technical Approach

### 1. Timeout & Reliability (Completed)
- **Implemented:** `dig +tries=2 +time=1`.
- **Fast Fail:** Added a pre-flight check using `dig +short`. If server is unreachable, it is marked as DOWN immediately.

### 2. Domain Selection (Completed)
- **Menu:**
  1. Russian Domains (RU)
  2. Global Domains
  3. All
- **Implementation:** Used `read` and `case` statement.

### 3. Output Improvements (Completed)
- **Colors:** Green (<50ms), Yellow (<150ms), Red (>150ms/Fail).
- **Alignment:** Increased column width to 12 chars.
- **Dependencies:** Replaced `bc` with `awk` for floating point math.

## Documentation
- `README.md` created and updated.
