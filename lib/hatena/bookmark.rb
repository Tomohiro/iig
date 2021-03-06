# encoding: utf-8

require 'ostruct'
require 'open-uri'
require 'mechanize'

module Hatena
  class Bookmark
    attr_accessor :cookie_file_path

    def initialize
      @agent = Mechanize.new
      @cookie_file_path = File.expand_path('../../tmp/cookie.yaml', __dir__)
    end

    def login(username, password)
      return load_cookie(@agent) if cookie_exists?

      @agent.get('https://www.hatena.ne.jp/login') do |page|
        response = page.form_with(action: '/login') do |form|
          form.field_with(name: 'name').value = username
          form.field_with(name: 'password').value = password
        end.click_button

        if response.body.include?('The Hatena ID or password you entered does not match our records.')
          raise StandardError.new('Error: failed to loign.')
        end
      end

      save_cookie(@agent)
      @agent
    end

    def interests(username)
      interests = {}
      @agent.get("http://b.hatena.ne.jp/#{username}/interest") do |page|
        page.search('div.interest-sub-unit').each do |interest|
          keyword = interest.at('h2/a').text
          interests[keyword] = []
          interest.search('ul.sub-entry-list/li').each do |entry_dom|
            interests[keyword] << OpenStruct.new(extract_entry_information(entry_dom))
          end
        end
      end
      interests
    end

    private
      def cookie_exists?
        File.exists?(cookie_file_path)
      end

      def load_cookie(agent)
        agent.cookie_jar.load(cookie_file_path)
        agent
      end

      def save_cookie(agent)
        agent.cookie_jar.save_as(cookie_file_path)
      end

      def extract_entry_information(entry_dom)
        {
          title: entry_dom.at('h3/a').attributes['title'].text,
          url:   entry_dom.at('h3/a').attributes['href'].text,
          users: entry_dom.at('span.users').text
        }
      end
  end
end
