class ExchangeService
  attr_accessor :errors, :appointment_id
  
  def initialize
    @errors = []
    @appointment_id = nil
  end
  
  # Creates an event in EWS. If it succeeds, the @appointment_id will be populated with the EWS Item Id.
  # The EWS Item Id is the reference to the event in EWS so that it can be deleted.
  # If it returns false, check the errors array for messages.
  # Params:
  # * event - Should have a name, location, description and start and end times.
  # * target_mailbox - The email address for the calendar the event should go to. If nil, it will go on the calendar of the user the app logs in with.
  # * attendees - An array of email addresses that will be added as attendees.
  def create_event_in_ews(event, target_mailbox = nil, attendee_addresses = [])
    connection = ExchangeConnection.new(APP_CONFIG[:ews_user_name], APP_CONFIG[:ews_user_password], APP_CONFIG[:ews_endpoint])
    begin
      response_doc = REXML::Document.new(connection.connect(create_calendar_item_xml(event, target_mailbox, attendee_addresses)))
      status = REXML::XPath.first(response_doc, '//m:CreateItemResponseMessage').attribute('ResponseClass')
    rescue => e
      @errors << "Uh-oh, there was an XML exception: #{e}."
      return false
    end
    
    if status.to_s != "Success"
      response_code = REXML::XPath.first(response_doc, "//m:ResponseCode").text
      message = REXML::XPath.first(response_doc, "//m:MessageText").text
      @errors << "EWS appointment creation failed. Status: #{status.to_s}. Response code: #{response_code}. #{message}"
      return false
    end
    
    calendar_ids = REXML::XPath.match(response_doc, '//t:ItemId')
    calendar_ids.each { |item|
      @appointment_id = item.attribute("Id").to_s
    }
    return true
  end
  
  # Takes an array of time slots. Calls the connect method with the formatted Soap document.
  # Deletes the events referenced by the EWS Itme Id in the time slot.
  # If it returns false, check the errors array for messages.
  def delete_event_in_ews(events)
    connection = ExchangeConnection.new(APP_CONFIG[:ews_user_name], APP_CONFIG[:ews_user_password], APP_CONFIG[:ews_endpoint])
    begin
      response_doc = REXML::Document.new(connection.connect(delete_calendar_item_xml(events)))
      status = REXML::XPath.first(response_doc, '//m:DeleteItemResponseMessage').attribute('ResponseClass')
    rescue => e
      @errors << "Uh-oh, there was an XML exception: #{e}."
      return false
    end
    if status.to_s != "Success"
      response_code = REXML::XPath.first(response_doc, "//m:ResponseCode").text
      message = REXML::XPath.first(response_doc, "//m:MessageText").text
      @errors << "EWS appointment could not be deleted. Status: #{status.to_s}. Response code: #{response_code}. #{message}"
      return false
    end
    return true
  end
  
  
  
