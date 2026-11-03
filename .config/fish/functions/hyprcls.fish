function hyprcls --description 'List Hyprland window client details with filtering and focus history'
    set -l show_full 0
    set -l mode "all"
    set -l active_count 1
    set -l search_query ""
    set -l ws ""
    set -l expecting_ws 0
    set -l expecting_active_count 0

    # Parse command arguments
    for arg in $argv
        if test $expecting_ws -eq 1
            set ws $arg
            set expecting_ws 0
            continue
        end

        if test $expecting_active_count -eq 1; and string match -qr '^[0-9]+$' -- $arg
            set active_count $arg
            set expecting_active_count 0
            continue
        end

        switch (string lower -- $arg)
            case -h --help help
                echo "Usage: hyprcls [active [N]] [ws <WS_ID|NAME>] [full|-v] [QUERY]"
                echo "  hyprcls              List all clients"
                echo "  hyprcls active       Show currently active window"
                echo "  hyprcls active 4     Show last 4 focused windows"
                echo "  hyprcls ws 1         Show windows on workspace 1"
                echo "  hyprcls code         Search windows matching 'code'"
                echo "  hyprcls full         Show pos, size, mon, pid"
                return 0
            case full verbose -v --full
                set show_full 1
            case active
                set mode "active"
                set expecting_active_count 1
            case ws
                set expecting_ws 1
            case '*'
                set search_query $arg
        end
    end

    # Build JQ filter rule based on arguments
    set -l jq_filter ".[]"
    if test "$mode" = "active"
        set jq_filter "map(select(.focusHistoryID != null)) | sort_by(.focusHistoryID) | .[:($active_count | tonumber)] | .[]"
    else if test -n "$ws"
        set jq_filter ".[] | select(.workspace.id == (try ($ws | tonumber) catch null) or .workspace.name == \"$ws\")"
    else if test -n "$search_query"
        set jq_filter ".[] | select((.class | test(\"$search_query\"; \"i\")) or (.title | test(\"$search_query\"; \"i\")) or (.workspace.name == \"$search_query\"))"
    end

    # Build optional verbose output string
    set -l extra_info ""
    if test $show_full -eq 1
        set extra_info "\n    \u001b[32mpos:\u001b[0m \(.at[0]), \(.at[1])  \u001b[32msize:\u001b[0m \(.size[0])x\(.size[1])  \u001b[32mmon:\u001b[0m \(.monitor)  \u001b[32mpid:\u001b[0m \(.pid)"
    end

    # Process client list
    hyprctl clients -j | jq -r "$jq_filter | \"\u001b[1;36mWindow \(.address)\u001b[0m \u001b[37m[WS \(.workspace.id)]\u001b[0m\(if .floating then \" \u001b[1;33m[Float]\u001b[0m\" else \"\" end)\(if .pinned then \" \u001b[1;35m[Pinned]\u001b[0m\" else \"\" end)\(if .xwayland then \" \u001b[1;31m[XWayland]\u001b[0m\" else \"\" end) -> \u001b[1;37m\(.title)\u001b[0m:\n    \u001b[33mclass:\u001b[0m \(.class)\n    \u001b[33mtitle:\u001b[0m \(.title)\n    \u001b[33minitialClass:\u001b[0m \(.initialClass)\n    \u001b[33minitialTitle:\u001b[0m \(.initialTitle)$extra_info\n\""
end