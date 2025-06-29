Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # Defines the root path route ("/")
  root 'static_pages#top'
  resources :guests, only: %i[new create]
  resources :promises, only: %i[new create show edit update] do
    member do
      get :approve                 # offeree承認画面
      patch :perform_approve     # offeree承認実行
      patch :perform_reject
      get :witnesse        # witnesse立会画面
      patch :perform_witnesse # witnesse立会実行
      get :confirm
      get :complete_form
      post :submit_completion
      patch :submit_completion
      get :review_completion
      patch :accept_completion
      patch :reject_completion
      patch :completion_witnesse
    end
  end
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
