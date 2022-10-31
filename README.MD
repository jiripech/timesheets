# Documentation

## First Steps

1. Install Gitlab API client gem
2. Configure environment
3. Run `Timesheets.rb >Timesheets.md`

### Environment

These variables should be present in the environment

```
GITLAB_API_PRIVATE_TOKEN="glpat_..."
GITLAB_API_ENDPOINT="https://gitlab.com/api/v4" (or address of your Gitlab instance API)
GITLAB_GROUP="your_group"
OUTFILE="Timesheets.csv" 
FIELD_DELIMITER=";"
```

## Gitlab API Client

This work is based on [Gitlab API Client][https://github.com/NARKOZ/gitlab] by [Nihad Abbasov](https://github.com/NARKOZ). The Gitlab API v4 unfortunately does not publish raw timesheets, so we had to go through all the notes, extract the times from them and add it up for each author.

### More reading

- https://www.rubydoc.info/gems/gitlab/Gitlab/ClientIssues#time_stats_for_issue-instance_method


[https://github.com/NARKOZ/gitlab]: https://github.com/NARKOZ/gitlab