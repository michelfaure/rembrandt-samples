# Phase 0 checklist — five questions before letting your agent write

Run this checklist *before* sending a prompt that asks your AI coding agent to write a new component, format, template, or module in a domain that already exists in your codebase. If you can't answer one of the five questions, you haven't done Phase 0 and you're about to throw away a day.

---

## 1. What domain folder is this living in?

Name the directory: `app/<domain>/`, `lib/<domain>/`, `components/<domain>/`. If you can't name one, the domain isn't yet established in the codebase — that's a different kind of project, with different risks.

## 2. What files already exist in that folder?

Run `phase-0-grep.sh <domain>` or equivalent. Get the list on one screen. If the list has more than fifteen files, you're already in a mature domain — the cost of inventing next to existing code is highest here.

## 3. What output verbs are already present?

`Render`, `Export`, `Pdf`, `Generate`, `Build`, `Compose`, `Format`. If any of these verbs already exists in a filename matching the domain, you must read that file before writing.

## 4. Is the existing code reasonable to extend or refactor?

Open the candidate files. Read them. If the existing code can be extended by adding a parameter, a variant, or a new render function — that's almost always cheaper than writing a new file. If the existing code is so tangled that extending feels worse than starting over, *write that down in the prompt* so the agent knows the call has been made deliberately.

## 5. What would the new file add that the existing code can't?

One sentence. If you can't write that sentence, you don't yet know what you're asking for, and the agent will fill the gap with plausible duplication.

---

## When to skip this checklist

Never. The cost of running it is two minutes. The cost of skipping it, when the existing code turns out to handle the case, is empirically one dev-day.

The only legitimate exception is: the domain is being created in this prompt (no folder yet, no existing code, brand new feature). In that case the checklist is replaced by an architecture sketch — but you should still verbalize that the domain is new before asking the agent to generate the first file.
