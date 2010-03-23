require 'test_helper'

class EventTest < ActiveSupport::TestCase
  
  should "be valid" do
    assert Event.new.valid?
  end
  
  context "An event instance" do
    setup do
      @event = events(:one)
    end
    
    should "not be all day" do
      assert !@event.all_day?
    end
    
    should "be all day" do
      @event.start_datetime = Time.zone.now.beginning_of_day
      @event.end_datetime = Time.zone.now.end_of_day
      assert @event.all_day?
    end
    
    should "not have an attendee list if attendee_addresses are blank" do
      assert @event.attendee_email_list.length == 0
    end
    
    should "have an attendee list of attendee_addresses are not blank" do
      @event.attendee_addresses = "test@test123.com
      test1@test123.com"
      assert_equal 2, @event.attendee_email_list.length
    end
    
  end
end
