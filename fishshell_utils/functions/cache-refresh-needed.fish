function cache-refresh-needed
    log "cache-refresh-needed $argv"
    set -l cache_file $argv[1]
    log "cache_file: $cache_file"
    set -l cache_age $argv[2]
    log "cache_age: $cache_age"
    set -l cache_creation_needed 1  # Default to refresh needed
    log "cache_creation_needed: $cache_creation_needed"
    if test -f $cache_file
        set -l cache_mod_time (date -r $cache_file +%s)
        set -l current_time (date +%s)
        set -l stale_date (math $current_time - $cache_age)
        if test $cache_mod_time -lt $stale_date
            log "cache file exists but is older than $cache_age seconds. refresh needed"
            set cache_creation_needed 0  # No refresh needed
        else
            log "cache file exists but is younger than $cache_age seconds"
        end
    else
        log "cache file does not exist" 
    end
    return $cache_creation_needed
end