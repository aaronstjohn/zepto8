pico-8 cartridge // http://www.pico-8.com
version 28
__lua__
--
--  ZEPTO-8 — Fantasy console emulator
--
--  Copyright © 2016—2021 Sam Hocevar <sam@hocevar.net>
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
json = dofile("./lua/json.lua")
__z8_stopped = false
__z8_load_code = load
__z8_persist_delay = 0


-- Backward compatibility for old PICO-8 versions
-- PICO-8 documentation: t() aliased to time()
t = time
mapdraw = map

-- These variables can be used for button names
⬅️ = 0  ➡️ = 1  ⬆️ = 2  ⬇️ = 3  🅾️ = 4  ❎ = 5

-- These variables encode fillp patterns
 █ = 0         ▒ = 0x5a5a.8  🐱 = 0x511f.8   ░ = 0x7d7d.8  ✽ = 0xb81d.8
 ● = 0xf99f.8  ♥ = 0x51bf.8   ☉ = 0xb5bf.8  웃 = 0x999f.8  ⌂ = 0xb11f.8
😐 = 0xa0e0.8  ♪ = 0x9b3f.8   ◆ = 0xb1bf.8   … = 0xf5ff.8  ★ = 0xb15f.8
 ⧗ = 0x1b1f.8  ˇ = 0xf5bf.8   ∧ = 0x7adf.8   ▤ = 0x0f0f.8  ▥ = 0x5555.8


--
-- Save these functions because they are needed by some of our public functions
-- but will not be propagated to the cart through _ENV.
--
local error = error
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

