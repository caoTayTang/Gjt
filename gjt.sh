#! /bin/bash

#################### UTILITY FUNCTION #####################
gen_commit_id() {
    echo "$(date +"%H:%M-%d/%m/%Y")"
}

write_commit() {
    msg="$1"
    timestamp=$2

    if [ -z "$msg" ]; then
        echo "Error: Commit message is required."
        exit 1
    fi

    temp="./.gjt/.temp"
    history="./.gjt/history.log"
    touch "$temp"
    echo "$timestamp: $msg" > "$temp"
    echo "$(cat $history)" >> "$temp"
    mv "$temp" "$history"
}

check_initialize() {
    if [ ! -d '.gjt' ]; then
        echo "Must be a gjt root folder."
        exit 1
    fi
}
##########################################################

init() {
    #!INFO:
    # 1. Check if .gjt exists, if does error
    # 2. Otherwise, create .gjt/, tracked_files, history.log,...
    # 3. add the `$gjt init`, aka create .gjt timestamp to history.log
    
    if [ -d ".gjt" ]; then
        echo "Error: Backup already initialized in this folder."
        exit 1
    fi
        
    mkdir "./.gjt"
    mkdir "./.gjt/diff"
    touch "./.gjt/tracked_files"
    touch "./.gjt/history.log"

    timestamp=$(gen_commit_id)
    write_commit "GJT Init." "$timestamp"
    echo "Backup initialized."
}

add() {
    #!INFO: 2 cases 
    # 1. If argument is given 
    #   1.1 If file 
    #       If file not exists error: echo "Error: src/main.c does not exist."
    #   1.2 If directory 
    #       Not given info, what if user add .GJT?????
    # 2. If $2 is empty
    #   Track all file in current folder (exclude .GJT)
    #   2.1 Does it need to check for .GJT exist folder and throw error?

    arg="$1"

    if [ -z "$arg" ]; then 
        files=$(find . -mindepth 1 -type f ! -path "./.git/*" ! -path "./.git")
        for file in $files; do
            file=$(realpath --relative-to=. "$file")

            if ! grep -qx "$file" ".git/tracked_files"; then
                echo "$file" >> ".gjt/tracked_files"
            fi

            gjt_file=".gjt/$(echo "$file" | tr '/' '_')"
            mkdir -p "$gjt_file"
            cp "$file" "$gjt_file/latest"
            echo "Added $file to backup tracking."
        done
        return
    fi

    if [ -f "$arg" ]; then
        arg=$(realpath --relative-to=. "$arg")
        if $(grep -q "$arg" "./.gjt/tracked_files"); then
            echo "Error: $arg is already tracked."
            exit 1
        fi
        mkdir -p ".gjt/$(echo "$arg" | tr '/' '_')"
        echo "$arg" >> ".gjt/tracked_files"
        cp "$arg" ".gjt/$(echo "$arg" | tr '/' '_')/latest"
        echo "Added $arg to backup tracking."
        return
    fi

    echo "Error: $arg does not exist."
    exit 1
}

status() {
    #!INFO:
    # 1. Error if not intialize gjt folder
    # 2. Error if file not track:
    #   echo "Error: src/main.c is not tracked."
    # 3. Error if no file has been track???? (what differ from above), this should have higher priority
    #   echo "Error: Nothing has been tracked."
    
    arg="$1"

    # Check if any files are tracked
    if [ ! -s ".gjt/tracked_files" ]; then
        echo "Error: Nothing has been tracked."
        exit 1
    fi

    if [ -z "$arg" ]; then
        files=$(cat .gjt/tracked_files)
        any_tracked=false
        
        for file in $files; do
            file_real=$(realpath --relative-to=. "$file")
            gjt_file=".gjt/$(echo "$file_real" | tr '/' '_')"
            latest="$gjt_file/latest"

            if [ ! -f "$latest" ]; then
                echo "Error: $file_real is not tracked."
                continue
            fi

            any_tracked=true
            if diff_output=$(diff -u "$latest" "$file_real" 2>/dev/null); then
                echo "$file_real: No changes"
            else
                diff_output=$(diff -u "$latest" "$file_real" 2>/dev/null)
                echo "$file_real:"
                echo "$diff_output"
            fi
        done

        if [ "$any_tracked" = false ]; then
            echo "Error: Nothing has been tracked."
            exit 1
        fi
        return
    fi

    if [ ! -f "$arg" ]; then 
        echo "Error: $arg does not exist."
        exit 1
    fi

    if [ -f "$arg" ]; then
        file=$(realpath --relative-to=. "$arg")
        gjt_file=".gjt/$(echo "$file" | tr '/' '_')"
        latest="$gjt_file/latest"

        if ! grep -Fxq "$file" .gjt/tracked_files; then
            echo "Error: $file is not tracked."
            exit 1
        fi

        if [ ! -f "$latest" ]; then
            echo "Error: $file is not tracked."
            exit 1
        fi

        if diff_output=$(diff -u "$latest" "$file" 2>/dev/null); then
            echo "$file: No changes"
        else
            diff_output=$(diff -u "$latest" "$file" 2>/dev/null)
            echo "$file:"
            echo "$diff_output"
        fi

        return
    fi
}
commit() {
    #!INFO:
    # 1. Gen commitID (format `hh:mm-DD/MM/YYYY`) 
    # 2. Store diffs of changed files in .gjt 
    # 3. Update history
    # 4. If no files provided, commit all changed tracked files
    # 5. Commit message is mandatory (does commit message require: (file name) at the end)
    # Errors: - Missing message, No changed,
    
    
    msg="$1"
    dir="$2"
    
    if [ -z "$msg" ]; then
        echo "Error: Commit message is required."
        exit 1
    fi

    timestamp=$(gen_commit_id)

    # Commit all changed 'tracked files'
    if [ -z "$dir" ]; then
        filename=""
        files=$(find . -type f ! -path "./.gjt/*" ! -path "./.gjt")
        any_tracked_or_unchange=false

        for file in $files; do
            file=$(realpath --relative-to=. "$file")
            latest=".gjt/$(echo "$file" | tr '/' '_')/latest"

            # If no change then diff will return 0
            if [ -f "$latest" ] && ! diff_output=$(diff -u "$latest" "$file" 2>&1); then
                any_tracked_or_unchange=true
                diff_name="$(echo "$file" | tr '/' '_').diff"

                if [ -z "$filename" ]; then
                    filename="$file"
                else 
                    filename+=",$file"
                fi

                echo "$diff_output" > "./.gjt/diff/$diff_name"
                cp "$file" "$latest"

                echo "Committed $file with ID $timestamp."
            fi
        done

        if [ "$any_tracked_or_unchange" = false ]; then
            echo "Error: No change to commit."
            exit 1
        fi

        write_commit "$msg ($filename)." "$timestamp"
        return
    fi

    if [ -f "$dir" ]; then
        file=$(realpath --relative-to=. "$dir")
        latest=".gjt/$(echo "$file" | tr '/' '_')/latest"
        diff_name="$(echo "$file" | tr '/' '_').diff"
        
        # No changes or untracked
        if [ ! -f "$latest" ] || diff_output=$(diff -u "$latest" "$file" 2>&1); then
            echo "Error: No change to commit."
            exit 1
        fi

        echo "$diff_output" > "./.gjt/diff/$diff_name"
        cp "$file" "$latest"

        write_commit "$msg ($dir)." "$timestamp"
        echo "Committed $file with ID $timestamp."
        return
    fi

    exit 1
}


