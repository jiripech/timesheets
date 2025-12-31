require "gitlab"
require "csv"
require "time"

def put_time_estimation(stats)
  if stats.human_time_estimate.nil?
    puts "No estimation."
  else
    puts stats.human_time_estimate
  end
end

def put_time_spent(stats)
  if stats.human_total_time_spent.nil?
    puts "There's nothing done yet."
  else
    puts stats.human_total_time_spent
  end
end

def minutes_from_note(note)
  return 0 if note.empty?

  minutes = 0
  minutes += note[/(\d+)d/, 1].to_i * 1440
  minutes += note[/(\d+)h/, 1].to_i * 60
  minutes += note[/(\d+)m/, 1].to_i

  note.start_with?("sub") ? -minutes : minutes
end

if __FILE__ == $0
  Gitlab.configure do |config|
    config.endpoint = ENV.fetch("GITLAB_API_ENDPOINT", nil)
    config.private_token = ENV.fetch("GITLAB_API_PRIVATE_TOKEN", nil)
    version = ENV.fetch("GITLAB_AGENT_VERSION", "0.2-alpha")
    config.user_agent = "Custom Timesheet Generator [#{version}]"
  end

  cli = Gitlab.client

  # get all issues we can see in the project
  group = cli.group(ENV["GITLAB_GROUP"])

  # Just a fancy stuff (capitalize first letter in the group, splitting words by dash, dot and underscore)
  puts "# " + group.name.split(/[-._]/).map(&:capitalize).join(" ")
  puts

  delim = ENV.fetch("FIELD_DELIMITER", ";")
  outfile = ENV.fetch("OUTFILE", "Timesheets.csv")

  CSV.open(
    outfile,
    "wb",
    force_quotes: true,
    col_sep: delim,
    encoding: "utf-8",
    headers: :first_row
  ) do |csv|
    csv << ["User", "Date", "Project", "Reference", "Issue Name", "Minutes"]

    cli
      .group_projects(group.id, include_subgroups: true)
      .auto_paginate
      .each do |project|
        next if project.nil?

        puts "## " + project.name_with_namespace
        cli
          .issues(project.path_with_namespace)
          .auto_paginate
          .each do |issue|
            puts "### " + issue.title + " (##{issue.iid})"
            puts

            s = issue.time_stats
            if s.human_total_time_spent.nil?
              puts "No time stats."
            else
              print "- Estimated (minutes): "
              put_time_estimation(s)
              print "- Spent (minutes): "
              put_time_spent(s)

              puts "#### Notes"
              puts

              notes = cli.issue_notes(project.id, issue.iid, { page: 1, per_page: 100 })

              if notes.nil?
                puts "No notes at all."
              else
                notes.auto_paginate do |note|
                  matched_text = note.body.to_s.match(/\A(sub|add).*\ of\ time\ spent/i)
                  next if matched_text.nil?

                  minutes = minutes_from_note(matched_text.to_s)
                  next if minutes == 0

                  cdate = Time.parse(note.created_at).to_date.to_s
                  print "Added at #{cdate}: "
                  puts "#{minutes}m by #{note.author.name}"
                  puts
                  csv << [
                    note.author.username,
                    cdate,
                    project.name_with_namespace,
                    issue.references.full,
                    issue.title,
                    minutes
                  ]
                end
              end
            end
          end
      end
  end
end


