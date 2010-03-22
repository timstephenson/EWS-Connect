class Event < ActiveRecord::Base
  attr_accessible :name, :description, :location, :start_datetime, :end_datetime
end
