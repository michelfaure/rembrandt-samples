/**
 * Contract test with mandatory negative case (anti-tautology).
 *
 * Source article: Five silent failure modes I codified after 35 effective
 * days of solo ERP coding — Mode 2.
 *
 * Why this file exists
 * --------------------
 * A contract test that only contains positive cases ("DB values are within
 * the declared whitelist") can pass for the wrong reason: the assertion
 * helper itself silently swallows mismatches. On the first ADR-0044 run
 * five contract tests all passed in three seconds. Adding the negative
 * case below revealed that four of the five tests were potemkin — green
 * by construction, with no actual capacity to detect drift.
 *
 * Rule
 * ----
 * Every contract test suite contains at least one negative case that
 * MUST throw. Without it, you don't know whether the suite tests anything.
 * The presence of red is what validates green.
 */

import { describe, it, expect } from 'vitest'

// Replace with your own enum / whitelist constant.
import { ENROLLMENT_VALID_STATUSES } from '@/lib/enrollments/active'

// Replace with your own contract helper. The signature is illustrative.
import { assertEnumStable } from './_helpers'

describe('contract — enrollments.status', () => {
  // Positive: every value present in DB belongs to the whitelist.
  it('every DB value is within ENROLLMENT_VALID_STATUSES', async () => {
    await assertEnumStable({
      table: 'enrollments',
      column: 'status',
      expected: ENROLLMENT_VALID_STATUSES,
      contractRef: 'lib/enrollments/active.ts::ENROLLMENT_VALID_STATUSES',
    })
  })

  // Negative — proves the helper actually fails when DB ⊄ code.
  // Without this test, a buggy helper would render every contract green.
  it('throws when given a deliberately restricted set (anti-tautology)', async () => {
    await expect(
      assertEnumStable({
        table: 'enrollments',
        column: 'status',
        expected: ['enrolled'], // deliberate subset, MUST be detected as drift
        contractRef: '(negative test)',
      }),
    ).rejects.toThrow(/Drift DB ↔ code detected/)
  })
})
