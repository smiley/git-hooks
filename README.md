# git-hooks
A collection of useful git hooks that I've written over time to deal with various SCM issues.

## What are "git hooks"?
[Git hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) are specialized
scripts, run at, before or after specific commands in Git. They can be used for special-use
git repositories, like a `post-receive` hook -- called after `git push` -- which deploys
the code you just pushed. Or a `pre-receive` hook -- called during `git push`, after *sending*
your changes but before the server *applies* them -- used to enforce certain repository policies.

## Hook directory
### Client-side
None yet!

### Server-side
#### `pre-receive` hooks
##### [**Case-insensitive branches**](pre-receive/case-insensitive-branches.sh)
Reject any updates to branches with the same name but different casing, or to non-lowercase branch prefixes.
(which are used by [Atlassian Stash/Bitbucket Server](https://confluence.atlassian.com/bitbucketserver/using-branches-in-bitbucket-server-776639968.html#UsingbranchesinBitbucketServer-Configuringthebranchingmodel))

Git normally stores refs in a folder structure on your filesystem. This is usually OK, except a lot
of us develop on Windows machines. [Files in Windows are case-insensitive](http://superuser.com/a/165980/231123),
and this caused an issue where some developers' workstations would accidentally create a branch prefixed
`Feature` instead of `feature`. This would later propagate to other developers the next time they updated their
clones, and it could rarely affect the prefix itself under `.git\refs\heads`. Future branches would be silently
checked out as `Feature/something` instead of `feature/something`, branches would split in two and Git would
update the wrongly-cased branch (refs suddenly pointing ~50 commits in the past, [SourceTree](https://www.sourcetreeapp.com)
showing this as "50 behind" but git claiming `Everything up-to-date`).

We'd delete the errant branches server-side, but anyone who would push with SourceTree's old default settings
of "all" would just bring them back to life and cause this mess all over again. In the end, we decided to enforce
this programmatically and just decline pushes that would do this, echoing a detailed error that told the person to
change his settings or rename his local branches.
