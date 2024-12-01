# frozen_string_literal: true

module OpenFinanceBrasil
  class Client
    def initialize(bank_number, client_id, client_secret, cert_pem: nil, cert_key: nil)
      puts '[OFB] Client initialized'
      @env            = ENV.fetch('OPEN_FINANCE_ENV', 'sandbox')
      @url            = @env == 'production' ? get_url(bank_number) : get_url_sandbox(bank_number)
      @cnpj           = get_cnpj(bank_number)
      @bank_number    = bank_number
      @client_id      = client_id
      @client_secret  = client_secret
      @cert_path      = certificate_path(cert_pem) if cert_pem
      @cert_key       = cert_key
      puts "[OFB] cert_path: #{@cert_path}"
    end

    def teste
      '[OFB] teste'
    end

    def env(new_env)
      @env = new_env
      @url = new_env == 'production' ? get_url(@bank_number) : get_url_sandbox(@bank_number)
    end

    def list_accounts
      puts '[OFB] list_accounts'
      get_many("/bank_account_information/v1/banks/#{@cnpj}/accounts")
    end

    def account_balance(account_id)
      puts '[OFB] account_balance'
      # get("/accounts/#{account_id}/balance")
    end

    def account_statements(account_id, start_date, end_date)
      puts '[OFB] account_statements'
      get_many("/bank_account_information/v1/banks/#{@cnpj}/statements/#{account_id}?initialDate=#{start_date}&finalDate=#{end_date}")
    end

    def dda_bills
      get('/dda_bills')
    end

    def pay_bill(bill_id, payment_details)
      post("/bills/#{bill_id}/pay", payment_details)
    end

    def make_pix(pix_details)
      post('/pix', pix_details)
    end

    private

    def get_many(endpoint)
      puts '[OFB] get_many'
      puts "[OFB] endpoint: #{endpoint}"

      endpoint = endpoint.include?('?') ? "#{endpoint}&" : "#{endpoint}?"
      list = []
      offset = 1
      loop do
        response = get("#{endpoint}_offset=#{offset}&_limit=50")
        return response['error'] if response['error']

        offset += 1
        list.concat(response['_content'])
        break if response['_pageable']['totalPages'].to_i < offset
      end
      list
    end

    def get(endpoint)
      puts '[OFB] get'
      puts "[OFB] url: #{@url}"
      puts "[OFB] endpoint: #{endpoint}"

      command = <<-CURL
        curl --location "#{@url}#{endpoint}" \
        --cert #{@cert_path} \
        --header 'X-Application-Key: #{@client_id}' \
        --header 'Authorization: Bearer #{token}'
      CURL

      stdout, stderr, status = Open3.capture3(command)
      puts "[OFB] status: #{status}"
      puts "[OFB] stdout: #{stdout}"
      puts "[OFB] stderr: #{stderr}"

      return stdout unless status.success?

      JSON.parse(stdout)
    end

    def post(endpoint, body)
      uri = URI("#{@url}#{endpoint}")
      request = Net::HTTP::Post.new(uri)
      request['Authorization'] = "Bearer #{token}"
      request['Content-Type'] = 'application/json'
      request.body = body.to_json
      # send_request(uri, request)
    end

    def token
      puts '[OFB] token'
      puts "[OFB] @env: #{@env}"
      return @token if @token && @token_expire > Time.now

      url = "#{@url}/auth/oauth/v2/token"
      puts "[OFB] @url: #{@url}"
      puts "[OFB]  url: #{url}"
      puts "[OFB] @client_id: #{@client_id}"
      puts "[OFB] @client_secret: #{@client_secret}"
      puts "[OFB] @cert_path: #{@cert_path}"

      command = <<-CURL
        curl --location #{url} \
        --cert #{@cert_path} \
        --header 'Content-Type: application/x-www-form-urlencoded' \
        --data-urlencode 'client_id=#{@client_id}' \
        --data-urlencode 'client_secret=#{@client_secret}' \
        --data-urlencode 'grant_type=client_credentials'
      CURL

      stdout, _stderr, status = Open3.capture3(command)

      return unless status.success?

      response = JSON.parse(stdout)
      @token = response['access_token']
      @token_expire = Time.now + response['expires_in'] - 5
      @token
    end

    def get_url(bank_number)
      case bank_number
      when '033'
        'https://trust-open.api.santander.com.br'
      end
    end

    def get_url_sandbox(bank_number)
      case bank_number
      when '033'
        'https://trust-sandbox.api.santander.com.br'
      end
    end

    def get_cnpj(bank_number)
      case bank_number
      when '033'
        '90400888000142'
      end
    end

    def certificate_path(certificate)
      full_path = "#{Dir.tmpdir}/#{certificate.filename}"
      File.binwrite(full_path, certificate.download)
      full_path
    end
  end
end
