#! /bin/bash
bku init
result=$(bku schedule --daily)
cron_jobs=$(crontab -l 2>/dev/null | grep -c "Scheduled backup")
if [[ "$result" == "Scheduled daily backups at daily." && "$cron_jobs" -ge 1 ]]; then
    echo "Daily backup scheduled successfully!"
else
    echo "Scheduling failed: Output='$result', cron jobs found='$cron_jobs' (expected >= 1)"
fi
