/**
 * ESLint rule: no-unordered-select
 *
 * Forbids `supabase.from(X).select(...)` without an explicit `.order()` or
 * single-row terminator (`.single()`, `.maybeSingle()`, `.csv()`, ...).
 *
 * Rationale: PostgREST applies `Range` + `LIMIT/OFFSET` automatically when
 * `.order()` is absent, falling back to `ORDER BY ctid`. The query is capped
 * at 1000 rows and the ordering is unstable.
 *
 * Safe patterns (not flagged):
 *   - .from('X').select('*').single()
 *   - .from('X').select('*').maybeSingle()
 *   - .from('X').select('*').order('id')...
 *   - .from('X').select('*', { count: 'exact', head: true })
 *   - .from('X').select('*').csv()
 *
 * Flagged patterns:
 *   - .from('X').select('*')                       // no terminator, no order
 *   - .from('X').select('*').eq('y', z)            // filter only, no order
 *   - .from('X').select('*').range(0, 99)          // range without order
 *   - .from('X').select('*').in('id', ids)         // in() without order
 *
 * Five guard mechanisms keep the noise around 40% of the raw signal. Each
 * helper below documents the false-positive class it neutralizes.
 */

const SAFE_TERMINATORS = new Set([
  'order',
  'single',
  'maybeSingle',
  'csv',
  'geojson',
  'explain',
])

// Guard 1: chain must actually be rooted on a `.from()` call.
function chainContainsFromCall(node) {
  let current = node
  while (current && current.type === 'CallExpression' &&
         current.callee && current.callee.type === 'MemberExpression') {
    if (current.callee.property && current.callee.property.name === 'from') {
      return true
    }
    current = current.callee.object
  }
  return false
}

// Guard 2: skip writes followed by .select(). PostgREST insert/update/upsert/
// delete + .select() returns the affected rows in insertion order — no Range
// header, no ORDER BY ctid sort.
function chainContainsWriteBeforeSelect(node) {
  let current = node
  while (current && current.type === 'CallExpression' &&
         current.callee && current.callee.type === 'MemberExpression') {
    const propName = current.callee.property && current.callee.property.name
    if (propName === 'insert' || propName === 'update' ||
        propName === 'upsert' || propName === 'delete') {
      return true
    }
    current = current.callee.object
  }
  return false
}

// Guard 3: skip count-head (`select('*', { count: 'exact', head: true })`).
// No rows are returned, so the Range header is moot.
function selectOptsHasHeadTrue(selectNode) {
  if (selectNode.arguments.length < 2) return false
  const opts = selectNode.arguments[1]
  if (!opts || opts.type !== 'ObjectExpression') return false
  for (const prop of opts.properties) {
    if (prop.type === 'Property' &&
        prop.key && prop.key.name === 'head' &&
        prop.value && prop.value.value === true) {
      return true
    }
  }
  return false
}

// Guard 4: skip when the chain has a safe terminator downstream.
function chainHasSafeTerminator(selectNode) {
  let current = selectNode
  let parent = selectNode.parent
  while (parent) {
    if (parent.type === 'MemberExpression' && parent.object === current) {
      const grandParent = parent.parent
      if (grandParent && grandParent.type === 'CallExpression' &&
          grandParent.callee === parent) {
        const propName = parent.property && parent.property.name
        if (SAFE_TERMINATORS.has(propName)) {
          return true
        }
        current = grandParent
        parent = grandParent.parent
        continue
      }
    }
    break
  }
  return false
}

// Guard 5: skip when the chain is the body of a pagination helper callback.
// The helper injects its own .order() inside. See 03-cursor-pagination.ts.
function chainIsInsidePaginationHelper(selectNode, helperNames) {
  let current = selectNode
  let parent = selectNode.parent
  while (parent) {
    if (parent.type === 'MemberExpression' && parent.object === current) {
      const grandParent = parent.parent
      if (grandParent && grandParent.type === 'CallExpression' &&
          grandParent.callee === parent) {
        current = grandParent
        parent = grandParent.parent
        continue
      }
    }
    while (parent && (parent.type === 'ConditionalExpression' ||
                      parent.type === 'LogicalExpression')) {
      current = parent
      parent = parent.parent
    }
    if (parent && parent.type === 'ArrowFunctionExpression' && parent.body === current) {
      const wrap = parent.parent
      if (wrap && wrap.type === 'CallExpression' &&
          wrap.callee && wrap.callee.type === 'Identifier' &&
          helperNames.has(wrap.callee.name)) {
        return true
      }
    }
    if (parent && parent.type === 'ReturnStatement') {
      let block = parent.parent
      while (block && block.type !== 'BlockStatement') block = block.parent
      const fn = block && block.parent
      if (fn && (fn.type === 'ArrowFunctionExpression' || fn.type === 'FunctionExpression')) {
        const wrap = fn.parent
        if (wrap && wrap.type === 'CallExpression' &&
            wrap.callee && wrap.callee.type === 'Identifier' &&
            helperNames.has(wrap.callee.name)) {
          return true
        }
      }
    }
    break
  }
  return false
}

// Bonus: skip variable-assigned chains. The terminator appears at the await
// site, not at the assignment site. Without data-flow analysis, lint at the
// await site, not here.
function chainEndsAtAssignment(selectNode) {
  let current = selectNode
  let parent = selectNode.parent
  while (parent) {
    if (parent.type === 'MemberExpression' && parent.object === current) {
      const grandParent = parent.parent
      if (grandParent && grandParent.type === 'CallExpression' &&
          grandParent.callee === parent) {
        current = grandParent
        parent = grandParent.parent
        continue
      }
    }
    break
  }
  if (parent && parent.type === 'VariableDeclarator' && parent.init === current) return true
  if (parent && parent.type === 'AssignmentExpression' && parent.right === current) return true
  return false
}

const HELPER_NAMES = new Set(['fetchAll'])

const rule = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Forbid Supabase .from(X).select(...) without .order() / single-row terminator',
    },
    schema: [],
    messages: {
      unorderedSelect:
        'Supabase select() without .order()/.single()/.maybeSingle() falls back to ORDER BY ctid ' +
        '(capped at 1000 rows, unstable order). Add an explicit .order() or single-row terminator.',
    },
  },
  create(context) {
    return {
      CallExpression(node) {
        if (!node.callee || node.callee.type !== 'MemberExpression') return
        if (!node.callee.property || node.callee.property.name !== 'select') return
        if (!chainContainsFromCall(node.callee.object)) return
        if (chainContainsWriteBeforeSelect(node.callee.object)) return
        if (selectOptsHasHeadTrue(node)) return
        if (chainHasSafeTerminator(node)) return
        if (chainEndsAtAssignment(node)) return
        if (chainIsInsidePaginationHelper(node, HELPER_NAMES)) return
        context.report({ node, messageId: 'unorderedSelect' })
      },
    }
  },
}

export default rule