private
  
  # Takes an event and creates the XML to create a calendar item.
  # Soap schema information can be found at:
  # http://msdn.microsoft.com/en-us/library/aa564690.aspx
  # Params:
  # * event - Should have a name, location, description and start and end times.
  # * target_mailbox - The email address for the calendar the event should go to. If nil, it will go on the calendar of the user the app logs in with.
  # * attendees - An array of email addresses that will be added as attendees.
  def create_calendar_item_xml(event, target_mailbox = nil, attendee_addresses = [])
    
    doc = REXML::Document.new
    doc.with_element('soap:Envelope', envelope_data) do |envelope|
      envelope.with_element('soap:Body') do |body|
        body.with_element('CreateItem', create_item_data(attendee_addresses.length > 0)) do |create_item|
                             
          create_item.with_element('SavedItemFolderId') do |saved_item_folder_id|
            # Will add the event to the calendar of the user that the app logs in as.
            if target_mailbox.blank?
              saved_item_folder_id.add_element('t:DistinguishedFolderId', {'Id' => "calendar"})
            else
              
              # This adds an event to to the calendar specified by the mailbox.
              # Schema info: http://msdn.microsoft.com/en-us/library/aa580808.aspx
              # In order to succeed, the user who owns the target mail box must grant
              # permission to the user that the app logs in as.
              saved_item_folder_id.with_element('t:DistinguishedFolderId', xmlns_types.merge({'Id' => "calendar"})) do |distinguished_folder_id|
                distinguished_folder_id.with_element("Mailbox") do |mailbox|
                  mailbox.with_element("EmailAddress") do |email|
                    email.add_text(target_mailbox)
                  end
                end
              end # end distinguished folder id
            end #if target_mailbox.blank?
          end
          
          # The items block in the XML
          create_item.with_element('Items') do |items|
              
              items.with_element("t:CalendarItem", xmlns_types) do |t_calendar_item|
                subject = t_calendar_item.add_element("Subject")
                subject.add_text(event.name.blank? ? "Rails EWS Test" : event.name)

                body = t_calendar_item.add_element("Body", {'BodyType' => "Text"})
                body.add_text(event.description)

                reminder_is_set = t_calendar_item.add_element("ReminderIsSet")
                reminder_is_set.add_text("true")

                reminder_minutes_before_start =  t_calendar_item.add_element("ReminderMinutesBeforeStart")
                reminder_minutes_before_start.add_text("60")

                event_start =  t_calendar_item.add_element("Start")
                event_start.add_text(event.start_datetime.strftime("%Y-%m-%dT%H:%M:%S"))

                event_end = t_calendar_item.add_element("End")
                event_end.add_text(event.end_datetime.strftime("%Y-%m-%dT%H:%M:%S"))

                all_day = t_calendar_item.add_element("IsAllDayEvent")
                all_day.add_text(event.all_day?.to_s)

                status = t_calendar_item.add_element("LegacyFreeBusyStatus")
                # There are several options that can be used for the status. 
                # * Free
                # * Busy
                # * OOF - Out of office - etc.
                status.add_text("Busy")

                location = t_calendar_item.add_element("Location")
                location.add_text(event.location) unless event.location.blank?
                # If you have attendees, you would add them here.
                # If the SendToNone option is seleceted, then it seems to ignore attendees anyway.
                t_calendar_item.with_element("RequiredAttendees") do |attendees|
                  attendee_addresses.each do |email_address|
                    attendees.with_element("Attendee") do |attendee|
                      attendee.with_element("Mailbox") do |mailbox|
                        mailbox.with_element("EmailAddress") do |email|
                          email.add_text(email_address)
                        end
                      end
                    end
                  end # attendee_address.each
                end # end of attendees
              end # end of calendar item
              
          end # items
        end # body
      end # envelope
    end # doc
    return doc
  end
  
  # Expects and array of events and creates the XML for the delete item operation.
  # Soap schema information can be found at:
  # http://msdn.microsoft.com/en-us/library/aa580484.aspx
  def delete_calendar_item_xml(events)
   doc = REXML::Document.new
    doc.with_element('soap:Envelope', envelope_data_for_delete) do |envelope|
      envelope.with_element('soap:Body') do |body|
        body.with_element('DeleteItem', delete_item_data) do |delete_item|
          delete_item.with_element('ItemIds') do |item_id|
            events.each do |event|
              item = item_id.add_element("t:ItemId", { 'Id' => event.ews_item_id })
            end
          end
        end
      end
    end
    return doc
  end
  
  # Reusable EWS schema name space information.
  # Called by the methods creating the soap xml.
  def envelope_data
    return xmlns_xsi.merge(xmlns_xsd).merge(xmlns_soap).merge(xmlns_t)
  end
  
  def envelope_data_for_delete
    return xmlns_soap.merge(xmlns_t)
  end
  
  def create_item_data(send_to_all)
    # If sending messages is not desired change value to: SendToNone, with invitation: SendToAllAndSaveCopy
    # http://msdn.microsoft.com/en-us/library/dd633661%28EXCHG.80%29.aspx
    send_message_text = send_to_all ? "SendToAllAndSaveCopy" : "SendToNone"
    return xmlns_messages.merge(xmlns_t).merge({'SendMeetingInvitations' => send_message_text})
  end
  
  def delete_item_data
    return xmlns_messages.merge({'DeleteType' => "HardDelete", "SendMeetingCancellations" => "SendToNone"})
  end
  
  def xmlns_xsi
    {'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance"}
  end
  
  def xmlns_xsd
    {'xmlns:xsd' => "http://www.w3.org/2001/XMLSchema"}
  end
  
  def xmlns_soap
    {'xmlns:soap' => "http://schemas.xmlsoap.org/soap/envelope/"}
  end
  
  def xmlns_t
    {'xmlns:t' => "http://schemas.microsoft.com/exchange/services/2006/types"}
  end
  
  def xmlns_messages
    {'xmlns' => "http://schemas.microsoft.com/exchange/services/2006/messages"}
  end
  
  def xmlns_types
    {'xmlns' => "http://schemas.microsoft.com/exchange/services/2006/types"}
  end

end
