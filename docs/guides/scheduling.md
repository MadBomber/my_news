# Scheduling

MyNews supports automatic pipeline execution on a cron schedule using `rufus-scheduler`.

## Default Schedule

The pipeline runs 3x daily by default:

```yaml
schedule:
  times:
    - "07:00"
    - "13:00"
    - "19:00"
  timezone: America/Chicago
```

## Running the Scheduler

```bash
my_news schedule
```

This starts a long-running process that executes the full pipeline at each scheduled time. It runs in the foreground -- use a process manager (systemd, launchd, etc.) for production.

## Custom Schedule

Override the times in your configuration:

```yaml
schedule:
  times:
    - "06:00"
    - "12:00"
    - "18:00"
    - "22:00"
  timezone: America/New_York
```

## Alternative: System Cron

Instead of the built-in scheduler, you can use crontab:

```cron
0 7,13,19 * * * cd /path/to/my_news && bundle exec my_news pipeline
```
