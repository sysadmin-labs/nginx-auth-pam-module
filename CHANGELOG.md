# Changelog

## Unreleased

First release from this repository. It continues Sergio Talens-Oliag's
module, whose history is intact here; his repository has had no commit
since June 2023.

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
  writes. Measured: 23 bytes allocated, 24 written.
- **The allocation was not checked.** Out of memory meant writing to a
  null pointer, which is what gcc reports as a null destination under
  `-Wformat-overflow` and what made the sanitizer build fail. The copy
  helper had the same omission.

`sprintf` is gone in favour of `ngx_snprintf` with the size, so the length
and the buffer cannot drift apart again.

### Added

- Continuous integration against nginx 1.28, 1.30 and 1.31, statically and
  dynamically, with sanitizers, valgrind, CodeQL, a reload gate and a
  FreeBSD run.
- `t/00-directives.t` for what the directives accept and refuse, for the
  two cases above, and for the one request that reaches the PAM
  environment code at all -- so the sanitizers and valgrind have it in
  front of them.

### Changed

- Sources moved to `src/`.
- `config` uses the `auto/module` form only; the pre-1.9.11 branch it
  carried alongside could not build a loadable module.
