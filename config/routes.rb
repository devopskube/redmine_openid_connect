# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'oic', to: 'account#oic'
get 'oic_reauthorize', to: 'account#oic_reauthorize'
get 'rpiframe', to: 'account#rpiframe'
