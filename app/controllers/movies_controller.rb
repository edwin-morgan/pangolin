class MoviesController < ApplicationController
  require 'json'
  include SparqlQueries
  before_action :check_params

  def search
    render_cached_data("#{@key}_#{params[@key]}")
    render json: @results
  end

    private

    def render_cached_data(cache_key)
      @results = Rails.cache.fetch(cache_key, {raw: true}) do
        make_query(@key,params[@key]).to_json
      end
    end

    def movie_params
       params.permit(:actor, :film)
    end

    def check_params
      keys = (movie_params.keys & ['actor', 'film'])
      if keys.length == 1
        @key = keys[0].to_sym
      else
      render json: {error: "Can only accept one parameter: 'film' or 'actor'."}
      end
    end
end
