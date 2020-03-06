//
//  ZEPTO-8 — Fantasy console emulator
//
//  Copyright © 2017—2020 Sam Hocevar <sam@hocevar.net>
//
//  This program is free software. It comes without any warranty, to
//  the extent permitted by applicable law. You can redistribute it
//  and/or modify it under the terms of the Do What the Fuck You Want
//  to Public License, Version 2, as published by the WTFPL Task Force.
//  See http://www.wtfpl.net/ for more details.
//

#pragma once

// The splore class
// ————————————————
// This will be a Splore implementation to access BBS games.

namespace z8
{

class splore
{
public:
    splore()
    {}

    bool dump(char const *filename);
};

} // namespace z8

