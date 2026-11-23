# Memory

Memories are a staging buffer, not a destination.

Before writing a memory, check whether a skill or a `.claude/rules/` file already covers it.
If one does, don't write the memory.

If it belongs in a skill or rule but isn't there yet, say so and offer to put it there instead.
Write the memory only when the fact is genuinely transient, or when stopping to edit a skill
would derail the work in progress — and when you do, note in the memory that it is awaiting
promotion.

When a memory does reach a durable home, delete the memory file and its `MEMORY.md` index
line as part of that same change. Don't leave promoted memories to a later sweep.

Batching the deletions turns a series of small reversible steps into one large irreversible
one, and it leaves the index describing files that no longer say anything new. Promoting and
deleting together also verifies itself: a memory still listed in the index is a promotion that
did not finish.

Before deleting, check the memory's body against the text that absorbed it, not its
description. Check the codebase too, not only skills and rules — a NOTE comment sitting on the
config it governs is often the better home, and it is easy to miss when only skills are
searched.
