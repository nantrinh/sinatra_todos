require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def list_complete?(list)
    todos_count(list) > 0 && todos_remaining_count(list).zero?
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todos_remaining_count(list)
    list[:todos].count { |todo| !todo[:completed] }
  end

  def todos_count(list)
    list[:todos].size
  end
end

before do
  session[:lists] ||= []
end

get '/' do
  redirect '/lists'
end

# View list of lists
get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

get '/lists/:list_id' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

get '/lists/:list_id/edit' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  erb :edit_list, layout: :layout
end

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

# Update list
post '/lists/:list_id' do
  list_name = params[:list_name].strip
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = 'The list has been updated.'
    redirect "/lists/#{@list_id}"
  end
end

# Delete list
post '/lists/:list_id/delete' do
  @list_id = params[:list_id].to_i
  session[:lists].delete_at(@list_id)
  session[:success] = 'The list has been deleted.'
  redirect '/lists'
end

# Delete todo item
post '/lists/:list_id/todos/:todo_id/delete' do
  @list_id = params[:list_id].to_i
  @todo_id = params[:todo_id].to_i
  session[:lists][@list_id][:todos].delete_at(@todo_id)
  session[:success] = 'The todo has been deleted.'
  redirect "/lists/#{@list_id}"
end

# Toggle completion of todo item
post '/lists/:list_id/todos/:todo_id' do
  @list_id = params[:list_id].to_i
  @todo_id = params[:todo_id].to_i
  completed = to_boolean(params[:completed])
  session[:lists][@list_id][:todos][@todo_id][:completed] = completed
  session[:success] = "The todo has been updated."
  redirect "/lists/#{@list_id}"
end

# Set all todo items to completed
post '/lists/:list_id/complete_all' do
  @list_id = params[:list_id].to_i
  session[:lists][@list_id][:todos].each do |todo|
    todo[:completed] = true
  end
  session[:success] = "All todos have been completed."
  redirect "/lists/#{@list_id}"
end

def to_boolean(str)
  if str == "true"
    true
  elsif str == "false"
    false
  else
    raise StandardError, "Input must be true or false"
  end
end

# Add todo item to a list
post '/lists/:list_id/todos' do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  todo_name = params[:todo].strip

  error = error_for_todo_name(todo_name)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << { name: params[:todo], completed: false }
    session[:success] = 'The todo item has been added.'
    redirect "/lists/#{@list_id}"
  end
end

# Return an error message if the name is invalid.
# Return nil if name is valid.
def error_for_list_name(name)
  if !(1..100).cover?(name.size)
    'List name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'List name must be unique.'
  end
end

def error_for_todo_name(name)
  'Todo must be between 1 and 100 characters.' unless (1..100).cover?(name.size)
end
