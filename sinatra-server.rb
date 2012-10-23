require "rubygems"
require "sinatra"
require "net/http"

set :port, 12345
	# force a refresh every time for development purposes
set :static_cache_control, :no_cache

before do
	if ARGV[0] && ARGV[0].downcase == "dev"
		puts "Pointing at DEV ---------------------------------------"
		@_server_name = "usdevexxl05"
		@_root_path = "/MobileSvc"
	else
		puts "Pointing at LAB ---------------------------------------"
		@_server_name = "169.153.190.47"
		@_root_path = "/RestAPI"
	end

	@delay = 0
	if ARGV[0] && ARGV[0].to_i > 0
		@delay = ARGV[0].to_i
	end

	@_server_port = 80
	@test_server_name = "localhost"
	@test_server_port = 4567
	@test_root_path = ""
	@test_users = ['50546', '38053', '38054', '98765', '9999']

	cache_control :no_cache #:public, :must_revalidate, :max_age => 1800
	# setup_auth if request.path_info.start_with? '/api/'

	# if request.request_method == "GET" and not @is_test_user and not @noAuth
	# 	puts 'Caching Enabled'
	# 	cache_control :public, :must_revalidate, :max_age => 1800
	# else
	# 	cache_control :no_cache #:public, :must_revalidate, :max_age => 1800
	# end
end

get '/' do
	send_file File.join(settings.public_folder, 'home.html')
end

# forward api requests to the sinatra test server for accessTD
get '/api/*' do
	setup_auth
	puts "Server: #{server_name} #{server_port}, test user? #{@is_test_user}, market #{request.env['HTTP_X_CUSTOMER_ORDERLEVEL']}"
	url = params[:splat][0]
	res = Net::HTTP.start(server_name, server_port) do |http|
		puts params[:splat]

		query_string = request.query_string.split('&')
		filtered = []
		query_string.each do |pair|
			key = pair.split('=')[0]
			filtered.push pair unless ['market', 'user'].include? key
		end
		query_string = filtered.join('&')

		get = Net::HTTP::Get.new("#{root_path}/#{url}?#{query_string}")
		set_basic_auth get
		get['User-Agent'] = request['User-Agent']
		get['X-Customer-OrderLevel'] = request.env['HTTP_X_CUSTOMER_ORDERLEVEL']
		get['Accept'] = request.accept[0]
		http.request(get)
	end

	if @delay > 0
		sleep(@delay / 1000)
	end

	theRes = res.body
	puts theRes
	theRes
end

post '/api/*' do
	setup_auth
	req = request.body.read

	puts "Request (Content-Type=#{request.content_type}):"
	puts req

	if @noAuth
		@is_test_user = @test_users.any? { |user| req.include? user }
	end

	url = params[:splat][0]

	puts "Server: #{server_name} #{server_port}, test user? #{@is_test_user}"

	res = Net::HTTP.start(server_name, server_port) do |http|
		post = Net::HTTP::Post.new("#{root_path}/#{url}")
		post.body = req
		post.content_type = request.content_type
		set_basic_auth post
		post['User-Agent'] = request['User-Agent']
		post['Accept'] = request.accept[0]
		post['X-Customer-OrderLevel'] = request['X-Customer-OrderLevel']
		puts "Accept: #{post['Accept']}"
		http.request(post)
	end

	theRes = res.body
	puts theRes
	theRes
end

def setup_auth
	begin
	 	@auth ||= Rack::Auth::Basic::Request.new(request.env)
		@is_test_user = @test_users.include?(@auth.username) 
		@noAuth = @auth.username.to_s == ''
	rescue
		@is_test_user = true
	 	puts "Authentication error"
	 	@noAuth = true
	end
end

def set_basic_auth request
	begin
		unless @auth.username.to_s == ''
			request.basic_auth @auth.username, @auth.credentials[1] 
			puts "Authenticating as #{@auth.username}, #{@auth.credentials[1]}"
		else
			puts "No Authentication credentials provided"
		end
	rescue
	end
end

def server_name
	@is_test_user ? @test_server_name : @_server_name
end

def server_port
	@is_test_user ? @test_server_port : @_server_port
end

def root_path
	@is_test_user ? @test_root_path : @_root_path
end
