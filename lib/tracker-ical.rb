require 'icalendar'
require 'pivotal-tracker'
require File.join(File.dirname(__FILE__), 'pivotal-tracker', 'story')

class TrackerIcal

  def self.token=(token)
    PivotalTracker::Client.token=token
  end

  def self.token(username,password)
    PivotalTracker::Client.token(username,password)
  end
  #Returns an ics formatted string of all the milestones in the project
  def self.create_calendar_for_project_id(project_id)
    project = PivotalTracker::Project.find(project_id)
    releases = project.stories.all(:story_type => 'release')
    calendar = Icalendar::Calendar.new
    iterations = project.iterations.all
    iterations.each do |iter|
      iteration_event(project,calendar,iter)
      # Retrieve the due_on value for each milestone & stip the time component
      #Retrieve the title of the milestone & set it to the summary
      #Retrieve the goals of the milestone & set it to the description
    end
    releases.each do |release|
      release_event(project,calendar,release)
    end
    calendar.publish
    return calendar.to_ical
  end

  def self.create_ics_file_for_project_id(filepath,project_id)
    file = File.new(filepath,"w+")
    file.write(self.create_calendar_for_project_id(project_id))
    file.close
  end

  private

  def self.release_event(project,calendar,release)
    #Can't generate release events since pivotal-tracker gem doesn't include deadline info for releases
    puts("Release events not yet implemented")  
  end

  def self.iteration_event(project,calendar,iter)
    story_hash={}
    iter.stories.each do |story|
      story_hash[story.name] = story.current_state
    end
    desc = []
    story_hash.keys.each do |key|
      desc.push("#{key}: #{story_hash[key]}")
    end
    calendar.event do
      dtstart       Date.new(iter.start.year,iter.start.month,iter.start.day)
      dtend         Date.new(iter.finish.year,iter.finish.month,iter.finish.day)
      summary       "#{project.name}: Iteration #{iter.number}"
      description   desc.join("\n")
    end
  end

end