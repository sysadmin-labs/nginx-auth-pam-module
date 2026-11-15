# nginx-auth-pam-module

[![Build][build-test-badge]][build-test-link]
[![Lint][lint-badge]][lint-link]
[![CodeQL][codeql-badge]][codeql-link]
[![A/UBSan][sanitizers-badge]][sanitizers-link]
[![Valgrind][valgrind-badge]][valgrind-link]
[![Reload][reload-badge]][reload-link]
[![FreeBSD][freebsd-badge]][freebsd-link]

[build-test-badge]: https://github.com/sysadmin-labs/nginx-auth-pam-module/actions/workflows/build-test.yml/badge.svg
[build-test-link]: https://github.com/sysadmin-labs/nginx-auth-pam-module/actions/workflows/build-test.yml
[lint-badge]: https://github.com/sysadmin-labs/nginx-auth-pam-module/actions/workflows/lint.yml/badge.svg
[lint-link]: https://github.com/sysadmin-labs/nginx-auth-pam-module/actions/workflows/lint.yml
[codeql-badge]: https://github.com/sysadmin-labs/nginx-auth-pam-module/actions/workflows/codeql.yml/badge.svg
[codeql-link]: https://github.com/sysadmin-labs/nginx-auth-pam-module/actions/workflows/codeql.yml
[sanitizers-badge]: https://github.com/sysadmin-labs/nginx-auth-pam-module/actions/workflows/sanitizers.yml/badge.svg
[sanitizers-link]: https://github.com/sysadmin-labs/nginx-auth-pam-module/actions/workflows/sanitizers.yml
[valgrind-badge]: https://github.com/sysadmin-labs/nginx-auth-pam-module/actions/workflows/valgrind.yml/badge.svg
[valgrind-link]: https://github.com/sysadmin-labs/nginx-auth-pam-module/actions/workflows/valgrind.yml
[reload-badge]: https://github.com/sysadmin-labs/nginx-auth-pam-module/actions/workflows/reload.yml/badge.svg
[reload-link]: https://github.com/sysadmin-labs/nginx-auth-pam-module/actions/workflows/reload.yml
[freebsd-badge]: https://github.com/sysadmin-labs/nginx-auth-pam-module/actions/workflows/freebsd.yml/badge.svg
[freebsd-link]: https://github.com/sysadmin-labs/nginx-auth-pam-module/actions/workflows/freebsd.yml

HTTP Basic authentication in nginx against PAM, so a location can be opened
to the accounts the system already knows instead of a password file kept
beside them.

## Requirements

nginx 1.28 or newer, and PAM. On FreeBSD PAM is in the base system; on
Debian and Ubuntu it is `libpam0g-dev`.

## Building

```sh
./configure --add-module=/path/to/nginx-auth-pam-module
```

As a loadable module, `--add-dynamic-module=` and then

```nginx
load_module modules/ngx_http_auth_pam_module.so;
```

## Quick start

```nginx
location /private/ {
    auth_pam              "Restricted";
    auth_pam_service_name "nginx";
}
```

`/etc/pam.d/nginx` decides what counts as a valid account. nginx normally
runs unprivileged, so a stack that reads `/etc/shadow` will not work
without help; `pam_unix` through a helper, LDAP or Kerberos will.

## Directives

### auth\_pam

|Syntax |`auth_pam realm \| off`|
|-------|---|
|Default|`off`|
|Context|http, server, location, limit\_except|

The realm to send in `WWW-Authenticate`, which switches the module on.
`off` switches it off again in a nested location. The realm may contain
variables.

### auth\_pam\_service\_name

|Syntax |`auth_pam_service_name name`|
|-------|---|
|Default|`nginx`|
|Context|http, server, location, limit\_except|

The PAM service to authenticate against, meaning the file of that name
under `/etc/pam.d`.

### auth\_pam\_set\_pam\_env

|Syntax |`auth_pam_set_pam_env on \| off`|
|-------|---|
|Default|`off`|
|Context|http, server, location, limit\_except|

Pass the request's own details into the PAM environment, so a module in
the stack can see them: `REMOTE_ADDR`, `REMOTE_PORT`, `SERVER_ADDR`,
`SERVER_PORT`, `SERVER_NAME`, `REQUEST_METHOD` and `REQUEST_URI`.

## Testing

```sh
ci/build.sh 1.30.6 /tmp/nginx-test
TEST_NGINX_BINARY=/tmp/nginx-test/sbin/nginx prove -r t/
ci/reload.sh /tmp/nginx-test/sbin/nginx
```

The suite does not authenticate anybody, which would need a PAM service
and an account on the machine running it. It asks what nginx accepts, and
that a request without credentials is refused with this module's realm in
the challenge.

## License

BSD 2-Clause. See `LICENSE`.
