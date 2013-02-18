class ApplicationController < ActionController::Base
	protect_from_forgery
	around_filter :wrap_in_transaction

	def wrap_in_transaction
		ActiveRecord::Base.transaction do
			yield
		end
	end
end
