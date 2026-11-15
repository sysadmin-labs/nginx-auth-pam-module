# The directives parse, and the refusals happen where they should.
#
# None of this authenticates anybody: that needs a PAM service and a user,
# which belongs in a test on a machine that has both.  What is asked here
# is what nginx accepts, and that the module refuses a request before it
# ever reaches PAM when there are no credentials.

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
        return 200 "never reached\n";
    }
--- request
GET /t
--- error_code: 401



=== TEST 2: the realm comes back in the challenge
--- config
    location /t {
        auth_pam              "a realm of its own";
        auth_pam_service_name "nginx-test";
        return 200 "never reached\n";
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
            return 200 "never reached\n";
        }
    }
--- request
GET /outer/inner
--- error_code: 401
--- response_headers
WWW-Authenticate: Basic realm="inherited realm"



=== TEST 5: credentials that PAM cannot know are refused, not accepted
--- config
    location /t {
        auth_pam              "test realm";
        auth_pam_service_name "nginx-no-such-service";
        return 200 "never reached\n";
    }
--- more_headers
Authorization: Basic bm9ib2R5Ondyb25n
--- request
GET /t
--- error_code: 403
