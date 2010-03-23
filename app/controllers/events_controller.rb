class EventsController < ApplicationController
  def index
    @events = Event.all
  end
  
  def show
    @event = Event.find(params[:id])
  end
  
  def new
    @event = Event.new
  end
  
  def create
    @event = Event.new(params[:event])
    create_ews_event
    if @event.save
      flash[:notice] = "Successfully created event."
      redirect_to @event
    else
      render :action => 'new'
    end
  end
  
  def edit
    @event = Event.find(params[:id])
  end
  
  def update
    @event = Event.find(params[:id])
    # First, destroy the original event that as created.
    destroy_ews_event
    
    if @event.update_attributes(params[:event])
      # Create a new event based on the changes.
      create_ews_event
      @event.save
      flash[:notice] = "Successfully updated event."
      redirect_to @event
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @event = Event.find(params[:id])
    destroy_ews_event
    @event.destroy
    flash[:notice] = "Successfully destroyed event."
    redirect_to events_url
  end
  
  private
  
  def create_ews_event
    es = ExchangeService.new
    if es.create_event_in_ews(@event, nil, @event.attendee_email_list)
      @event.ews_item_id = es.appointment_id
      logger.info("#{Time.now.to_s}: Event: #{@event.id} -  Created EWS event. EWS id: #{@event.ews_item_id}.")
    else
      logger.warn("#{Time.now.to_s}: Event: #{@event.id} - #{es.errors.join(", ")}")
    end
  end
  
  def destroy_ews_event
    es = ExchangeService.new
    if es.delete_event_in_ews([@event])
      logger.info("#{Time.now.to_s}: Event: #{@event.id} - Deleted EWS event.")
    else
      logger.warn("#{Time.now.to_s}: Event: #{@event.id} - #{es.errors.join(", ")}")
    end
  end
end
