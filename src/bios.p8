pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--
--  ZEPTO-8 — Fantasy console emulator
--
--  Copyright © 2016—2020 Sam Hocevar <sam@hocevar.net>
--
--  This program is free software. It comes without any warranty, to
--  the extent permitted by applicable law. You can redistribute it
--  and/or modify it under the terms of the Do What the Fuck You Want
--  to Public License, Version 2, as published by the WTFPL Task Force.
--  See http://www.wtfpl.net/ for more details.
--


--
-- Private things
--
__z8_stopped = false
__z8_load_code = load
__z8_persist_delay = 0


-- Backward compatibility for old PICO-8 versions
-- PICO-8 documentation: t() aliased to time()
t = time
mapdraw = map

-- These variables can be used for button names
⬅️, ➡️, ⬆️, ⬇️, 🅾️, ❎ = 0, 1, 2, 3, 4, 5

-- These variables encode fillp patterns
█, ▒, 🐱, ░, ✽, ●, ♥, ☉, 웃, ⌂, 😐, ♪, ◆, …, ★, ⧗, ˇ, ∧, ▤, ▥ = 0, 0x5a5a,
0x511f, 0x7d7d, 0xb81d, 0xf99f, 0x51bf, 0xb5bf, 0x999f, 0xb11f, 0xa0e0,
0x9b3f, 0xb1bf, 0xf5ff, 0xb15f, 0x1b1f, 0xf5bf, 0x7adf, 0x0f0f, 0x5555


--
-- Save these functions because they are needed by some of our public functions
-- but will not be propagated to the cart through _ENV.
--
local error = error
local table = table -- for insert and remove
local ipairs = ipairs
local tonumber = tonumber
local __cartdata = __cartdata


-- According to https://gist.github.com/josefnpat/bfe4aaa5bbb44f572cd0 :
--  coroutine.[create|resume|status|yield]() was removed in 0.1.3 but added
--  in 0.1.6 as coroutine(), cocreate(), coresume(), costatus() and yield()
--  respectively.
-- The debug library is not needed either, but we need trace()
cocreate = coroutine.create
coresume = coroutine.resume
costatus = coroutine.status
yield = coroutine.yield
trace = debug.traceback

function stop()
    __z8_stopped = true
    error()
end

function assert(cond, msg)
    if not cond then
        color(14) print("assertion failed:")
        color(6) print(msg or "assert()")
        stop()
    end
end

function count(a) return a != nil and #a or 0 end
function add(a, x) if a != nil then table.insert(a, x) end return x end
sub = string.sub

function foreach(a, f)
    if a != nil then for k, v in ipairs(a) do f(v) end end
end

function all(a)
    local i, n = 0, a != nil and #a or 0
    return function() i = i + 1 if i <= n then return a[i] end end
end

function del(a, v)
    if a != nil then
        for k, v2 in ipairs(a) do
            if v == v2 then table.remove(a, k) return v end
        end
    end
end

function cartdata(s)
    if __cartdata() then
        print('cartdata() can only be called once')
        abort()
        return false
    end
    -- PICO-8 documentation: id is a string up to 64 characters long
    if #s == 0 or #s > 64 then
        print('cart data id too long')
        abort()
        return false
    end
    -- PICO-8 documentation: legal characters are a..z, 0..9 and underscore (_)
    -- PICO-8 changelog: allow '-' in cartdat() names
    if string.match(s, '[^-abcdefghijklmnopqrstuvwxyz0123456789_]') then
        print('cart data id: bad char')
        abort()
        return false
    end
    return __cartdata(s)
end

function __z8_strlen(s)
    return #string.gsub(s, '[\128-\255]', 'XX')
end

-- Stubs for unimplemented functions
local function stub(s)
    return function(a) __stub(s.."("..(a and '"'..tostr(a)..'"' or "")..")") end
end
save = stub("save")
info = stub("info")
abort = stub("abort")
folder = stub("folder")
resume = stub("resume")
reboot = stub("reboot")
dir = stub("dir")
ls = dir

