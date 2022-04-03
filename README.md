# ChatWatch
 Chat watcher addon for FFXI Windower

## Very Alpha - This may or may not work as expected

Addon will watch for chosen strings in chat log and send defined reactions

### Commands - Use chatwatch or cw followed by any of the following:
start | begin | on | go - will activate chat watching/responding
stop | end | halt | off - will terminate chat watching/responding

add [chat_type] [job] [character] [target:<targettype>] <"text to watch for"> <"command to execute">
* will add the "text to watch for" to watched strings and "command to execute" will happen when detected
* chat_type, job, character, and target:<targettype> are optional
* * if target is used it must be in the form of target:targettype 
* "text to watch for" and "command to execute" are required and must be inside of ""

rem[ove] | del[ete]  <id>

list - Displays currently watched messages with id # and status

