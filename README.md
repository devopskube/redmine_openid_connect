# Redmine OpenID Connect Plugin #

**Note** *This plugin is at the moment, a proof of concept (POC). Further coding needs to be added to ensure security.*

## Introduction ##
This 

## Usage ##
1. Go to your Redmine plugins directory.
2. Clone/copy this plugin.
3. Restart your server
4. Login as administrator and head over to the plugins page.
5. Fill in the details.
6. Go to your SSO server and add this url as a registered login url:

```
http(or s)://your-host-url/has_authorization
```
7. Also add in your host to the registered logout url:
```
http(or s)://your-host-url
```

Enjoy!