history() {
    echo "$(cat ./.gjt/history.log)"
}

restore() {
    #INFO:
    #1. revert using 'diff -R old old.diff'
    #2. replace the reverted to the latest
    dir="$1"

    if [ -z "$dir" ]; then
        files=$(cat .gjt/tracked_files)
    else
        files="$dir"
    fi
    
    local success=1
    for file in $files; do
        clean_file=$(echo "$file" | sed 's|^\./||')
        if ! grep -Fxq "$clean_file" .gjt/tracked_files; then
            echo "Error: $file is not tracked."
            continue
        fi

        backup_file=$(echo "$clean_file" | sed 's|/|_|g')
        latest_diff=".gjt/diff/$backup_file.diff"  # Adjusted to match your commit() diff path
        if [ -f "$latest_diff" ]; then
            patch -R "$file" < "$latest_diff" 2>&1 > /dev/null
            echo "Restored $file to its previous version."
            rm "$latest_diff"
            cp "$file" ".gjt/$(echo "$clean_file" | tr '/' '_')/latest"
            success=0
        else
            echo "Error: No previous version available for $clean_file"
        fi
    done
    return $success
}

schedule() {
    case "$1" in
        --daily)
            (crontab -l 2>/dev/null; echo "0 0 * * * ./gjt.sh commit \"Scheduled backup\"") | crontab -
            echo "Scheduled daily backups at daily."
            ;;
        --hourly)
            (crontab -l 2>/dev/null; echo "0 * * * * ./gjt.sh commit \"Scheduled backup\"") | crontab -
            echo "Scheduled hourly backups at hourly."
            ;;
        --weekly)
            (crontab -l 2>/dev/null; echo "0 0 * * 1 ./gjt.sh commit \"Scheduled backup\"") | crontab -
            echo "Scheduled weekly backups at weekly."
            ;;
        --off)
            crontab -l 2>/dev/null | grep -v "gjt.sh commit \"Scheduled backup\"" | crontab -
            echo "Backup scheduling disabled."
            ;;
        *)
            echo "Usage: $0 schedule {--daily|--hourly|--weekly|--off}"
            exit 1
            ;;
    esac


}

stop() {

    if [ -d '.gjt' ]; then
        rm -r ".gjt"
        crontab -l 2>/dev/null | grep -Fv -e "${jobs[@]}" | crontab -
        echo "Backup system removed."
    else
        echo "Error: No backup system to be removed."
        exit 1
    fi
}

# gjt add abcd
case "$1" in 
    init) 
        init 
        ;;
    add) 
        check_initialize
        shift
        add "$1" 
        ;;
    status) 
        check_initialize
        shift
        status "$1" 
        ;;
    commit) 
        check_initialize
        shift
        commit "$1" "$2" 
        ;;
    history) 
        check_initialize
        history 
        ;;
    restore) 
        check_initialize
        shift
        restore "$1"
        ;;
    schedule) 
        check_initialize
        shift
        schedule "$1"
        ;;
    stop) 
        stop 
        ;;
    *) 
        echo "Invalid argument"
        exit 1
        ;;
esac
