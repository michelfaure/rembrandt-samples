/**
 * ESLint rule: no-bare-await-on-supabase-mutation
 *
 * Forbids `await supabase.from(X).<insert|update|upsert|delete>(...)` at
 * statement level (i.e. the await result is discarded, neither destructured
 * nor assigned).
 *
 * Why: the Supabase JS client returns `{ data, error }` on every mutation.
 * It does NOT throw. A bare await at statement level silently discards the
 * error and lets the application continue on a wrong assumption. The bug
 * surfaces downstream as an unrelated error.
 *
 * Flagged:
 *   await supabase.from('X').delete().eq('id', id)
 *   await supabase.from('X').insert(payload)
 *   await supabase.from('X').update({ ... }).eq('id', id)
 *   await supabase.from('X').upsert(rows)
 *
 * Not flagged:
 *   const { error } = await supabase.from('X').delete().eq('id', id)
 *   const result = await supabase.from('X').insert(payload)
 *   await supabase.from('X').delete().eq('id', id).throwOnError()
 *   const rows = await supabase.from('X').select('*').order('id')   // not a mutation
 */

const MUTATORS = new Set(['insert', 'update', 'upsert', 'delete'])

// True if the chain (walking through MemberExpressions) contains one of the
// mutation method calls. We walk up the callee chain from the inside out.
function chainContainsMutation(node) {
  let current = node
  while (current && current.type === 'CallExpression' &&
         current.callee && current.callee.type === 'MemberExpression') {
    const propName = current.callee.property && current.callee.property.name
    if (MUTATORS.has(propName)) return true
    current = current.callee.object
  }
  return false
}

// True if the chain ends with `.throwOnError()` somewhere downstream of the
// mutation call. We walk up the parent chain from the AwaitExpression's
// argument.
function chainHasThrowOnError(callNode) {
  let current = callNode
  while (current && current.type === 'CallExpression' &&
         current.callee && current.callee.type === 'MemberExpression') {
    const propName = current.callee.property && current.callee.property.name
    if (propName === 'throwOnError') return true
    current = current.callee.object
  }
  return false
}

const rule = {
  meta: {
    type: 'problem',
    docs: {
      description:
        'Forbid bare awaited Supabase mutations (insert/update/upsert/delete) ' +
        'at statement level; destructure { error } or use .throwOnError().',
    },
    schema: [],
    messages: {
      bare:
        'Bare await on Supabase mutation: the error evaporates silently. ' +
        'Destructure { error } or chain .throwOnError().',
    },
  },
  create(context) {
    return {
      AwaitExpression(node) {
        // Only flag when the await is the entire statement.
        // `const { error } = await ...` and `const r = await ...` are fine.
        if (!node.parent || node.parent.type !== 'ExpressionStatement') return

        const call = node.argument
        if (!call || call.type !== 'CallExpression') return

        if (!chainContainsMutation(call)) return
        if (chainHasThrowOnError(call)) return

        context.report({ node, messageId: 'bare' })
      },
    }
  },
}

export default rule
