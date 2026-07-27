function _enhancd_history_add
    set -l merged $ENHANCD_DIRECTORIES $argv
    set -l list (string join \n -- $merged \
        | _enhancd_filter_reverse | _enhancd_filter_unique | _enhancd_filter_reverse \
        | string split \n)
    test -n "$list"; and set -Ux ENHANCD_DIRECTORIES $list
end
