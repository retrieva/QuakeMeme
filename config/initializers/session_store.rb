# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_quakememe_session',
  :secret      => '3b11e816d91296a16492e1e68c434bb6847a3b47a42b1e073f494eb54f2166f5bcf545a252c8656c4341f849e71d82015008c2b5cd17b6232fce7af77773f253'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
