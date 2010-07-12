require 'icalendar'
require 'pivotal-tracker'
require File.join(File.dirname(__FILE__), 'pivotal-tracker', 'story')

class TrackerIcal

  #Set the PivotalTracker token to be used for interating with the Pivotal API
  def self.token=(token)
    PivotalTracker::Client.token=token
  end

  #Retrieves the PivotalTracker token for a given username and password, enabling further interaction with the Pivotal API
  def self.token(username,password)
    PivotalTracker::Client.token(username,password)
  end
  
  #Returns an ics formatted string of all the iterations and releases in the project
  #If a release does not have a deadline, it will not be included in the output
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

  #Creates an ics file at the specified filepath containing the iterations and releases with deadlines for the project_id
  def self.create_ics_file_for_project_id(filepath,project_id)
    file = File.new(filepath,"w+")
    file.write(self.create_calendar_for_project_id(project_id))
    file.close
  end

  private

  def self.release_event(project,calendar,release)
    unless release.deadline.nil?
      calendar.event do
        dtstart       Date.new(release.deadline.year,release.deadline.month,release.deadline.day)
        dtend         Date.new(release.deadline.year,release.deadline.month,release.deadline.day)
        summary       release.name
        description   release.description
      end
    end
  end
  
  def self.iteration_points(iteration)
    points = {}
    point_array = iteration.stories.collect(&:estimate).compact
    accepted_point_array = iteration.stories.select{|story|story.current_state == 'accepted'}.collect(&:estimate).compact
    points[:total] = eval point_array.join('+').to_i
    points[:accepted] = eval accepted_point_array.join('+').to_i
  end

  def self.iteration_event(project,calendar,iter)
    stories = []
    
    iter.stories.each do |story|
      stories.push("#{story.name} (#{story.current_state})")
    end
    
    points = self.iteration_points(iter)
    
    calendar.event do
      dtstart       Date.new(iter.start.year,iter.start.month,iter.start.day)
      dtend         Date.new(iter.finish.year,iter.finish.month,iter.finish.day)
      summary       "#{project.name}: Iteration #{iter.number} (#{points[:accepted]}/#{points[:total]} points)"
      description   stories.join("\n")
    end
  end

end