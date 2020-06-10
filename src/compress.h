//
//  ZEPTO-8 — Fantasy console emulator
//
//  Copyright © 2017—2018 Sam Hocevar <sam@hocevar.net>
//
//  This program is free software. It comes without any warranty, to
//  the extent permitted by applicable law. You can redistribute it
//  and/or modify it under the terms of the Do What the Fuck You Want
//  to Public License, Version 2, as published by the WTFPL Task Force.
//  See http://www.wtfpl.net/ for more details.
//

#pragma once

#include <string>
#include <vector>
#include <cstdint>

namespace z8
{

std::vector<uint8_t> compress(std::vector<uint8_t> &input);
std::string encode49(std::vector<uint8_t> const &v);

} // namespace z8