-- All flip() does for now is yield so that the C++ VM gets a chance
-- to draw something even if Lua is in an infinite loop
function flip()
    _update_buttons()
    yield()
end

-- Load a cart from file or URL
function load(arg)
    local finished, success, msg
    if string.match(arg, '^#') then
        color(6)
        local x,y = cursor()
        print('downloading.. ', x, y)
        cursor(x+14*4, y)
        finished, success, msg = __download(arg)
        while not finished do
            finished, success, msg = __download()
            flip()
        end
    else
        color(14)
        print('not implemented yet')
        success, msg = __load(arg), ""
    end
    if success then
        print('ok')
    else
        color(14)
        print('failed')
        cursor(0, cursor()[2])
        print(msg)
    end
end


--
-- Create a private environment for the cartridge, using a whitelist logic
-- According to https://gist.github.com/josefnpat/bfe4aaa5bbb44f572cd0 :
--  _G global table has been removed.
--
function create_sandbox()
    local t = {}
    for k,v in pairs(_ENV) do
        if __is_api(k) then
            t[k] = v
        end
    end
    return t;
end


--
-- Handle persistence using eris
--
local perms = {}
for k,v in pairs(_ENV) do
    if type(v) == 'function' and __is_api(k) then
        add(perms, k)
    end
end
table.sort(perms)

function persist(cr)
    eris.settings("path", true)
    local t = {[_ENV]=1, [error]=2}
    for i=1,#perms do t[_ENV[perms[i]]] = i+2 end
    collectgarbage('stop')
    local ret = eris.persist(t, cr)
    collectgarbage('restart')
    return ret
end

function unpersist(s)
    local t = {_ENV, error}
    for i=1,#perms do add(t, _ENV[perms[i]]) end
    collectgarbage('stop')
    local ret = eris.unpersist(t, s)
    collectgarbage('restart')
    return ret
end


--
-- Utility functions
--
function __z8_reset_state()
    -- From the PICO-8 documentation:
    -- “The draw state is reset each time a program is run. This is equivalent to calling:
    -- clip() camera() pal() color(6)”
    -- Note from Sam: also add fillp() here.
    clip() camera() pal() color(6) fillp()
end

function __z8_reset_cartdata()
    __cartdata(nil)
end

function __z8_run_cart(cart_code)
    local glue_code = [[--
        if (_init) _init()
        if _update or _update60 or _draw then
            local do_frame = true
            while true do
                if _update60 then
                    _update_buttons()
                    _update60()
                elseif _update then
                    if (do_frame) _update_buttons() _update()
                    do_frame = not do_frame
                end
                if (_draw and do_frame) _draw()
                yield()
            end
        end
    ]]

    __z8_loop = cocreate(function()

        -- First reload cart into memory
        memset(0, 0, 0x8000)
        reload()

        __z8_reset_state()
        __z8_reset_cartdata()

        -- Load cart and run the user-provided functions. Note that if the
        -- cart code returns before the end, our added code will not be
        -- executed, and nothing will work. This is also PICO-8’s behaviour.
        -- The code has to be appended as a string because the functions
        -- may be stored in local variables.
        local code, ex = __z8_load_code(cart_code..glue_code, nil, nil,
                                        create_sandbox())
        if not code then
            color(14) print('syntax error')
            color(6) print(ex)
            error()
        end

        -- Run cart code
        code()
    end)
end

function __z8_tick()
    if (costatus(__z8_loop) == "dead") return -1
    ret, err = coresume(__z8_loop)
    -- XXX: test eris persistence
    __z8_persist_delay += 1
    if __z8_persist_delay > 30 and btnp(13) then
        __z8_persist_delay = 0
        if backup then
            __z8_loop = unpersist(backup)
        else
            backup = persist(__z8_loop)
        end
    end
    if __z8_stopped then __z8_stopped = false -- FIXME: what now?
    -- FIXME: I use __stub because printh() prints nothing in Visual Studio
    elseif not ret then __stub(tostr(err))
    end
    return 0
end


