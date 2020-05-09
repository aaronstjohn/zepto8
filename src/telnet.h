//
//  ZEPTO-8 — Fantasy console emulator
//
//  Copyright © 2016—2020 Sam Hocevar <sam@hocevar.net>
//
//  This program is free software. It comes without any warranty, to
//  the extent permitted by applicable law. You can redistribute it
//  and/or modify it under the terms of the Do What the Fuck You Want
//  to Public License, Version 2, as published by the WTFPL Task Force.
//  See http://www.wtfpl.net/ for more details.
//

#pragma once

#include <lol/msg>    // lol::msg
#include <lol/utils>  // lol::ends_with
#include <lol/thread> // lol::timer
#include <lol/vector> // lol::ivec2
#include <vector>     // std::vector

#if HAVE_UNISTD_H
#   include <unistd.h>
#endif
#if HAVE_SYS_SELECT_H
#   include <sys/select.h>
#endif

#include "zepto8.h"
#include "pico8/vm.h"
#include "raccoon/vm.h"

// The telnet class
// ————————————————
// This is a high-level telnet server that runs a ZEPTO-8 VM.

namespace z8
{

struct telnet
{
    std::vector<uint8_t> m_screen;
    lol::ivec2 m_term_size = lol::ivec2(128, 64);

    void run(std::string const &cart)
    {
        disable_echo();

        std::unique_ptr<z8::vm_base> vm;
        if (lol::ends_with(cart, ".rcn.json"))
            vm.reset((z8::vm_base *)new raccoon::vm());
        else
            vm.reset((z8::vm_base *)new pico8::vm());
        vm->load(cart);
        vm->run();

        auto const &ram = vm->ram();

        while (true)
        {
            lol::timer t;

            for (int i = 0; i < 16; ++i)
                vm->button(i, 0);

            for (;;)
            {
                int key = get_key();
                if (key < 0)
                    break;

                switch (key)
                {
                    /* For now, Escape quits */
                    case 0x1b: return;

                    case 0x144: vm->button(0, 1); break; // left
                    case 0x143: vm->button(1, 1); break; // right
                    case 0x141: vm->button(2, 1); break; // up
                    case 0x142: vm->button(3, 1); break; // down
                    case 'z': case 'Z':
                    case 'c': case 'C':
                    case 'n': case 'N': vm->button(4, 1); break;
                    case 'x': case 'X':
                    case 'v': case 'V':
                    case 'm': case 'M': vm->button(5, 1); break;
                    case '\r': case '\n': vm->button(6, 1); break;
                    case 's': case 'S': vm->button(8, 1); break;
                    case 'f': case 'F': vm->button(9, 1); break;
                    case 'e': case 'E': vm->button(10, 1); break;
                    case 'd': case 'D': vm->button(11, 1); break;
                    case 'a': case 'A': vm->button(12, 1); break;
                    case '\t':
                    case 'q': case 'Q': vm->button(13, 1); break;
                    default:
                        lol::msg::info("Got unknown key %02x\n", key);
                        break;
                }
            }

            vm->step(1.f / 60.f);

            vm->print_ansi(m_term_size,
                           m_screen.empty() ? nullptr : m_screen.data());

            // FIXME: PICO-8 specific
            m_screen.resize(0x2000);
            ::memcpy(m_screen.data(), std::get<0>(ram) + 0x6000, 0x2000);

            t.wait(1.f / 60.f);
        }
    }

    void disable_echo()
    {
#if HAVE_UNISTD_H
        uint8_t const message[] =
        {
            0xff, 0xfb, 0x03, // WILL suppress go ahead (no line buffering)
            0xff, 0xfe, 0x22, // DONT linemode (no idea what it does)
            0xff, 0xfb, 0x01, // WILL echo (actually disables local echo)
            0xff, 0xfd, 0x1f, // DO NAWS (window size negociation)
        };

        write(STDOUT_FILENO, message, sizeof(message));
#endif
    }

    int get_key()
    {
#if HAVE_UNISTD_H
        static std::string seq;

        fd_set fds;
        FD_ZERO(&fds);
        FD_SET(STDIN_FILENO, &fds);

        struct timeval tv;
        tv.tv_sec = tv.tv_usec = 0;

        select(STDIN_FILENO + 1, &fds, NULL, NULL, &tv);

        if (!FD_ISSET(0, &fds))
            return -1;

        char ch;
        if (read(STDIN_FILENO, &ch, 1) <= 0)
            exit(EXIT_SUCCESS);

        if (ch != '\x1b' && ch != '\xff' && seq.length() == 0)
            return ch;

        seq += ch;

        // TELNET commands
        if (seq[0] == '\xff') // telnet commands
        {
            if (seq[1] >= '\xfb' && seq[1] <= '\xfe')
            {
                if (seq[2] == 0)
                    return -1; // wait for more data
                goto reset;
            }
            else if (seq[1] == '\xfa') // subnegociation
            {
                if (seq[2] == 0)
                    return -1; // wait for more data
                if (seq[2] != '\x1f')
                    goto reset; // can’t happen
                if (seq.length() < 9)
                    return -1; // wait for more data
                m_term_size.x = (uint8_t)seq[3] * 256 + (uint8_t)seq[4];
                m_term_size.y = (uint8_t)seq[5] * 256 + (uint8_t)seq[6];
                printf("\x1b[2J"); // clear screen
                m_screen.clear();
                goto reset;
            }
            else if (seq.length() >= 3)
            {
                goto reset;
            }

            return -1;
        }

        // Escape sequences
        if (seq[0] == '\x1b')
        {
            if (seq[1] == '\x5b')
            {
                if (seq[2] == 0)
                    return -1; // wait for more data
                int ret = 0x100 + seq[2];
                seq = "";
                return ret;
            }
            else if (seq[1] == '\x1b')
            {
                seq = "";
                return '\x1b';
            }

            return -1;
        }

reset:
        seq = "";
#endif
        return -1;
    }
};

} // namespace z8

