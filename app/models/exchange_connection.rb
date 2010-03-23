class ExchangeConnection
  
  # This could easily have been included in the ExchangeService class.
  # Having a separate connection class made it easy to mock the connection
  # in the exchange service tests. 
  
  def initialize(user, password, endpoint)
    @user, @password, @endpoint = user, password, endpoint
  end
  
  # Uses cURL to connect to the EWS server.
  # Passes the Soap XML document as the data.
  def connect(xml_doc)
    wsdl = `curl -u #{@user}:#{@password} -L #{@endpoint} -d "#{xml_doc.write}" -H "Content-Type:text/xml" --ntlm` 
  end
  
end