Rails.application.routes.draw do

  post 'user' => 'user#new'
  put 'user' => 'user#update'
  get 'user' => 'user#get'
  get 'bots' => 'user#get_bots'
  get 'users' => 'user#list'
  post 'game' => 'game#new'
  post 'game/new' => 'game#start'
  get 'game' => 'game#get'
  get 'invitations' => 'game#invitations'
  post 'event' => 'event#new'
  post 'image' => 'upload#upload'
  get 'import' => 'cardset#import'
  get 'search' => 'cardset#search'
  get 'popular' => 'cardset#popular'
  post 'like' => 'cardset#like'
  post 'unlike' => 'cardset#unlike'
  post 'tag' => 'cardset#put_tag'
  post 'untag' => 'cardset#drop_tag'
  post 'flag' => 'cardset#put_flag'
  post 'unflag' => 'cardset#drop_flag'
  get 'tags' => 'cardset#get_tags'
  get 'info' => 'application#info'
  get 'cardsets' => 'cardset#get'

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
