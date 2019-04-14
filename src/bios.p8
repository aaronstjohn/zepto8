pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--
--  ZEPTO-8 — Fantasy console emulator
--
--  Copyright © 2016—2019 Sam Hocevar <sam@hocevar.net>
--
--  This program is free software. It comes without any warranty, to
--  the extent permitted by applicable law. You can redistribute it
--  and/or modify it under the terms of the Do What the Fuck You Want
--  to Public License, Version 2, as published by the WTFPL Task Force.
--  See http://www.wtfpl.net/ for more details.
--


--
-- Private object -- should be refactored in a better way
--
_z8 = {
    stopped=false
}


--
-- Aliases for PICO-8 compatibility
--
do
    -- According to https://gist.github.com/josefnpat/bfe4aaa5bbb44f572cd0 :
    --  coroutine.[create|resume|status|yield]() was removed in 0.1.3 but added
    --  in 0.1.6 as coroutine(), cocreate(), coresume(), costatus() and yield()
    --  respectively.
    cocreate = coroutine.create
    coresume = coroutine.resume
    costatus = coroutine.status
    yield = coroutine.yield

    -- The debug library is not needed either, but we need trace()
    trace = debug.traceback

    local error = error
    function stop() _z8.stopped = true error() end

    function assert(cond, msg)
        if not cond then
            color(14) print("assertion failed:")
            color(6) print(msg or "assert()")
            stop()
        end
    end

    -- use closure so that we don’t need “table” later
    local insert = table.insert
    local remove = table.remove

    function count(a) return a != nil and #a or 0 end
    function add(a, x) if a != nil then insert(a, x) end return x end
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
                if v == v2 then remove(a, k) return end
            end
        end
    end

    -- PICO-8 documentation: t() aliased to time()
    t = time

    -- Use the new peek4() and poke4() functions
    function dget(n)
        n = tonumber(n)
        return n >= 0 and n < 64 and peek4(0x5e00 + 4 * n) or 0
    end

    function dset(n, x)
        n = tonumber(n)
        if n >= 0 and n < 64 then poke4(0x5e00 + 4 * n, x) end
    end

    local match = string.match
    local gsub = string.gsub
    local __cartdata = __cartdata

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
        if match(s, '[^abcdefghijklmnopqrstuvwxyz0123456789_]') then
            print('cart data id: bad char')
            abort()
            return false
        end
        return __cartdata(s)
    end

    function _z8.strlen(s)
        return #gsub(s, '[\128-\255]', 'XX')
    end

    _z8.load = load

    -- Stubs for unimplemented functions
    local function stub(s)
        return function(a) __stub(s.."("..(a and '"'..tostr(a)..'"' or "")..")") end
    end
    load = stub("load")
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

    -- Backward compatibility for old PICO-8 versions
    mapdraw = map
end


--
-- According to https://gist.github.com/josefnpat/bfe4aaa5bbb44f572cd0 :
--  _G global table has been removed.
--
_G = nil


--
-- Hide these functions from lbaselib
-- Must keep: assert, getmetatable, load, pairs, print, rawequal, rawlen,
-- rawget, rawset, setmetatable, type
--
collectgarbage, dofile, error, ipairs, loadfile, loadstring, next, pcall,
select, tonumber, tostring, xpcall = nil


--
-- Hide these modules, they should not be accessible
--
table, debug, string, io, coroutine = nil


--
-- Utility functions
--
function _z8.reset_state()
    -- These variables are global but can be overridden
    ⬅️, ➡️, ⬆️, ⬇️, 🅾️, ❎, ◆ = 0, 1, 2, 3, 4, 5, 6

    -- From the PICO-8 documentation:
    -- “The draw state is reset each time a program is run. This is equivalent to calling:
    -- clip() camera() pal() color(6)”
    -- Note from Sam: also add fillp() here.
    clip() camera() pal() color(6) fillp()
end

function _z8.reset_cartdata()
    __cartdata(nil)
end

function _z8.run_cart(cart_code)
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

    _z8.loop = cocreate(function()

        -- First reload cart into memory
        memset(0, 0, 0x8000)
        reload()

        _z8.reset_state()
        _z8.reset_cartdata()

        -- Load cart and run the user-provided functions. Note that if the
        -- cart code returns before the end, our added code will not be
        -- executed, and nothing will work. This is also PICO-8’s behaviour.
        -- The code has to be appended as a string because the functions
        -- may be stored in local variables.
        local code, ex = _z8.load(cart_code..glue_code)
        if not code then
          color(14) print('syntax error')
          color(6) print(ex)
          error()
        end

        -- Run cart code
        code()
    end)
end

function _z8.tick()
    if (costatus(_z8.loop) == "dead") return -1
    ret, err = coresume(_z8.loop)
    if _z8.stopped then _z8.stopped = false -- FIXME: what now?
    elseif not ret then printh(tostr(err))
    end
    return 0
end


--
-- Splash sequence
--
function _z8.boot_sequence()
    _z8.reset_state()

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
        [45] = function() color(6) print("\n\n\nzepto-8 0.0.0 beta") end,
        [50] = function() print("(c) 2016-19 sam hocevar et al.\n") end,
        [52] = function() print("type help for help\n") end,
    }

    for step=0,54 do if boot[step] then boot[step]() end flip() end

    _z8.loop = cocreate(_z8.prompt)
end

function _z8.prompt()
    -- activate project
    poke(0x5f2d, 1)
    local caret = 0
    local cmd = ""
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
        if btnp(0) then
            caret = max(caret - 1, 0)
        elseif btnp(1) then
            caret = min(caret + 1, #cmd)
        end
        -- fixme: print() behaves slightly differently when
        -- scrolling in the command prompt
        if exec then
            start_y = start_y + 6
            cursor(0, start_y)
            rectfill(0, start_y, 127, start_y + 5, 0)
            color(14)
            if cmd == 'help' then
                print('no help yet lol')
            else
                print('syntax error')
            end
            start_y = peek(0x5f27)
            caret = 0
            flip()
            cmd = ""
        else
            local pen = peek(0x5f25)
            rectfill(0, start_y, (_z8.strlen(cmd) + 3) * 4, start_y + 5, 0)
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
srand(0)
_z8.loop = cocreate(_z8.boot_sequence)


__gfx__
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
00007070707070007070700070007070707007000700707070007070707070707000770070700070070070707770777070700070700007000700070070007070
00007070777007707770777070007770707077707700707077707070707077007000077070707700070007700700777070707770777007700700770000007770
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777770707070707000007007777700700070000070000000777000077077000077700000777000007770000777770077777770000777000777770000070000
77777770070707007777777077000770007000700077770007770700077777000770770000777000077777007770077070777070000700007700077000777000
77777770707070707077707077000770700070000077700007777700077777007770777007777700777777707700077077777770000700007707077007777700
77777770070707007077707077707770007000700777700007777700007770000770770000777000070707007770077070000070077700007700077000777000
77777770707070700777770007777700700070000000700000777000000700000077700000707000070777000777770077777770077700000777770000070000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777000007000007777700077777000000000000000000077777007777777070707070000000000000000000000000000000000000000000000000
00000000770077700077700000777000777077707070000070007000770707700000000070707070000000000000000000000000000000000000000000000000
70707070770007707777777000070000770007700700707007070700777077707777777070707070000000000000000000000000000000000000000000000000
00000000770077700777770000777000770007700000070000700070770707700000000070707070000000000000000000000000000000000000000000000000
00000000077777000700070007777700077777000000000000000000077777007777777070707070000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
