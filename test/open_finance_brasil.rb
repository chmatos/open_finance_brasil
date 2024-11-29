require "minitest/autorun"
require "open_finance_brasil"

class OpenFinanceBrasilTest < Minitest::Test
  def setup
    @client = OpenFinanceBrasil::Client.new("your_api_key", "path_to_cert.pem")
  end

  def test_list_accounts
    response = @client.list_accounts
    assert response == 'list_accounts ok'
    # assert response.is_a?(Array)
  end

  def test_account_balance
    response = @client.account_balance("account_id")
    assert response == 'account_balance ok'
    # assert response.key?("balance")
  end

  # Add more tests for other methods
end