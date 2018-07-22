Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  post 'netflix', to: 'application#netflix'

  post 'netflixcontrol', to: 'application#netflixcontrol'

  post 'bootup', to: 'application#bootup'

  post 'closeprogram', to: 'application#closeprogram'

  post 'shutdown', to: 'application#shutdown'

  post 'restart', to: 'application#restart'
end
