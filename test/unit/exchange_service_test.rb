require File.dirname(__FILE__) + '/../test_helper'

class ExchangeServiceTest < ActiveSupport::TestCase
  
  
  # Tests using a mock connection.  --------------------------------------------
  # The mock connection allows me to test some specific failure and success variations.
  
  context "Creating an event with ExchangeService instance returns successfully" do
    setup do
     @connection = mock('ExchangeConnection')
     @connection.stubs(:connect).returns(%{
      <?xml version="1.0" encoding="utf-8" ?>
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <soap:Header>
          <t:ServerVersionInfo MajorVersion="8" MinorVersion="0" MajorBuildNumber="685" MinorBuildNumber="8" 
                               xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" />
        </soap:Header>
        <soap:Body>
          <CreateItemResponse xmlns:m="http://schemas.microsoft.com/exchange/services/2006/messages" 
                              xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" 
                              xmlns="http://schemas.microsoft.com/exchange/services/2006/messages">
            <m:ResponseMessages>
              <m:CreateItemResponseMessage ResponseClass="Success">
                <m:ResponseCode>NoError</m:ResponseCode>
                <m:Items>
                  <t:CalendarItem>
                    <t:ItemId Id="AAAlAFV" ChangeKey="DwAAABYA" />
                  </t:CalendarItem>
                </m:Items>
              </m:CreateItemResponseMessage>
            </m:ResponseMessages>
          </CreateItemResponse>
        </soap:Body>
      </soap:Envelope>
      })
      ExchangeConnection.expects(:new).returns(@connection)
      @es = ExchangeService.new
      @event =  events(:one)
    end
    
    should "fill appointment ids and return true when creating a EWS event" do
      assert @es.create_event_in_ews(@event)
    end
    
    should "have an appointment id" do
      @es.create_event_in_ews(@event)
      assert_equal "AAAlAFV", @es.appointment_id
    end
  
    should "not fail if the task has no name or location" do
      event = events(:three)
      @es.create_event_in_ews(event)
      assert_equal "AAAlAFV", @es.appointment_id
    end
  end
  
  context "Creating an event with ExchangeService instance returns an error" do
    setup do
     @connection = mock('ExchangeConnection')
     @connection.stubs(:connect).returns(%{
      <?xml version="1.0" encoding="utf-8" ?>
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <soap:Header>
          <t:ServerVersionInfo MajorVersion="8" MinorVersion="0" MajorBuildNumber="685" MinorBuildNumber="8" 
                               xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" />
        </soap:Header>
        <soap:Body>
          <CreateItemResponse xmlns:m="http://schemas.microsoft.com/exchange/services/2006/messages" 
                              xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" 
                              xmlns="http://schemas.microsoft.com/exchange/services/2006/messages">
            <m:ResponseMessages>
              <m:CreateItemResponseMessage ResponseClass="Error">
                <m:MessageText>The specified object was not found in the store.</m:MessageText>
                <m:ResponseCode>ErrorItemNotFound</m:ResponseCode>
                <m:DescriptiveLinkKey>0</m:DescriptiveLinkKey>
              </m:CreateItemResponseMessage>
            </m:ResponseMessages>
          </CreateItemResponse>
        </soap:Body>
      </soap:Envelope>
      })
      ExchangeConnection.expects(:new).returns(@connection)
      @es = ExchangeService.new
      @event =  events(:two)
    end
    
    should "return false" do
      assert !@es.create_event_in_ews(@event)
    end
    
    should "have errors" do
      @es.create_event_in_ews(@event)
      error_string = "EWS appointment creation failed. Status: Error. Response code: ErrorItemNotFound. The specified object was not found in the store."
      assert_equal error_string, @es.errors.join("")
    end
  end
  
  context "Creating an event with ExchangeService returns unexpected result" do
    setup do
     @connection = mock('ExchangeConnection')
     @connection.stubs(:connect).returns(%{
      <?xml version="1.0" encoding="utf-8" ?>
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <soap:Header>
          <t:ServerVersionInfo MajorVersion="8" MinorVersion="0" MajorBuildNumber="685" MinorBuildNumber="8" 
                               xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" />
        </soap:Header>
        <soap:Body>
          <SomeResponse xmlns:m="http://schemas.microsoft.com/exchange/services/2006/messages" 
                              xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" 
                              xmlns="http://schemas.microsoft.com/exchange/services/2006/messages">
            <m:SomeResponseMessages>
              <m:SomeItemResponseMessage ResponseClass="Error">
                <m:MessageText>The specified object was not found in the store.</m:MessageText>
                <m:ResponseCode>ErrorItemNotFound</m:ResponseCode>
                <m:DescriptiveLinkKey>0</m:DescriptiveLinkKey>
              </m:SomeItemResponseMessage>
            </m:SomeResponseMessages>
          </SomeResponse>
        </soap:Body>
      </soap:Envelope>
      })
      ExchangeConnection.expects(:new).returns(@connection)
      @es = ExchangeService.new
      @event =  events(:one)
    end
    
    should "return false" do
      assert !@es.create_event_in_ews(@event)
    end
    
    should "have errors" do
      @es.create_event_in_ews(@event)
      error_string = "Uh-oh, there was an XML exception: You have a nil object when you didn't expect it!\nThe error occurred while evaluating nil.attribute."
      assert_equal error_string, @es.errors.join("")
    end
  end
  
  context "Creating an event with ExchangeService returns invalid xml" do
    setup do
     @connection = mock('ExchangeConnection')
     @connection.stubs(:connect).returns(%{
      <?xml version="1.0" encoding="utf-8" ?>
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
                     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                     xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <soap:Header>
          <invalid>Hi</notvalid>
        </soap:Header>
        <soap:Body>
          <alsobad>This is bad.</sobad>
        </soap:Body>
      </soap:Envelope>
      })
      ExchangeConnection.expects(:new).returns(@connection)
      @es = ExchangeService.new
      @event =  events(:one)
    end
    
    should "return false" do
      assert !@es.create_event_in_ews(@event)
    end
    
    should "have errors" do
      @es.create_event_in_ews(@event)
      assert @es.errors.join("").include?("ParseException")
    end
  end
  
  # Testing the delete event method --------------------------------------------
  
  context "Deleting an event with ExchangeService instance returns successfully" do
    setup do
     @connection = mock('ExchangeConnection')
     @connection.stubs(:connect).returns(%{
       <?xml version="1.0" encoding="utf-8" ?>
       <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
                      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                      xmlns:xsd="http://www.w3.org/2001/XMLSchema">
         <soap:Header>
           <t:ServerVersionInfo MajorVersion="8" MinorVersion="0" MajorBuildNumber="595" MinorBuildNumber="0" 
                                xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" />
         </soap:Header>
         <soap:Body>
           <DeleteItemResponse xmlns:m="http://schemas.microsoft.com/exchange/services/2006/messages" 
                               xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" 
                               xmlns="http://schemas.microsoft.com/exchange/services/2006/messages">
             <m:ResponseMessages>
               <m:DeleteItemResponseMessage ResponseClass="Success">
                 <m:ResponseCode>NoError</m:ResponseCode>
               </m:DeleteItemResponseMessage>
             </m:ResponseMessages>
           </DeleteItemResponse>
         </soap:Body>
       </soap:Envelope>
      })
      ExchangeConnection.expects(:new).returns(@connection)
      @es = ExchangeService.new
      @events = []
      event =  events(:one)
      @events << event
    end
    
    should "fill delete an appointment in EWS" do
      assert @es.delete_event_in_ews(@events)
    end
  end
  
  context "Deleting an event with ExchangeService instance returns an errer" do
    setup do
     @connection = mock('ExchangeConnection')
     @connection.stubs(:connect).returns(%{
       <?xml version="1.0" encoding="utf-8" ?>
       <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
                      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                      xmlns:xsd="http://www.w3.org/2001/XMLSchema">
         <soap:Header>
           <t:ServerVersionInfo MajorVersion="8" MinorVersion="0" MajorBuildNumber="595" MinorBuildNumber="0" 
                                xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" />
         </soap:Header>
         <soap:Body>
           <DeleteItemResponse xmlns:m="http://schemas.microsoft.com/exchange/services/2006/messages" 
                               xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" 
                               xmlns="http://schemas.microsoft.com/exchange/services/2006/messages">
             <m:ResponseMessages>
               <m:DeleteItemResponseMessage ResponseClass="Error">
                 <m:MessageText>The specified object was not found in the store.</m:MessageText>
                 <m:ResponseCode>ErrorItemNotFound</m:ResponseCode>
                 <m:DescriptiveLinkKey>0</m:DescriptiveLinkKey>
               </m:DeleteItemResponseMessage>
             </m:ResponseMessages>
           </DeleteItemResponse>
         </soap:Body>
       </soap:Envelope>
      })
      ExchangeConnection.expects(:new).returns(@connection)
      @es = ExchangeService.new
      @events = []
      event =  events(:one)
      @events << event
    end
    
    should "return false when deleting the event" do
      assert !@es.delete_event_in_ews(@events)
    end
    should "have errors" do
      @es.delete_event_in_ews(@events)
      error_string = "EWS appointment could not be deleted. Status: Error. Response code: ErrorItemNotFound. The specified object was not found in the store."
      assert_equal error_string, @es.errors.join("")
    end
  end
  
  context "Deleting an event with ExchangeService instance returns unexpected result" do
    setup do
     @connection = mock('ExchangeConnection')
     @connection.stubs(:connect).returns(%{
       <?xml version="1.0" encoding="utf-8" ?>
       <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" 
                      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                      xmlns:xsd="http://www.w3.org/2001/XMLSchema">
         <soap:Header>
           <t:ServerVersionInfo MajorVersion="8" MinorVersion="0" MajorBuildNumber="685" MinorBuildNumber="8" 
                                xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" />
         </soap:Header>
         <soap:Body>
           <SomeResponse xmlns:m="http://schemas.microsoft.com/exchange/services/2006/messages" 
                               xmlns:t="http://schemas.microsoft.com/exchange/services/2006/types" 
                               xmlns="http://schemas.microsoft.com/exchange/services/2006/messages">
             <m:SomeResponseMessages>
               <m:SomeItemResponseMessage ResponseClass="Error">
                 <m:MessageText>The specified object was not found in the store.</m:MessageText>
                 <m:ResponseCode>ErrorItemNotFound</m:ResponseCode>
                 <m:DescriptiveLinkKey>0</m:DescriptiveLinkKey>
               </m:SomeItemResponseMessage>
             </m:SomeResponseMessages>
           </SomeResponse>
         </soap:Body>
       </soap:Envelope>
      })
      ExchangeConnection.expects(:new).returns(@connection)
      @es = ExchangeService.new
      @events = []
      event =  events(:one)
      @events << event
    end
    
    should "return false when deleting the event" do
      assert !@es.delete_event_in_ews(@events)
    end
    should "have errors" do
      @es.delete_event_in_ews(@events)
      error_string = "Uh-oh, there was an XML exception: You have a nil object when you didn't expect it!\nThe error occurred while evaluating nil.attribute."
      assert_equal error_string, @es.errors.join("")
    end
  end
  
  context "Deleting an event with ExchangeService instance returns invalid xml" do
    setup do
     @connection = mock('ExchangeConnection')
     @connection.stubs(:connect).returns(%{
       <?xml version="1.0" encoding="utf-8" ?>
         <soap:Body>
          <invalid>This is not valid</notvalid>
         </soap:Body>
       </soap:Envelope>
      })
      ExchangeConnection.expects(:new).returns(@connection)
      @es = ExchangeService.new
      @events = []
      event =  events(:one)
      @events << event
    end
    
    should "return false when deleting the event" do
      assert !@es.delete_event_in_ews(@events)
    end
    should "have errors" do
      @es.delete_event_in_ews(@events)
      error_string = "Uh-oh, there was an XML exception: Undefined prefix soap found."
      assert_equal error_string, @es.errors.join("")
    end
  end
  
  

end