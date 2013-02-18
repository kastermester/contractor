module ApplicationHelper
	class BootstrapFormBuilder < ActionView::Helpers::FormBuilder
		def label(method, text = nil, options = {})
			if options.has_key? :class
				options[:class] += " control-label"
			else
				options[:class] = "control-label"
			end
			super(method, text, options)
		end

		def submit(value = nil, options = {})
			options[:class] = "" unless options[:class]
			options[:class] += " btn btn-success"

			super(value, options)
		end

		def collection_select_for(record, options, value_method, text_method, html_options = {})
			puts @object.class.model_name.i18n_key.inspect
			collection_select record, options, value_method, text_method, html_options
		end

		def control_group_for(record, &block)
			puts @template.class
			raise ArgumentError "Missing block" unless block_given?
			helper = FieldHelper.new self, record
			@template.content_tag("div",
				label(record) + 
				@template.content_tag("div",
					@template.capture(helper, &block),
					:class => "controls"),
				:class => "control-group")
		end

		def editor_for(record, options = {})
			editor = nil
			
			type = @object[record].class

			if @object[record].class == nil.class
				type = String
			end

			inline_editor_into_label = false
			inline_editor_label_class = nil

			puts type.inspect
			if type == String
				if options[:long]
					options.delete :long
					editor = text_area(record, options)
				else
					editor = text_field(record, options)
				end
			elsif type == ActiveSupport::TimeWithZone
				editor = text_field(record, options)
			elsif type == TrueClass || type == FalseClass
				editor = check_box(record, options)
				inline_editor_into_label = true
				inline_editor_label_class = "checkbox"
			end


			if inline_editor_into_label
				@template.content_tag("div",
					@template.content_tag("div",
						@template.content_tag("label",
							(html_encode(text_for(record)) + editor).html_safe,
							:class => inline_editor_label_class),
						:class => "control-group"),
					:class => "controls")
			else
				control_group_for record do
					editor
				end
			end
		end

		def html_encode(str)
			Rack::Utils.escape_html str
		end

		def text_for(record)
			record = record.to_s.dup
			record.gsub!(/\[(.*)_attributes\]\[\d\]/, '.\1')

			key = @object.class.model_name.i18n_key

			i18n_default ||= ""
			I18n.t("#{key}.#{record}", :default => record.humanize, :scope => "helpers.label")
		end

	end

	class BootstrapHorizontalFormBuilder < BootstrapFormBuilder

	end

	class FieldHelper
		def initialize(parent, attribute)
			@parent = parent
			@attribute = attribute
		end
		def method_missing(m, *args, &block)
			method = m.to_s
			method += "_for"
			puts method.inspect
			puts @parent.respond_to? method.to_sym
			arguments = [@attribute].concat(args)
			puts method.inspect
			puts arguments.inspect
			method = method.to_sym
			if @parent.respond_to? method
				@parent.send method, *arguments, &block
			else
				super
			end
		end
	end

	def horizontal_form_for(record, options = {}, &proc)
		unless options.has_key? :html
			options[:html] = {}
		end

		if options[:html].has_key? :class
			options[:html][:class] += " form-horizontal"
		else
			options[:html][:class] = "form-horizontal"
		end

		options[:builder] = BootstrapHorizontalFormBuilder

		form_for(record, options, &proc)
	end
end