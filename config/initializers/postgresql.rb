class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  def supports_disable_referential_integrity?
    false
  end
end