--
-- Splash sequence
--
function __z8_boot_sequence()
    __z8_reset_state()

    local boot =
    {
        [1]  = function() for i=2,127,8 do for j=0,127 do pset(i,j,rnd()*4+j/40) end end end,
        [7]  = function() for i=0,127,4 do for j=0,127,2 do pset(i,j,(i+j)/8%8+6) end end end,
        [12] = function() for i=2,127,4 do for j=0,127,3 do pset(i,j,rnd()*4+10) end end end,
        [17] = function() for i=1,127,2 do for j=0,127 do pset(i,j,pget(i+1,j)) end end end,
        [22] = function() for j=0,31 do memset(0x6040+j*256,0,192) end end,
        [27] = cls,
        [36] = function() local notes = { 0x.5dde, 0x5deb.5be3, 0x.5fef, 0x.57ef, 0x.53ef }
                          for j=0,#notes-1 do poke4(0x3200+j*4,notes[j+1]) end poke(0x3241, 0x0a)
                          sfx(0)
                          local logo = "######  ####  ###  ######  ####       ### "
                                    .. "    ## ##    ## ##   ##   ##  ##     ## ##"
                                    .. "  ###  ##### #####   ##   ##  ## ###  ### "
                                    .. " ###   ##    ####    ##   ### ##     ## ##"
                                    .. "###### ##### ##      ##   ######     #####"
                                    .. "###### ##### ##      ##    ####       ### "
                          for j=0,#logo-1 do pset(j%42,6+j/42,sub(logo,j+1,j+1)=='#'and 7) end
                          local a = {0,0,12,0,0,0,13,7,11,0,14,7,7,7,10,0,15,7,9,0,0,0,8,0,0}
                          for j=0,#a-1 do pset(41+j%5,2+j/5,a[j+1]) end end,
        [45] = function() color(6) print("\n\n\nzepto-8 0.0.0 alpha") end,
        [50] = function() print("(c) 2016-20 sam hocevar et al.\n") end,
        [52] = function() print("type help for help\n") end,
    }

    for step=0,54 do if boot[step] then boot[step]() end flip() end

    __z8_loop = cocreate(__z8_shell)
end

local function do_command(cmd)
    local c = color()
    if string.match(cmd, '^ *$') then
        -- empty line
    elseif string.match(cmd, '^ *run *$') then
        run()
    elseif string.match(cmd, '^ *load[ |(]') then
        load(string.gsub(cmd, '^ *load *', ''))
    elseif cmd == 'help' then
        color(12)
        print('\ncommands\n')
        color(6)
        print('load <filename>')
        print('run')
        print('')
        color(12)
        print('example: load #15133')
        print('         load #dancer')
        print('')
    else
        color(14)
        print('syntax error')
    end
    color(c)
end

