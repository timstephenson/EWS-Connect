# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_EWS-Connect_session',
  :secret      => '813cacc15587a31357c3b146406d80c02bf759abd5ff4f2fc9b835ff722bbceee3d08fd64d3b2042677cd7cbb441c908a45582395d2c85e707152862c70d6a71'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
