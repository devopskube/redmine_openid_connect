# Redmine OpenID Connect Plugin #

Based on the work from [intelimina](https://bitbucket.org/intelimina/redmine_openid_connect).

## Introduction ##
This is a plugin based on the implementation of redmine_cas. It redirects to a SSO server bypassing the original Redmine login authentication and using the SSO server authentication in it's place.

## Server Settings  ##
Just include 'username' in the scope being sent and replied to the
client app.

## Usage ##
1. Go to your Redmine plugins directory.
2. Clone/copy this plugin.
3. Run bundle install
4. Run bundle exec rake redmine:plugins:migrate RAILS_ENV=production
5. Restart your server
6. Login as administrator and head over to the plugins page.
7. Open the configuration page for redmine openid connect plugin.
8. Fill in the details.
9. Go to your SSO server and add this url as a registered login url and logout url respectively:

```
http(or s)://your-host-url/oic/local_login
```
```
http(or s)://your-host-url/oic/local_logout
```

## Hints ##

If you enable the OpenId Connect plugin and your OpenId Connect Server is not reachable, but you still would like to login, you can use an additional parameter, to be able to login directly into redmine:

```
http(or s)://your-host-url/login?local_login=true
```

Enjoy!
