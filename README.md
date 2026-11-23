# Home repo

The global layer for everything I work on: instructions and [Agent Skills](https://agentskills.io) that apply in every repo, unless a repo's own instructions or skills override them. It holds no business or project details, so it stays public.

- `global/CLAUDE.md`: instructions for every repo.
- `skills/`: every skill, flat. Most are mine; the rest are copied from upstream (see Vendored skills).

## Setup, once per machine

```bash
scripts/install.sh
```

It makes two symlinks (link -> what it points at):

```text
$CLAUDE_CONFIG_DIR/CLAUDE.md -> global/CLAUDE.md      (default ~/.claude)
$CLAUDE_CONFIG_DIR/skills    -> skills/
```

Claude Code reads through them into this repo, so `git pull` is the whole update, new skills included. The script never overwrites a real file or folder; move one aside and rerun. Another agent is one more row in the script's `agents` table.

## Vendored skills

`vendor.lock.json` pins each upstream source to a commit and lists the skills copied from it into `skills/`. Their licences are in `licenses/`.

```bash
scripts/vendor.sh --outdated   # which vendored skills upstream has changed since the pin
scripts/vendor.sh              # after editing the lock: recopy at the pinned commit
scripts/vendor.sh --check      # CI: fail if a copy differs from its pinned commit
```

Only changes to the lock need `vendor.sh`; editing my own skills never does. Removing a skill from the lock leaves its folder; delete it in the same change.

## Installing the plugin

```bash
claude plugin marketplace add bellcd/home-repo
claude plugin install bellcd-skills@bellcd
```

Skills then resolve under the plugin's name, e.g. `bellcd-skills:code-style`.

An organization can declare the marketplace once for every member instead,
through the Claude Code managed settings.
That declaration reaches cloud sessions as well as local ones.

A marketplace on a network location has to be declared in user or managed settings.
Project scope cannot vouch for one, so a declaration committed to a repo is ignored.

## Installing one skill without the plugin

The [skills CLI](https://github.com/vercel-labs/skills) installs a single skill into one project,
which is worth it when only that skill is wanted:

```bash
npx skills add bellcd/home-repo --skill code-style
npx skills add bellcd/home-repo --list
```

Add `-g` for a global install.

Keeping those current is per skill.
`update` takes a **skill name**, not a repo, and it only looks where that skill is actually installed:

```bash
npx skills ls -g                  # check what is installed, and where
npx skills update code-style -g   # global install
npx skills update code-style      # project install, run from the project root
```

## Available skills

- [afk-prompt-files](skills/afk-prompt-files/SKILL.md)
- [ag-grid](skills/ag-grid/SKILL.md)
- [artifact-design](skills/artifact-design/SKILL.md)
- [code-style](skills/code-style/SKILL.md)
- [db-normalization](skills/db-normalization/SKILL.md)
- [driving-chrome](skills/driving-chrome/SKILL.md)
- [fetching-web-sources](skills/fetching-web-sources/SKILL.md)
- [git-and-github-hygiene](skills/git-and-github-hygiene/SKILL.md)
- [mobile-push-approvals](skills/mobile-push-approvals/SKILL.md)
- [posthog](skills/posthog/SKILL.md)
- [prose-style](skills/prose-style/SKILL.md)
- [skills-maintenance](skills/skills-maintenance/SKILL.md)
- [tight-feedback-loops](skills/tight-feedback-loops/SKILL.md)

## Releases

An unattended agent should run a reviewed version of a skill,
rather than whatever the default branch happens to serve at that moment.

`claude plugin tag` cuts a version tag for that.
It refuses to tag unless the plugin manifest and the marketplace entry agree on the version:

```bash
claude plugin tag . --dry-run
```

A consumer then pins to the tag.
Both manifests carry the version, so bump them together in the same change.
