require "active_support"
require "active_support/hash_with_indifferent_access"
require "active_support/core_ext/hash/indifferent_access"
require "active_support/core_ext/object/to_query"
require "active_support/core_ext/class/attribute"

module NamedRoutes
  def named_route(*args, &block)
    named_routes.uri(*args, &block)
  end

  alias_method :path, :named_route
  alias_method :route, :named_route
  alias_method :uri, :named_route

  def named_routes
    ::NamedRoutes::Routes
  end

  alias_method :paths, :named_routes
  alias_method :routes, :named_routes
  alias_method :uris, :named_routes

  extend self
end

dir = File.dirname(__FILE__)
require "#{dir}/named-routes/concern"
require "#{dir}/named-routes/routes"
require "#{dir}/named-routes/schemed_uri"
