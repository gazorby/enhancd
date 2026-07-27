function _enhancd_track_mkdir --argument-names st cmd
    # Guards: disabled / not ready / mkdir failed
    test "$ENHANCD_ENABLE_MKDIR" = false; and return
    test -z "$_ENHANCD_READY"; and return
    test "$st" -eq 0; or return

    # Only a leading, standalone mkdir invocation
    string match -q -r -- '^\s*mkdir\b' "$cmd"; or return

    # Tokenize honoring simple single/double quotes
    set -l tokens (string match -a -r -- '\'[^\']*\'|"[^"]*"|\S+' "$cmd")
    set -l dirs
    set -l n (count $tokens)
    set -l i 2  # skip tokens[1] == mkdir
    
    while test $i -le $n
        set -l tok $tokens[$i]
        switch $tok
            case '-m' '--mode'
                set i (math $i + 1)  # skip the separate mode value
            case '-*'
                # flag with no separate value (-p, -pv, --parents, --mode=755, ...)
            case '*'
                # strip surrounding matching quotes, then resolve to abspath
                set -l op (string replace -r -- '^([\'"])(.*)\\1$' '$2' $tok)
                set -l abs (path resolve -- $op)
                test -d "$abs"; and set -a dirs $abs
        end
        set i (math $i + 1)
    end

    test (count $dirs) -gt 0; and _enhancd_history_add $dirs
end
