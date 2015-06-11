require 'sinatra'
require "bundler/setup"
require 'twitter'
require 'twitter_oauth'
# require 'pry'

SITE_URL = "https://twitter.com"

enable :sessions

# for expiring sessions
# use Rack::Session::Cookie, :key => 'rack.session',
#                            :domain => 'foo.com',
#                            :path => '/',
#                            :expire_after => 2592000, # In seconds
#                            :secret => 'change_me'

helpers do
  def twitter
    @twitter ||= Twitter::REST::Client.new do |config|
      config.consumer_key    = ENV.fetch("TWITTER_CONSUMER_KEY")
      config.consumer_secret = ENV.fetch("TWITTER_CONSUMER_SECRET")
    end
  end

  def twitter_oauth
    @oauth ||= OAuth::Consumer.new(
      ENV.fetch("TWITTER_CONSUMER_KEY"),
      ENV.fetch("TWITTER_CONSUMER_SECRET"),
      site: SITE_URL
    )
  end
end

get "/img" do
  min_image_index = ENV.fetch("MIN_IMG_INDEX")
  max_image_index = ENV.fetch("MAX_IMG_INDEX")
  i = (min_image_index..max_image_index).to_a.sample
  redirect to("http://res.cloudinary.com/list101/image/upload/#{i}.png"), 301
end




get "/keys" do
  # binding.pry
  request_token = twitter_oauth.get_request_token
  session[:oauth_request_token] = request_token
  @auth_url = request_token.authorize_url
  erb :accesskeygen, :format => :html5
end

post "/keys" do
  request_token = session[:oauth_request_token]
  redirect '/' and return unless (params[:pin_code] && request_token)

  access_token = request_token.get_access_token(
    oauth_verifier: params[:pin_code]
  )
  @token = access_token.token
  @secret = access_token.secret
  erb :accesskeygen_result
end


post "/shout" do


# To attach multiple images to a tweet, you first need to upload the images using the upload method:

# media_ids = %w(image1.png image2.png image3.png image4.png).map do |filename|
#   Thread.new do
#     twitter_client.upload(File.new(filename))
#   end
# end.map(&:value)
# This will return media IDs, which you can pass into the media_ids parameter (as a comma-separated string) of the update method.

# twitter_client.update("Tweet text", :media_ids => media_ids.join(','))


#another info : http://www.justinball.com/2014/10/09/twitter-update_with_media-and-the-nasty-twitter-error-unauthorized-could-not-authenticate-you-issue/
end


get "/tweets.css" do
  content_type "text/css"
  tweets = twitter.search(ENV.fetch("TWITTER_SEARCH_STRING"))
  tweets.take(15).map.with_index do |tweet, i|
    <<-CSS
      #tweet-#{i + 1} .copy {
        content: "#{tweet.text}";
      }
    CSS
  end
end
