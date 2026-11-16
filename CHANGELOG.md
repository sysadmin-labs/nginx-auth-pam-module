# Changelog

## 1.6.1

First release from this repository, carrying on from upstream's v1.5.5. It
continues Sergio Talens-Oliag's module, whose history is intact here; his
repository has had no commit since June 2023.

This replaces 1.6.0, which was tagged before the tree was tidied and
carries one more fix.

### Fixed

All three are on the `auth_pam_set_pam_env on` path, and none of them is
reachable without it.

- **A request without a Host header took the worker down.**
  `r->headers_in.host` is NULL when the request carried no Host header.
  HTTP/1.1 requires one and nginx refuses a request without it, but
  HTTP/1.0 does not, so the field can be NULL and dereferencing it
  segfaulted the worker. Reachable from the network by anyone:

      printf 'GET /t HTTP/1.0\r\nAuthorization: Basic ...\r\n\r\n'

  answered nothing and the process was gone. `t/00-directives.t` asks for
  it.
- **A one-byte heap overflow on every call.** The buffer for the PAM
  environment entry was sized `strlen(key) + strlen(value) + 1`, which is
  one short of the `key`, `=`, `value` and terminator that `sprintf`
  writes. Measured: 23 bytes allocated, 24 written. No sanitizer saw it,
  because `ngx_palloc` hands out a slice of a pool block the allocator
  sees as one piece; the sanitizer workflow now builds with
  `-DNGX_DEBUG_PALLOC=1`, which sends every allocation straight to malloc
  and puts this one in front of ASan. TEST 6 and TEST 7 walk this code,
  so that run covers it.
- **The allocation was not checked.** Out of memory meant writing to a
  null pointer, which is what gcc reports as a null destination under
  `-Wformat-overflow` and what made the sanitizer build fail. The copy
  helper had the same omission.
- **A failed `pam_set_item(PAM_RHOST)` leaked the PAM handle.** Every
  other way out of `ngx_http_auth_pam_authenticate` ends the transaction
  with `pam_end`; that one path returned 500 without it, leaving the
  handle and the PAM modules it had loaded in the worker for the rest of
  its life. The return value of the copy helper was not checked there
  either, so a failed allocation handed NULL to `pam_set_item`.

`sprintf` is gone in favour of `ngx_snprintf` with the size, so the length
and the buffer cannot drift apart again.

### Added

- Continuous integration against nginx 1.28, 1.30 and 1.31, statically and
  dynamically, with sanitizers, valgrind, CodeQL, a reload gate and a
  FreeBSD run.
- `t/00-directives.t` for what the directives accept and refuse, for the
  Host header case above, and for the one request that reaches the PAM
  environment code at all -- so the sanitizers and valgrind have it in
  front of them. The one-byte overflow has no gate of its own in `t/`:
  a pool allocation is invisible to a sanitizer, which is what
  `-DNGX_DEBUG_PALLOC=1` in the sanitizer workflow is for.

### Changed

- Sources moved to `src/`.
- The sanitizer workflow builds with `-DNGX_DEBUG_PALLOC=1` and collects
  the reports through `log_path`. nginx redirects its own stderr onto the
  error log file as soon as `error_log` names one, and Test::Nginx always
  names one, so reports written to stderr were lost: ASan was noticed
  only through the worker dying, and UBSan not at all.
- `config` uses the `auto/module` form only; the pre-1.9.11 branch it
  carried alongside could not build a loadable module.
