Nodes::Application.routes.draw do
    resources :auth_keys

    match 'nodes/search/:project(/:logic_expression)(/:status)' => 'search#nodes'
    match 'nodes/create' => 'servers#create', :via => 'post'
    match 'nodes/update' => 'servers#update', :via => 'post'
    match 'nodes/delete' => 'servers#delete', :via => 'post'

    match 'tags/search/:node' => 'search#tags'
    match 'tags/searchsegment/:project/:tag' => 'search#tag_segment'
    match 'tags/taglist/:project/:segment' => 'search#taglist'
    match 'tags/create' => 'tags#create', :via => 'post'
    match 'tags/delete' => 'tags#delete', :via => 'post'
    
	match 'projects/create' => 'projects#create', :via => 'post'
	match 'projects/delete' => 'projects#delete', :via => 'post'

    match 'tagsegments/create' => 'tag_segments#create', :via => 'post'
    match 'tagsegments/delete' => 'tag_segments#delete', :via => 'post'

    match 'preauth/:pubmd5' => 'home#preauth'
    match 'auth' => 'home#auth', :via => 'post'

    root :to => 'home#index'
end
