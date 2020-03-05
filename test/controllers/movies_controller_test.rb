require 'test_helper'
require 'json'
class MoviesControllerTest < ActionDispatch::IntegrationTest

  def setup
    @actors = ['Cary Grant', "Sean Connery", "Judi Dench", 'Daniel Day-Lewis',
       'Sacha Baron Cohen', 'Helena Bonham Carter', 'Ryan Reynolds', 'Agha', 'Madonna', 'Michelle Williams' ].map { |n| n.gsub(" ","_")}
    @films = ['Home Alone', 'Hellraiser', 'Gangs of New York', 'The Avengers',
      'Die Hard', 'Vertigo', 'The Lord of the Rings'].map { |n| n.gsub(" ","_")}
      Rails.cache.clear
  end

  test "should get movie cast" do
    @actors.each do |actor|
      get root_path, params: { actor: actor }
      assert_response :success
      body = JSON.parse(response.body)
      assert_equal actor.gsub("_"," "), body.keys.first
      get root_path, params: { actor: actor }
      assert_not Rails.cache.read("#{:actor}_#{actor}").nil?
    end
  end

  test "should get actor's movie roles" do
    @films.each do |title|
      get root_path, params: { film: title }
      assert_response :success
      body = JSON.parse(response.body)
      assert_equal title.gsub("_"," "), body.keys.first
      get root_path, params: { film: title }
      assert_not Rails.cache.read("#{:film}_#{title}").nil?
    end
  end

  test "should return error if no data found" do
    title = "XYZ123"
    get root_path, params: { film: title }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "error", body.keys.first
  end

  test "should deal with bad parameter" do
    get root_path, params: { actress: "Judi_Dench" }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "error", body.keys.first
  end

end
