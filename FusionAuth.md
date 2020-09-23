## Connect to fusionAuth

## In FusionAuth

### Add App 

* In Aplications >> Add a new app, choose a name and default options, you just need to pay attention to:

```
Authorized redirect URLs add:  http(or s)://your-host-url/oic/local_login  http(or s)://your-host-url/oic/local_logout

Logout URL: http(or s)://your-host-url/oic/local_logout
```

### Add role

In Application List, select the app and click manage roles, add two roles, User and Admin.



## In Redmine /settings/plugin/redmine_openid_connect

Settings>> Plugins >>Open id

* Just configure id and secret from Application Details in FusionAuth
* OpenID Connect server url: http(or s)://your-fusion-url/
* Scope: openid
* Authorized group: User
* Admins group: Admin

## Add the role to the user

* Just add the role to the users in FusionAuth and thats all, 
* User>>Manage>>Registrations add the app and the desidered role.
* if you choose both roles, Redmine considerer the user as Admin
