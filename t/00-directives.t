# The directives parse, and the refusals happen where they should.
#
# None of this authenticates anybody: that needs a PAM service and a user,
# which belongs in a test on a machine that has both.  What is asked here
# is what nginx accepts, and that the module refuses a request before it
# ever reaches PAM when there are no credentials.
#
# Note what the protected locations do NOT have: a "return".  return runs
# in the rewrite phase, before the access phase this module sits in, so a
# location with one answers without ever asking the module.  The locations
# below serve a file instead, which happens after access.

use Test::Nginx::Socket 'no_plan';

repeat_each(1);
run_tests();

__DATA__

=== TEST 1: every directive at once
--- config
    location /t {
        auth_pam              "test realm";
        auth_pam_service_name "nginx-test";
        auth_pam_set_pam_env  on;
        root                  html;
    }
--- request
GET /t
--- error_code: 401



=== TEST 2: the realm comes back in the challenge
--- config
    location /t {
        auth_pam              "a realm of its own";
        auth_pam_service_name "nginx-test";
        root                  html;
    }
--- request
GET /t
--- error_code: 401
--- response_headers
WWW-Authenticate: Basic realm="a realm of its own"



=== TEST 3: off turns it off
--- config
    location /t {
        auth_pam off;
        return 200 "through\n";
    }
--- request
GET /t
--- response_body
through
--- error_code: 200



=== TEST 4: a nested location inherits the realm
--- config
    location /outer {
        auth_pam              "inherited realm";
        auth_pam_service_name "nginx-test";

        location /outer/inner {
            root html;
        }
    }
--- request
GET /outer/inner
--- error_code: 401
--- response_headers
WWW-Authenticate: Basic realm="inherited realm"



=== TEST 5: credentials PAM cannot know are refused, not let through
--- config
    location /t {
        auth_pam              "test realm";
        auth_pam_service_name "nginx-no-such-service";
        root                  html;
    }
--- more_headers
Authorization: Basic bm9ib2R5Ondyb25n
--- request
GET /t
# 401 and not 403: PAM refused, and the module asks again rather than
# forbidding, which is what HTTP basic authentication is supposed to do.
# What matters here is that the request did not get through to the file.
--- error_code: 401



=== TEST 6: credentials with the PAM environment turned on
--- config
    location /t {
        auth_pam              "env realm";
        auth_pam_service_name "nginx-no-such-service";
        auth_pam_set_pam_env  on;
        root                  html;
    }
--- more_headers
Authorization: Basic bm9ib2R5Ondyb25n
--- request
GET /t
# This is the one case that reaches set_to_pam_env, which builds
# "KEY=value" into a buffer of its own.  The status is the same 401 as
# without the flag; what this case is for is to walk that code at all, so
# the sanitizers and valgrind have something to look at.
--- error_code: 401



=== TEST 7: HTTP/1.0 without a Host header does not take the worker down
--- config
    location /t {
        auth_pam              "env realm";
        auth_pam_service_name "nginx-no-such-service";
        auth_pam_set_pam_env  on;
        root                  html;
    }
--- raw_request eval
"GET /t HTTP/1.0\r\nAuthorization: Basic bm9ib2R5Ondyb25n\r\n\r\n"
# HTTP/1.1 requires a Host header and nginx refuses a request without
# one, but HTTP/1.0 does not, so r->headers_in.host is NULL here.  With
# auth_pam_set_pam_env on, dereferencing it segfaulted the worker -- no
# answer at all, reachable from the network.
--- response_body_like: 401 Authorization Required
--- error_code: 401
