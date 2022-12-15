require "gitlab"
require "csv"

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
  d = note.match(/([0-9]+)d/)
  h = note.match(/([0-9]+)h/)
  m = note.match(/([0-9]+)m/)
  minutes = 0
  minutes += d[1].to_i * 1440 unless d.nil? || d[1].nil?
  minutes += h[1].to_i * 60 unless h.nil? || h[1].nil?
  minutes += m[1].to_i unless m.nil? || m[1].nil?

  return -1 * minutes if note.start_with?('sub') # if we are substracting time then return negative value
  return minutes # positive value otherwise
end

Gitlab.configure do |config|
  # API endpoint URL, default: ENV['GITLAB_API_ENDPOINT'] and falls back to ENV['CI_API_V4_URL']
  config.endpoint = ENV['GITLAB_API_ENDPOINT']
  # user's private token or OAuth2 access token, default: ENV['GITLAB_API_PRIVATE_TOKEN']
  config.private_token = ENV['GITLAB_API_PRIVATE_TOKEN']
  if ENV["GITLAB_AGENT_VERSION"].nil?
    version = "0.2-alpha"
  else
    version = ENV["GITLAB_AGENT_VERSION"]
  end
  config.user_agent = "Custom Timesheet Generator [" + version + "]"
end

cli = Gitlab.client

# get all issues we can see in the project
group = cli.group(ENV["GITLAB_GROUP"])

# Just a fancy stuff (capitalize first leter in the group, splitting words by dash, dot and underscore)
puts "# " + group.name.split(/\-|\.|\_/).map(&:capitalize).join(" ")
puts

delim = ";"
delim = ENV["FIELD_DELIMITER"] unless ENV["FIELD_DELIMITER"].nil?

outfile = "Timesheets.csv"
outfile = ENV["OUTFILE"] unless ENV["OUTFILE"].nil?

CSV.open(outfile, "wb", force_quotes: true, col_sep: delim, encoding: "utf-8", headers: :first_row) do |csv|
  csv << ["User", "Date", "Project", "Reference", "Issue Name", "Minutes"]

  cli.group_projects(group.id, :include_subgroups => true).auto_paginate.each do |project|
    unless project.nil?
      puts "## " + project.name_with_namespace
      cli
        .issues(project.path_with_namespace)
        .auto_paginate
        .each do |issue|
          puts "### " + issue.title + " (#" + issue.iid.to_s + ")"
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

            cntr = 0
            all_minutes = Hash.new
            notes =
              Gitlab.issue_notes(
                project.id,
                issue.iid,
                { page: 1, per_page: 100 }
              )

            if notes.nil?
              puts "No notes at all."
            else
              notes.auto_paginate do |note|
                cntr += 1
                matched_text = note.body.to_s.match(/\A(sub|add).*\ of\ time\ spent/i)
                minutes = minutes_from_note(matched_text.to_s)

                unless matched_text.nil?
                  cdate = Time.parse(note.created_at).to_date.to_s
                  all_minutes[cdate] = Hash.new if all_minutes[cdate].nil?
                  all_minutes[cdate][note.author.username] = 0 if all_minutes[cdate][
                    note.author.username
                  ].nil?
                  print "Added at " + cdate + ": "
                  puts minutes.to_s + "m by " + note.author.name
                  puts
                  end
                csv << [note.author.username, cdate.to_s, issue.references.full, project.name_with_namespace, issue.title, minutes]

              end
            end
          end
        end
    end
  end
end
