# Changelog

## 0.9.6

* Fix an issue where existing admins lose their privileges if 
  an admin group is not defined
* Fix 500 error if the OpenID scope was empty
* Fix 500 error when deleting a user that logged in via OpenID
* Add the ability to enable or disable global logout
* Add better information in the plugin setup page

## 0.9.5
* Pull server-side errors from locale files
* Log-messages/some less prominent errors hard-coded in English again 
* Do not render `rpiframe`, if OpenID config does not contain a `check_session_iframe`
* Some more documentation about setting up

## 0.9.4
* Support Redmine 4
* Upgrade deprecated calls

## 0.9.3
* fix problem with symbols vs. strings usage

## 0.9.2
* fix settings page
* move to github
* Avoid error if members_of is empty during check
* Add disable ssl validation
* Add protocol to hostname
