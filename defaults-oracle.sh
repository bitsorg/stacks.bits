package: defaults-oracle
version: v1
# Oracle axis (optional): layer this profile (e.g. --defaults gcc15::oracle) to add
# the Oracle DB client packages (oracledb, cx_oracle) to the stack.
#
# Unlike the compiler / cuda axes it sets NO build env and NO append_arch: it does
# not change how any other package builds, so nothing else is rebuilt or published
# to a separate tree. It only flips the `oracle` variable that gates those two
# packages into the dependency graph (via "(?oracle)" in externals.sh); since the
# variable is not part of any other package's env/recipe, their hashes are unchanged.
#
# Oracle's client is Linux-only, so the flag is defined ONLY on non-osx
# (when: "(?!osx)"). On macOS `oracle` stays unset even with this profile layered,
# so "(?oracle)" is false and the packages are skipped — i.e. they build only when
# the oracle flag is set AND we are not on osx.
variables:
  oracle:
    value: "true"
    when: "(?!osx)"
---
