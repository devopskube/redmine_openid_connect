# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'oic', to: 'account#oic'
get 'oic_reauthorize', to: 'account#oic_reauthorize'
get 'oic/login', to: 'account#oic_login'
get 'oic/logout', to: 'account#oic_logout'
get 'oic/local_login', to: 'account#oic_local_login'
get 'oic/local_logout', to: 'account#oic_local_logout'
get 'oic/rpiframe', to: 'account#rpiframe'
