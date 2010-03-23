class Event < ActiveRecord::Base
  attr_accessible :name, :description, :location, :start_datetime, :end_datetime
  
  def all_day?
    self.start_datetime.strftime('%H').to_i == 0 and self.end_datetime.strftime('%H').to_i == 23
  end
end
