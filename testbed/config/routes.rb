Rails.application.routes.draw do

  match '/', :to                                     => 'surveyor#index', :as    => 'available_surveys', :via => :get
  match '/:survey_code/new', :to                     => 'surveyor#new', :as    => 'take_anonymous', :via => :get
  match '/:survey_code', :to                         => 'surveyor#create', :as => 'take_survey', :via       => :post
  match '/:survey_code', :to                         => 'surveyor#export', :as => 'export_survey', :via     => :get
  match '/:survey_code/:response_set_code', :to      => 'surveyor#show', :as   => 'view_my_survey', :via    => :get
  match '/:survey_code/:response_set_code/take', :to => 'surveyor#edit', :as   => 'edit_my_survey', :via    => :get
  match '/:survey_code/:response_set_code', :to      => 'surveyor#update', :as => 'update_my_survey', :via  => :put

  mount Surveyor::Engine => "/surveys", :as => "surveyor"

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
