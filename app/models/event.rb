class Event < ActiveRecord::Base
  attr_accessible :name, :description, :location, :ews_item_id, :target_mailbox, :attendee_addresses, :start_datetime, :end_datetime

  def all_day?
    self.start_datetime.strftime('%H').to_i == 0 and self.end_datetime.strftime('%H').to_i == 23
  end
  
  def attendee_email_list
    if self.attendee_addresses.blank?
      list = []
    else
      list = self.attendee_addresses.split("\n")
    end
  end
end
