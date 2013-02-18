# Load the rails application
require File.expand_path('../application', __FILE__)

require 'active_record/connection_adapters/postgresql_adapter'
NativeDbTypesOverride.configure({
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter => {
    datetime: { name: "timestamptz" },
    timestamp: { name: "timestamptz" }
  }
})


# Initialize the rails application
Contractor::Application.initialize!