# Redmine OpenID Connect Plugin #

Based on the work from [intelimina](https://bitbucket.org/intelimina/redmine_openid_connect).

## Introduction ##

This is a plugin based on the implementation of redmine_cas. 

It redirects to an SSO server bypassing the original Redmine login authentication using the SSO server authentication in its place.

## Important ##

User registration is implicit and cannot be disabled at the moment.

So your OpenID provider should probably provide unique endpoints for your needs.

Check out [FusionAuth](https://fusionauth.io/) for an excellent solution.

## Server Settings  ##

Just include `username` in the scope being sent and replied to the client app.

## Usage ##

### Configure Redmine ###

1. Go to your Redmine plugins directory.
2. Clone/copy this plugin.
3. Run `bundle install`
4. Run `bundle exec rake redmine:plugins:migrate RAILS_ENV=production`
5. Restart your server
6. Login as administrator and head over to the plugins page.
7. Open the configuration page for redmine openid connect plugin.
8. Fill in the details.

### Configure Your OpenID Provider ###

1. Go to your SSO server and add these urls as authorized redirect urls:
   * `https://<your-redmine-domain>/oic/local_login`
   * `https://<your-redmine-domain>/oic/local_logout`
2. Check the JWT Token generation. You need the following contents:
   * **`member_of`**: `String[]` of role/group names that your config maps to user properties like *is administrator* or *is authorized to log in*
   * **`user_name`**: `String` with the user's desired username (required for user creation), aliases: `nickname`, `preferred_username`
   * **`given_name`**: `String` with the user's first name (required for user creation)
   * **`family_name`**: `String` with the user's surname (required for user creation)
   * **`name`**: `String` with the user's full name (used as a fallback for first name and surname)
   * Should some of these fields be missing, try finding *Lambda* functions or *Generators* that allow you to customize the JWT Tokens issued

## In Case Your OpenID Provider Is Offline ##

If you enable the OpenId Connect plugin and your OpenId Connect Server is not reachable, but you still would like to login, you can use an additional parameter, to be able to login directly into redmine: 

```https://<your-redmine-domain>/login?local_login=true```

Enjoy!
