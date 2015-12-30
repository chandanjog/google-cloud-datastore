if ARGV.empty?
  abort "usage: adams.rb <dataset-id>"
end

client = Google::APIClient.new(
  :application_name => 'adams-ruby',
  :application_version => '1.0.0')
# Build the datastore API client.
datastore = client.discovered_api('datastore', 'v1beta2')

# Get the dataset id from command line argument.
dataset_id = ARGV[0]
# Get the credentials from the environment.
service_account = ENV['DATASTORE_SERVICE_ACCOUNT']
private_key_file = ENV['DATASTORE_PRIVATE_KEY_FILE']

# Load the private key from the .p12 file.
private_key = Google::APIClient::KeyUtils.load_from_pkcs12(private_key_file,
                                                           'notasecret')
# Set authorization scopes and credentials.
client.authorization = Signet::OAuth2::Client.new(
  :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
  :audience => 'https://accounts.google.com/o/oauth2/token',
  :scope => ['https://www.googleapis.com/auth/datastore',
             'https://www.googleapis.com/auth/userinfo.email'],
  :issuer => service_account,
  :signing_key => private_key)
# Authorize the client.
client.authorization.fetch_access_token!

# Start a new transaction.
resp = client.execute(
  :api_method => datastore.datasets.begin_transaction,
  :parameters => {:datasetId => dataset_id},
  :body_object => {})

# Get the transaction handle
tx = JSON.parse(resp.response.body)['transaction']

#resp = client.execute(
  #:api_method => datastore.datasets.lookup,
  #:parameters => {:datasetId => dataset_id},
  #:body_object => {
    ## Set the transaction, so we get a consistent snapshot of the
    ## value at the time the transaction started.
    #:readOptions => {:transaction => tx},
    ## Add one entity key to the lookup request, with only one
    ## :path element (i.e. no parent)
    #:keys => [{:path => [{:kind => 'metrics'}]}]
  #})


entity = {
  # Set the entity key with only one `path` element: no parent.
  :key => {
    :path => [{:kind => 'test_metrics'}]
  },
  # Set the entity properties:
  :properties => {
    :entity_id => {:integerValue => 1},
    :entity_type => {:integerValue => 2},
  }
}
# Build a mutation to insert the new entity.


mutation = {:insert => [entity]}

# Commit the transaction and the insert mutation if the entity was not found.
client.execute(
  :api_method => datastore.datasets.commit,
  :parameters => {:datasetId => dataset_id},
  :body_object => {
    :transaction => tx,
    :mutation => mutation
  })







