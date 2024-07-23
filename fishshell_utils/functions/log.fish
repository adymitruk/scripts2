function log
    if set -q UTILS_LOG
        set -l log_file $UTILS_LOG
    else
        return 0
    end
    echo (date "+%Y-%m-%d %H:%M:%S") $argv | tee -a $log_file > /dev/null
end
