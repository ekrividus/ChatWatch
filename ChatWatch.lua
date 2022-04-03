--[[
Copyright © 2020, Ekrividus
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of autoMB nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL Ekrividus BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

_addon.version = '0.8.0'
_addon.name = 'ChatWatch'
_addon.author = 'Ekrividus'
_addon.commands = {'chatwatch', 'cwatch', 'chatw', 'cw'}
_addon.lastUpdate = '9/21/21'
_addon.windower = '4'

require('tables')
require('sets')
require('strings')
require('chat')
require('logger')
require('xml')

files = require('files')
packets = require('packets')
config = require('config') 
res = require('resources')

local chat_types = T{
    [0] = {id=0,en="say",incoming=9,outgoing=1},
    [1] = {id=1,en="shout",incoming=10,outgoing=2},
    [3] = {id=3,en="tell",incoming=12,outgoing=4},
    [4] = {id=4,en="party",incoming=13,outgoing=5},
    [5] = {id=5,en="linkshell",incoming=14,outgoing=6},
    [8] = {id=8,en="emote",incoming=15,outgoing=7},
    [26] = {id=26,en="yell",incoming=11,outgoing=3},
    [27] = {id=27,en="linkshell2",incoming=214,outgoing=213},
    [33] = {id=33,en="unity",incoming=212,outgoing=211},
    [34] = {id=34,en="assistj",incoming=220,outgoing=219},
    [35] = {id=35,en="assiste",incoming=222,outgoing=221},
}

local chat_targets = T{
    none="",
    self="<me>",
    sender="<sender>",
    enemy="<bt>",
}

--[[ A chat item for testing and reference
local chat_item = {
    chat_message = "3rd eye",
    chat_response = 'input /ja "third eye"',
    chat_response_channel = "none",
    chat_type = "party",
    job="SAM",
    players = T{"lightin","lyannya"},
    target = "self",
}
]]--

local send_command = windower.send_command
local addon_commands = T{}

local defaults = {}
defaults.chat_items = T{
    [1] = {
        chat_message = "Hello", 
        chat_response = "Heya",
        chat_type = "any",
        chat_response_channel = "incoming",
        players = "any",
        target = "sender", 
    },
}

local settings = config.load("data/settings_"..windower.ffxi.get_player().name..".xml", defaults)

local running = false
local show_debug = false 

function message(str, debug, to_log)
    if (not debug and not to_log) then
        windower.add_to_chat(17, "[ChatWatch] "..str)
    elseif (debug and show_debug) then
        windower.add_to_chat(17, "[ChatWatch (Debug)] "..str)
    elseif (to_log) then
        windower.log("[ChatWatch] "..msg)
    end
end

addon_commands['start'] = {
    handler = function(cmd, args)
        running = true
        message("Now listening for chat messages.")
    end,
    help_text = "Start listening to chat."
}
addon_commands['stop'] = {
    handler = function(cmd, args)
        running = false
        message("No longer listening for chat messages.")
    end,
    help_text = "Stop listening to chat."
}
addon_commands['debug'] = {
    handler = function(cmd, args)
        show_debug = not show_debug
        message("Debug messages are "..(show_debug and "On" or "Off"))
    end,
    help_text = "Turn debug message on or off."
}


addon_commands['add'] = {
    handler = function(cmd, args)
        if (not args or #args < 1) then
            message(addon_commands[cmd].help_text)
            return
        end

        message("Added watch string: "..tostring(args[1]))
    end,
    help_text = "Usage: [chat_type] [job] [character] [target:<targettype>]<\"text to watch for\"> <\"command to execute\">"
}

addon_commands['remove'] = {
    handler = function(cmd, args)
        local id = tonumber(args[1])
        if (not args or #args < 1 or id == nil) then
            message(addon_commands[cmd].help_text)
            return
        end
        
        settings.chat_items[id] = nil
        --settings:save('all')

        message("Removed watch string: "..tostring(args[1]))
    end,
    help_text = "Usage: cw rem[ove] <id> where <id> is the id # of the chat_item you wish to remove"
}

addon_commands['list'] = {
    handler = function(cmd, args)
        local str = ""
        local target = ""

        for k, v in pairs(settings.chat_items) do
            str = str.."\n"
            target = ""

            if (v.target and v.target:lower() == "self") then
                target = " <me>"
            elseif (v.target and v.target:lower() == "sender") then
                target = " ".."<sender>"
            elseif (v.target and v.target:lower() == "enemy") then
                target = " <bt>"
            end

            --message("["..k.."]: "..T(v):tovstring())

            str = str.."["..k.."] Listen for message: \""..(v.chat_message and v.chat_message or "any").."\" On channel: "..(v.chat_type and v.chat_type or "any").."\n"
            str = str.."\t Allowed Players: "..(type(v.players) == 'string' and v.players or v.players:concat(" ")).."\n"
            if (type(v.chat_response) == 'string') then
                str = str.."\t Response: "..v.chat_response..target
            elseif (type(v.chat_response) == 'table') then
                str = str.."\t Responses: "
                for k2, v2 in pairs(v.chat_response) do
                    str = str.."\t\t"..v2..target
                end
            end
        end
        message(str)
        --message("Chat Item Count: "..tostring(settings.chat_items:length()))
    end,
    help_text = "Usage: cw list - Lists all loaded chat items in an agonizing way"
}

----[[[[ Chat Processing ]]]]----
windower.register_event('chat message', function(msg, sender, mode, gm)
    message("Chat incoming from "..sender.." using mode "..mode.." is gm? "..tostring(gm), true)
    if (gm) then return end -- Never react to GM chats
    
    -- loop through all of this characters chat_items, multiple matches are ok
    for k, v in pairs(settings.chat_items) do
        -- We matched the incoming message to our settings.chat_items messages
        if (v.chat_message:lower() == msg:lower()) then
            message("Chat Item - Message Matched", true)

            -- Verify it came in on a valid channel for this chat item
            if (v.chat_type:lower() ~= 'any' and not res.chat:with('en', v.chat_type:lower()).id == mode) then return end
            message("Chat Item - Valid Channel", true)


            -- Verify it's a valid sender for this chat item
            if (type(v.players) == 'string') then
                if (v.players:lower() ~= 'any' and not T(v.players:split(" ")):contains(sender:lower())) then return end
            elseif (type(v.players) == 'table') then
                if (not T(v.players):contains(sender)) then return end
            end
            message("Chat Item - Valid Sender", true)

            -- If this chat item requires a specific job make sure we're on it 
            if (v.job and windower.ffxi.get_player().job ~= v.job) then return end
            message("Chat Item - Valid Job", true)


            local target = ""
            if (v.target and v.target:lower() == "self") then
                target = " <me>"
            elseif (v.target and v.target:lower() == "sender") then
                target = " "..sender
            elseif (v.target and v.target:lower() == "enemy") then
                target = " <bt>"
            end
            message("Chat Item - Target Set", true)


            local channel = ""
            if (v.chat_response_channel and T{"any","incoming"}:contains(v.chat_response_channel:lower())) then
                if (res.chat:with('id', mode).en == 'tell') then
                    channel = "input /tell "..sender.." "
                else
                    channel = "input /"..res.chat:with('id', mode).en.." "
                end
            elseif(v.chat_response_channel and v.chat_response_channel:lower() == "tell") then
                channel = "input /tell "..sender.." "
            elseif(v.chat_response_channel and v.chat_response_channel:lower() ~= "none") then
                channel = "input /"..v.chat_response_channel.." "
            end
            message("Chat Item - Response Channel: ["..channel.."] == ["..tostring(v.chat_response_channel).."]", true)

            if (type(v.chat_response) == 'string') then
                message("Chat Item - Command: "..channel..v.chat_response..target, true)
                send_command(channel..v.chat_response..target)
            elseif (type(v.chat_response) == 'table') then
                for k2, v2 in pairs(v.chat_response) do
                    message("Chat Item - Command: "..channel..v2..target, true)
                    send_command(channel..v2..target)
                end
            end
        end
    end
end)

----[[[[ Addon Commands ]]]]----
windower.register_event('addon command', function(...)
    local cmd = arg[1]:lower()
    local args = T{}

    if (#arg > 1) then
        args = T(arg):slice(2, #arg):map(string.lower)
    end

    if (T{"start","begin","on","go"}:contains(cmd)) then
        cmd = "start"
    elseif (T{"stop","end","halt","off"}:contains(cmd)) then
        cmd = "stop"
    end

    if (addon_commands[cmd]) then
        addon_commands[cmd].handler(cmd, args)
    else 
        message("Unknown command: "..tostring(cmd))
    end
end)