function __z8_shell()
    -- activate project
    poke(0x5f2d, 1)
    local history = {}
    local cmd, caret = "", 0
    local start_y = peek(0x5f27)
    while true do
        local exec = false
        -- read next characters and act on them
        local chars = stat(30) and stat(31) or ""
        for n = 1, #chars do
            local c = sub(chars, n, n)
            if c == "\8" then
                if caret > 0 then
                    caret -= 1
                    cmd = sub(cmd, 0, caret)..sub(cmd, caret + 2, #cmd)
                end
            elseif c == "\x7f" then
                if caret < #cmd then
                    cmd = sub(cmd, 0, caret)..sub(cmd, caret + 2, #cmd)
                end
            elseif c == "\r" then
                exec = true
            elseif #cmd < 255 then
                cmd = sub(cmd, 0, caret)..c..sub(cmd, caret + 1, #cmd)
                caret += 1
            end
        end
        -- left/right/up/down handled by buttons instead of keys (FIXME)
        if btnp(0) then
            caret = max(caret - 1, 0)
        elseif btnp(1) then
            caret = min(caret + 1, #cmd)
        elseif btnp(2) and #history > 0 then
            if not history_pos then
                history_pos = #history + 1
            end
            if history_pos == #history + 1 then
                cmd_bak = cmd
            end
            if history_pos > 1 then
                history_pos -= 1
                cmd = history[history_pos]
                caret = #cmd
            end
        elseif btnp(3) and #history > 0 then
            if not history_pos then
                cmd, caret = "", 0
            elseif history_pos <= #history then
                history_pos += 1
                cmd = history[history_pos] or cmd_bak
                caret = #cmd
            end
        end
        -- fixme: print() behaves slightly differently when
        -- scrolling in the command prompt
        local pen = peek(0x5f25)
        if exec then
            start_y = start_y + 6
            cursor(0, start_y)
            rectfill(0, start_y, 127, start_y + 5, 0)
            do_command(cmd)
            start_y = peek(0x5f27)
            flip()
            if (#cmd > 0 and cmd != history[#history]) add(history, cmd)
            history_pos = nil
            cmd, caret = "", 0
        else
            rectfill(0, start_y, (__z8_strlen(cmd) + 3) * 4, start_y + 5, 0)
            color(7)
            print('> ', 0, start_y, 7)
            print(cmd, 8, start_y, 7)
            -- display cursor and immediately hide it after we flip() so that it
            -- does not remain in later frames
            local on = t() * 5 % 2 > 1
            if (on) rectfill(caret * 4 + 8, start_y, caret * 4 + 11, start_y + 4, 8)
            flip()
            if (on) rectfill(caret * 4 + 8, start_y, caret * 4 + 11, start_y + 4, 0)
        end
        poke(0x5f25, pen)
    end
end


--
-- Initialise the VM
--
__z8_loop = cocreate(__z8_boot_sequence)


__gfx__
00000000000000000000000000000000000000000000000000000000000000007770000000000000000000000070700077700000707000000000000070700700
00000000000000000000000000000000000000000000000000000000000000007770777077707070707070700770770070000070777000000000000070707070
00000000000000000000000000000000000000000000000000000000000000007770777070700700000070707770777070000070070007000000000000000700
00000000000000000000000000000000000000000000000000000000000000007770777077707070707070700770770070000070777000007000770000000000
00000000000000000000000000000000000000000000000000000000000000007770000000000000000000000070700000007770070000000700770000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000700707070707770707077000700070007007070000000000000000000707770770077707770707077707000777077707770000000000070000070007770
00000700707077707700007077007000700000700700070000000000000007007070070000700070707070007000007070707070070007000700777007000070
00000700000070700770070077000000700000707770777000007770000007007070070077700770777077707770007077707770000000007000000000700770
00000000000077707770700070700000700000700700070007000000000007007070070070000070007000707070007070700070070007000700777007000000
00000700000070700700707077700000070007007070000070000000070070007770777077707770007077707770007077700070000070000070000070000700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077007000077007000000
70707770770077707700777077707770707077707770707070007770770007707770070077700770777070707070707070707070777070000700007070700000
70707070770070007070770077007000707007000700770070007770707070707070707070707000070070707070707007007770007070000700007000000000
70007770707070007070700070007070777007000700707070007070707070707770770077000070070070707770777070700070700070000700007000000000
07707070777077707700777070007770707077707700707077707070707077007000077070707700070007700700777070707770777077000070077000007770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07007770777007707700777077700770707077707770707070007770770007707770070077700770777070707070707070707070777007700700770000000000
00707070707070007070700070007000707007000700707070007770707070707070707070707000070070707070707070707070007007000700070000700700
00007770770070007070770077007000777007000700770070007070707070707770707077007770070070707070707007007770070077000700077077707070
00007070707070007070700070007070707007000700707070007070707070707000770070700070070070707770777070700070700007000700070070000700
00007070777007707770777070007770707077707700707077707070707077007000077070707700070007700700777070707770777007700700770000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777770707070707000007007777700700070000070000000777000077077000077700000777000007770000777770077777770000777000777770000070000
77777770070707007777777077000770007000700077770007770700077777000770770000777000077777007770077070777070000700007700077000777000
77777770707070707077707077000770700070000077700007777700077777007770777007777700777777707700077077777770000700007707077007777700
77777770070707007077707077707770007000700777700007777700007770000770770000777000070707007770077070000070077700007700077000777000
77777770707070700777770007777700700070000000700000777000000700000077700000707000070777000777770077777770077700000777770000070000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777000007000007777700077777000000000000000000077777007777777070707070077700007000000000777000000700000777007007000700
00000000770077700077700000777000777077707070000070007000770707700000000070707070007000007000700000000000077770000070000077777070
70707070770007707777777000070000770007700700707007070700777077707777777070707070077770007000070007777700000700000777770007007000
00000000770077700777770000777000770007700000070000700070770707700000000070707070707707007070070000000700007007007070007007007000
00000000077777000700070007777700077777000000000000000000077777007777777070707070077007000700000000077000070770000770070007070000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777000000077000700070007770000077777000700000000070000070070000077770000700000007000000077770007777700000700000700077007077770
07777700007700000707777000007000000700000700000007777700077777000000700007770000777777007700007000007000000777007777000007000070
00777000070000000700070000000000077700000700000000070000070070000777777000707700007770000000007000070000007000000700070007000000
07000000007700000700070007000000700000000700070000770000070000000007000007000000000077000000070000070000070000007007770007070000
00777000000077000700700000777700077770000077700000070000007770000000777007007770077770000007700000007000007777000007707007007770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70070000070077000077770007007000770007000077000000000000707777000077700007700000007007000707000007777000007007000707770000070000
07777700770700700707007007077700070007700000000000770000700070000777770000700700077700700077770000700000077777700770707000077700
77070070077000707007007007007000070007000007000007007000707777000007000007777770007000000707707007777000007007700700707000070000
70770770770007707007007007077700070007000707070070000700700770000777700007700700077000700770007000700070000700000000770007777000
07700770070007700770070007077070007770007077007000000070707707700077070000007000007777000000770000077700000700000007000007700700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000070000000077770000700000007777000700770007770000070000000000000000000000000000000000000007777700000077000007000000777000
07000000070007000000700007707700000070007707007000700770077700000000000007070000007000000700000000000700077700000777770000070000
07777700070007000077777000770700007777700770007000777000070070000777000077777000777700000777000000707000000700000000070000070000
00000700007007000700777007700700070000707700070000070700700070700000700007077000707070000700000000700000000700000000700000070000
00777000000070000000770000700770000077000700700000077770700077000007000000700000707700007077700007000000000700000077000007777700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000007000000070000000700000007000000777770000700700000700000777770000700000070007000077777000777000070700700077700000700000
07777770077777000777700000777700007777700000070007777770070070000000070007777770007007000070007000070000070700700000000000700000
00077000007007000007000007000700070070000000070000700700007000000000700000700700000007000700707007777700000007000777770000777000
07707000070007000777770000007000000070000000070000000700000007700007700000700000000070000000077000070000000070000007000000700700
00077000070077000007000000070000000700000777770000007000007770000770070000077700000700000000700000700000007700000070000000700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000000000000777770000070000000007000000700007000000077777000077000000070000077777000077770000070000000000700777770000707770
07777700007770000000070007777700000007000070070007007700000007000700700007777700000007000000000000700000000707000007000007770070
00070000000000000007070000000700000070000070070007770000000007007000070000070000007070000777770000700700000070000777777000700700
00070000000000000000770077777070000700000700007007000000000070000000007007070700000700000000000007000770000707700007000000070000
00700000077777000077000000070000077000000700007000777700007700000000000070770070000070000777700007777070077000000000777000070000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077770077770000077700000700700007070000700000007777770077777000777770070000000000000000000000000000000000000000007000000070000
00000070000070000000000000700700007070000700000007000070070007000000070007000000707070000700000000000000077700000070000000007000
00000700077777000777770000700700007070000700000007000070000007000777770000007000000070007777700007770000077770007700077077000770
00000700000070000000070000000700007070700700770007000070000070000000070000070000000700000700700000070000000700000000700000700000
00777770077770000007700000077000070077000777000007777770000700000007700077700000077000000070000007777000077700000007000000070000
