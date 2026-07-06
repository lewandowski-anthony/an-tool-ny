# Code Review Guide

## Vision and Philosophy

Code reviews in our team are a collaborative tool designed for learning and knowledge sharing, not an inspection. The primary goals are to maintain the sustainability of our codebase and catch defects before they reach production.

We review the code, not the person. Treat your colleagues with respect, empathy, and constructive honesty.

---

## What to Focus On: Hierarchy of Importance

When reviewing a pull request, your attention should be distributed where it matters most. Do not waste time on minor syntax formatting if the underlying architecture is flawed.

1. High Priority: Architecture, Design Patterns, and Clean Code
    - Does the code respect our architectural boundaries, such as hexagonal architecture or clean code rules?
    - Are responsibilities properly separated? For example, is an infrastructure service handling domain logic?
    - Does the code leverage existing project utilities, or is it reinventing the wheel?

2. High Priority: Security, Performance, and Edge Cases
    - Are there any obvious N+1 query problems in database fetches?
    - Is input validation handled properly at the API contract level?
    - Are resources like streams or connections closed correctly to prevent leaks?

3. Medium Priority: Readability and Tests
    - Is the business logic self-explanatory, or does it require explicit comments?
    - Do test names clearly describe the behavior being verified?
    - Are the test assertions meaningful?

4. Automated: Formatting and Typos
    - Let the continuous integration pipeline handle syntax formatting and linting. Do not argue about code style in PR comments if it passes the automated checks.

---

## Comment Severity Framework

To avoid blocking pull requests over minor differences of opinion, reviewers should use the following prefixes in their comments. This clarifies what must be changed versus what is simply a suggestion.

- [BLOCKER] Major issue. This includes security flaws, broken architecture, or critical bugs. The change is mandatory, and the PR cannot be merged without a fix.
- [SHOULD] Important improvement. This covers missing edge case tests or standard optimizations. The author is expected to resolve or discuss this before merging.
- [SUGGESTION] Alternative approach. This includes architectural refactoring ideas or alternative syntax. The change is optional and left to the author's preference.
- [NITPICK] Minor detail. This covers typos in logs or subtle naming nuances. The change is optional, can be fixed quickly, and should never block a merge.
- [QUESTION] Clarification. Use this to ask for the reasoning behind a specific design choice. A response is required, but it does not automatically mean a code change is necessary.
- [PRAISE] Positive feedback. Use this to highlight elegant solutions, well-written tests, or great code quality to build a healthy engineering culture.

---

## Code Review Etiquette

### For Reviewers
- Explain the reasoning behind your feedback. Never just say "Change this line". Explain why the change is beneficial, for example, how it avoids an unnecessary database query.
- Use questions instead of commands. Instead of saying "Move this to the domain layer", try asking "What do you think about moving this logic into the domain layer to isolate it from the infrastructure?".
- Be mindful of your tone. Text lacks nuance and can easily sound harsh. Be explicit with encouragement when you see good work.

### For Authors
- Do not take feedback personally. Critiques of your code are not a judgment of your value as an engineer.
- Provide context early. If you had to make an unusual architectural choice due to a specific technical limitation, explain it with a self-comment on the pull request before the review starts.
- Resolve conversations properly. Do not simply close a thread. Briefly explain what you changed, or reply if you disagree, then resolve the point together.