-- Experimenting with count() on PICO-8 shows that it returns the number
-- of non-nil elements between c[1] and c[#c], which is slightly different
-- from returning #c in cases where the table is no longer an array. See
-- the tables.p8 unit test cart for more details.
--
-- We also try to mimic the PICO-8 error messages:
--  count(nil) → attempt to get length of local 'c' (a nil value)
--  count("x") → attempt to index local 'c' (a string value)
function count(c)
    local cnt,max = 0,#c
    for i=1,max do if (c[i] != nil) cnt+=1 end
    return cnt
end

-- It looks like table.insert() would work here but we also try to mimic
-- the PICO-8 error messages:
--  add("") → attempt to index local 'c' (a string value)
function add(c, x, i)
    if c != nil then
        -- insert at i if specified, otherwise append
        i=i and mid(1,i\1,#c+1) or #c+1
        for j=#c,i,-1 do c[j+1]=c[j] end
        c[i]=x
        return x
    end
end

function del(c,v)
    if c != nil then
        local max = #c
        for i=1,max do
            if c[i]==v then
                for j=i,max do c[j]=c[j+1] end
                return v
            end
        end
    end
end

function deli(c,i)
    if c != nil then
        -- delete at i if specified, otherwise at the end
        i=i and mid(1,i\1,#c) or #c
        local v=c[i]
        for j=i,#c do c[j]=c[j+1] end
        return v
    end
end

function all(c)
    if (c==nil or #c==0) return function() end
    local i,prev = 1,nil
    return function()
        -- increment unless the current value changed
        if (c[i]==prev) i+=1
        -- skip until non-nil or end of table
        while (i<=#c and c[i]==nil) i+=1
        prev=c[i]
        return prev
    end
end

function foreach(c, f)
     for v in all(c) do f(v) end
end

sub = string.sub
pack = table.pack
unpack = table.unpack

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
        local x,y = cursor()
        cursor(0, y)
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
    -- Note from Sam: color() is actually short for color(6)
    -- Note from Sam: also add fillp() here.
    clip() camera() pal() color() fillp()
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
                else
                    _update_buttons()
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

-- FIXME: this function is quite a mess
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

    if __z8_stopped then
        __z8_stopped = false -- FIXME: what now?
    elseif not ret then
        -- FIXME: I use __stub because printh() prints nothing in Visual Studio
        __stub(tostr(err))
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

local function print_clear(s)
    -- empty next line
    local y, c = @0x5f27, color(0)
    rectfill(0, y, 127, y + 5)
    color(c)
    print(s)
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
        print_clear('') print_clear('commands') print_clear('')
        color(6)
        print_clear('load <filename>')
        print_clear('run')
        print_clear('')
        color(12)
        print_clear('example: load #15133')
        print_clear('         load #dancer')
        print_clear('')
    else
        color(14)
        print_clear('syntax error')
    end
    color(c)
end

function __z8_shell()
    -- activate project
    poke(0x5f2d, 1)
    local history = {}
    local cmd, caret = "", 0
    local start_y = @0x5f27
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
        local pen = @0x5f25
        if exec then
            -- return was pressed, so print an empty line to ensure scrolling
            cursor(0, start_y)
            print('')
            start_y = @0x5f27
            do_command(cmd)
            start_y = @0x5f27
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
00000000000000000000077000000000000000000000000000000000000000007770000000000000000000000070700077700000707000000000000070700700
00000000000000000000070000000000000000000000000000000000000000007770777077707070707070700770770070000070777000000000000070707070
00000000000000000000770000000000000000000000000000000000000000007770777070700700000070707770777070000070070007000000000000000700
00000000000000000000000000000000000000000000000000000000000000007770777077707070707070700770770070000070777000007000770000000000
00000000000000000000777000000000000000000000000000000000000000007770000000000000000000000070700000007770070000000700770000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000700707070707770707077000700070007007070000000000000000000707770770077707770707077707000777077707770000000000070000070007770
00000700707077707700007077007000700000700700070000000000000007007070070000700070707070007000007070707070070007000700777007000070
00000700000070700770070007700000700000707770777000007770000007007070070077700770777077707770007077707770000000007000000000700770
00000000000077707770700070700000700000700700070007000000000007007070070070000070007000707070007070700070070007000700777007000000
00000700000070700700707077700000070007007070000070000000070070007770777077707770007077707770007077700070000070000070000070000700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077007000077007000000
70700770770007707700777077700770707077707770707070007770770007700770070077000770777070707070707070707070777070000700007070700000
70707070770070007070770077007000707007000700770070007770707070707070707070707000070070707070707007007770007070000700007000000000
70007770707070007070700070007070777007000700707070007070707070707770770077000070070070707770777007000070700070000700007000000000
07707070777007707700077070007770707077707700707007707070707077007000077070707700070007700700777070707700777077000070077000007770
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
00000000077777000007000007777700077777000000000000000000077777007777777070707070077700007000700000770000000700000777007007000700
00000000770077700077700000777000777077707070000070007000770707700000000070707070007000007000070007777000077770000070000077777070
70707070770007707777777000070000770007700700707007070700777077707777777070707070077770007000070000000700000700000777770007007000
00000000770077700777770000777000770007700000070000700070770707700000000070707070707707007070070000000700007007007070007007007000
00000000077777000700070007777700077777000000000000000000077777007777777070707070077007000700000000777000070770000770070007070000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07777000000070000700070007777000000700000700000000070000070070000077770007000000777700000777770007777700000700000700770007077770
00070000007700000707777000000700007777000700000007777700777777000000700077700000070000000000007000007000000777007770000007000070
00777700070000000700070000000000000070000700000000070000070070000777777007007700077700000000007000070000007000000700700007000000
70007000007700000700070007000000070000000700070000770000070000000070000007000000000070000000070000070000070000000007777007070000
07700000000070000700700000777700007700000077700000070000007770000007770007007700007770000007700000007000007777000007700007007770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70070000070770000077770007007000770007000077000000000000707777700777770007700000007007000707000007777000007070000707770000700000
07777700777007000707007007077700070007700000000000770000700777700077770000700700077700700077770000700000077777000770707000777000
77070070070007007007007007007000070007000007000007007000700070000007000007777770007000000707707007777000007007000700707000700000
70770770770077707007007007077700070007000707070070000700707777000777700007700700077000700770007000700070000700000000770007777000
07700770070077000770007007077000007770007077007000000070707770700777070000007000007777000000770000077700000700000007000007700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000070007000777770000700000077777000707700007770000007000000000000000000000000000000000000007777700000077000007000007777700
07000000070007000007700007707700000770007770070000700770070000000000000007070000007000000070000000000700000700000777770000070000
07777700077007000070070000770700007007000700070000777000077000000777000077777000777700000077000000707000077700000700070000070000
00000700000007000700777007700700070000707700070000070700770707000000700007007000707070000770000000700000000700000000070000070000
00777000000770000000770000700770000077000700700000077770700770000007000000700000707700000777000007000000000700000007700007777700
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007000007000000007000000777700007000000777770000700700077000000777770000700000070007000777770000777000070707000077700000700000
07777770077777000777770000700700007777700000070007777770000007000000070007777700007007000700070000070000070707000000000000700000
00077000007007000007000007000700070070000000070000700700077007000000700000700700000007007077070007777700000007000777770000777000
00707000070007000777770000007000000070000000070000000700000070000007700000700000000070000000770000070000000070000007000000700700
07007000070077000007000000070000000700000777770000007000007700000770070000077700007700000077000000700000007700000070000000700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000000000000777770000070000000007000000700007000000077777000077000000070000077777000077770000070000000000700777700000700000
07777700007770000000070007777700000007000070070007777000000007000700700007777700000007000000000000700000000707000070000007777700
00070000000000000007070000007700000007000070070007000000000007007000070000070000007070000777770000700700000070000777700000700700
00070000000000000000700007777070000070000070007007000000000070000000007007070700000700000000000007000070000707700070000000700000
00700000077777000077070000070000077700000700007000777000007700000000000007070700000070000777700007777770077000000077770000700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777000077770000777770000700700007070000700000007777700077777000777770007700000000000000000000000000000000000000007000000070000
00007000000070000000000000700700007070000700000007000700070007000000070000000700707070000070000000000000007770000070000000007000
00007000077770000777770000700700007070000700070007000700000007000077770000000700000070000777700000770000000770007700077077000770
00007000000070000000070000000700007070700700700007000700000070000000070000007000000700000070700000070000000070000000700000700000
07777700077770000007700000007000070077000777000007777700007700000007700007770000077000000070000007777000007770000007000000070000
