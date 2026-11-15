# Changelog

## Unreleased

First release from this repository. It continues Sergio Talens-Oliag's
module, whose history is intact here; his repository has had no commit
since June 2023.

### Added

- Continuous integration against nginx 1.28, 1.30 and 1.31, statically and
  dynamically, with sanitizers, valgrind, CodeQL, a reload gate and a
  FreeBSD run.
- `t/00-directives.t` for what the directives accept and refuse.

### Changed

- Sources moved to `src/`.
- `config` uses the `auto/module` form only; the pre-1.9.11 branch it
  carried alongside could not build a loadable module.
