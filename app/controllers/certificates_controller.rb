class CertificatesController < ApplicationController
	# GET /certificates
	# GET /certificates.json
	def index
		@certificates = Certificate.all

		respond_to do |format|
			format.html # index.html.erb
			format.json { render json: @certificates }
		end
	end

	# GET /certificates/1
	# GET /certificates/1.json
	def show
		@certificate = Certificate.find(params[:id])

		respond_to do |format|
			format.html # show.html.erb
			format.json { render json: @certificate }
			format.crt { render text: @certificate.full_certificate }
			format.key { render text: @certificate.pem_private_key }
		end
	end

	# GET /certificates/new
	# GET /certificates/new.json
	def new
		@certificate = Certificate.new
		@issuer_certificates = Certificate.where("is_ca")
		@issuer_certificates.prepend(Certificate.new(:id => 0, :name => "None"))

		respond_to do |format|
			format.html # new.html.erb
			format.json { render json: @certificate }
		end
	end

	# POST /certificates
	# POST /certificates.json
	def create
		params[:certificate].delete :issuer_certificate if params[:certificate][:issuer_certificate] == ""
		params[:certificate][:issuer_certificate] = Certificate.find(params[:certificate][:issuer_certificate]) if params[:certificate].has_key? :issuer_certificate
		params[:certificate].inspect
		@certificate = Certificate.new(params[:certificate])

		expires_timewithzone = @certificate.expires

		valid_for_time = expires_timewithzone - Time.zone.now

		puts @certificate.is_ca.inspect
		ssl_hash = { :common_name => @certificate.common_name, :email => @certificate.email, :valid_for_days => valid_for_time / (60*60), :is_ca => @certificate.is_ca, :key_size => 4096 }

		if @certificate.issuer_certificate == nil
			serial = 1
			@certificate.serial = serial
		else
			@certificate.issuer_certificate.child_last_serial += 1
			serial = @certificate.issuer_certificate.child_last_serial
			@certificate.issuer_certificate.save
			@certificate.serial = serial
			issuer_cert = SslHelper.load_certificate @certificate.issuer_certificate.pem_certificate
			issuer_key = SslHelper.load_key @certificate.issuer_certificate.pem_private_key
			ssl_hash[:issuer] = issuer_cert
			ssl_hash[:issuer_key] = issuer_key
			ssl_hash[:crl_uri] = "http://test.dk"
		end

		if @certificate.is_ca
			@certificate.child_last_serial = 1
		end
		ssl_hash[:serial] = serial

		cert = SslHelper.generate_certificate ssl_hash

		@certificate.pem_private_key = cert[:key].to_pem
		@certificate.pem_certificate = cert[:certificate].to_pem

		respond_to do |format|
			if @certificate.save
				format.html { redirect_to @certificate, notice: 'Certificate was successfully created.' }
				format.json { render json: @certificate, status: :created, location: @certificate }
			else
				format.html { render action: "new" }
				format.json { render json: @certificate.errors, status: :unprocessable_entity }
			end
		end
	end

	# GET /certificates/1/crl
	def crl
		@certificate = Certificate.find(params[:id])
		
	end

	# DELETE /certificates/1
	# DELETE /certificates/1.json
	def destroy
		@certificate = Certificate.find(params[:id])
		@certificate.destroy

		respond_to do |format|
			format.html { redirect_to certificates_url }
			format.json { head :no_content }
		end
	end
end
