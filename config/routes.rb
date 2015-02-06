# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'has_authorization', to: 'open_id_connect#has_authorization'
get 'create_or_login_the_account', to: 'account#create_or_login_the_account', as: 'create_or_login_the_account'
