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

#if HAVE_CONFIG_H
#   include "config.h"
#endif

#include <lol/engine.h> // lol::File
#include <lol/cli>   // lol::cli
#include <lol/msg>   // lol::msg
#include <lol/utils> // lol::ends_with
#include <fstream>   // std::ofstream
#include <sstream>
#include <iostream>
#include <streambuf>
#if _MSC_VER
#include <io.h>
#include <fcntl.h>
#endif

#include "zepto8.h"
#include "pico8/vm.h"
#include "pico8/pico8.h"
#include "raccoon/vm.h"
#include "telnet.h"
#include "splore.h"
#include "dither.h"
#include "minify.h"
#include "compress.h"

enum class mode
{
    none,

    test,
    stats,
    luamin,
    listlua,
    printast,
    convert,
    run, headless, telnet,

    dither,
    compress,
    splore,
};

static void usage()
{
    printf("Usage: z8tool stats <cart>\n");
    printf("       z8tool convert <cart> [--data <file>] <output.p8|output.p8.png|output.bin>\n");
    printf("       z8tool listlua <cart>\n");
    printf("       z8tool printast <cart>\n");
#if HAVE_UNISTD_H
    printf("       z8tool run [--headless|--telnet] <cart>\n");
#else
    printf("       z8tool run [--headless] <cart>\n");
#endif
    printf("       z8tool --dither [--hicolor] [--error-diffusion] <image> [-o <file>]\n");
    printf("       z8tool --compress [--raw <num>] [--skip <num>]\n");
    printf("       z8tool --splore <image>\n");
}

void test()
{
#if 1
    for (int t = 0; t < 3; ++t)
    {
        int chars = 65536;
        int as = 10;
        std::string data;
        for (int i = 0; i < chars; ++i)
            data += char(0x10 + lol::rand(as));
        z8::pico8::code::compress(data, z8::pico8::code::format::pxa);
    }
#elif 0
    int foo[] = { 2, 4, 8, 10, 16, 64, 128, 224, 256 };
    for (int as : foo)
    {
        int bytes = 2048;
        int chars = int(std::ceil(bytes * 8.f / std::log2(float(as))));
        int comp[4];
        for (int k = 0; k < 4; ++k)
        {
            std::string data;
            for (int i = 0; i < chars; ++i)
                data += char(0x10 + lol::rand(as));
            comp[k] = int(z8::pico8::code::compress(data, z8::pico8::code::format::pxa).size()) - 8;
        }
        float mean = 0.25f * (comp[0] + comp[1] + comp[2] + comp[3]);
        float eff = mean / bytes;
        printf("%d %d %d %d %d %d %d %f %f\n", as, bytes, chars,
               comp[0], comp[1], comp[2], comp[3], mean, eff);
    }
#else
    // alphabet size
    for (int a = 16; a <= 240; ++a)
    {
        float bits = std::log2(float(a));

        // char group size
        for (int n = 1; n < 32; ++n)
        {
            // total bits that a group can encode
            float gbits = n * bits;
            // effective bits it will encode
            int ebits = int(std::floor(gbits));

            if (ebits <= 0 || ebits > 64)
                continue;

            // amount of data we want to encode
            int bytes = 2048;
            // number of chars this represents
            int nchars = int(std::ceil(bytes * 8.f / ebits * n));

            std::string data;
            for (int i = 0; i < nchars; ++i)
                data += char(0x10 + lol::rand(a));

            auto compressed = z8::pico8::code::compress(data, z8::pico8::code::format::pxa);

            printf("% 3u % 2u % 3.4f % 2u % 5u %f\n", a, n, gbits, ebits, nchars, bytes / float(compressed.size()));
            fflush(stdout);
        }
    }
#endif
}

int main(int argc, char **argv)
{
    lol::sys::init(argc, argv);

    mode run_mode = mode::none;
    std::string in, out, data;
    size_t raw = 0, skip = 0;
    bool hicolor = false;
    bool error_diffusion = false;

    auto help = lol::cli::required("-h", "--help").call([]()
                    { ::usage(); exit(EXIT_SUCCESS); });

    auto commands0 =
    (
        (
            lol::cli::command("test").set(run_mode, mode::test)
        )
    );

    auto commands1 =
    (
        (
            // p8tool interface
            lol::cli::command("stats").set(run_mode, mode::stats) |
            lol::cli::command("listlua").set(run_mode, mode::listlua) |
            lol::cli::command("luamin").set(run_mode, mode::luamin) |
            lol::cli::command("printast").set(run_mode, mode::printast) |
            // custom interface
            ( lol::cli::command("run").set(run_mode, mode::run),
#if HAVE_UNISTD_H
              lol::cli::option("--telnet").set(run_mode, mode::telnet),
#endif
              lol::cli::option("--headless").set(run_mode, mode::headless)
            )
        ),
        lol::cli::value("cart", in)
    );

    auto commands2 =
    (
        (
            // not from p8tool (it has writep8 instead)
            lol::cli::command("convert").set(run_mode, mode::convert)
        ),
        lol::cli::option("--data") & lol::cli::value("file", data),
        lol::cli::value("cart", in),
        lol::cli::value("output", out)
    );

    auto other =
    (
        lol::cli::required("--splore").set(run_mode, mode::splore),
        lol::cli::value("cart", in),
        lol::cli::option("-o") & lol::cli::value("file", out)
    );

    auto dither =
    (
        lol::cli::required("--dither").set(run_mode, mode::dither),
        lol::cli::option("--hicolor").set(hicolor, true),
        lol::cli::option("--error-diffusion").set(error_diffusion, true),
        lol::cli::value("image").set(in),
        lol::cli::option("-o") & lol::cli::value("output", out)
    );

    auto compress =
    (
        lol::cli::required("--compress").set(run_mode, mode::compress),
        lol::cli::option("--raw") & lol::cli::value("num", raw),
        lol::cli::option("--skip") & lol::cli::value("num", skip)
    );

    auto commands = commands0 | commands1 | commands2 | other | dither | compress;
    auto success = lol::cli::parse(argc, argv, help | commands);

    if (!success)
    {
        usage();
        return EXIT_FAILURE;
    }

    // Most commands manipulate a cart, so get it right now
    z8::pico8::cart cart;

    switch (run_mode)
    {
    case mode::test:
        test();
        break;

    case mode::stats: {
        cart.load(in);
        printf("Code size: %d\n", (int)cart.get_p8().size());
        printf("Compressed code size: %d\n", (int)cart.get_compressed_code().size());

        auto &code = cart.get_code();
        if (z8::pico8::code::parse(code))
            printf("Code is valid\n");
        else
            printf("Code has syntax errors\n");
        break;
    }
    case mode::listlua:
        cart.load(in);
        printf("%s", cart.get_p8().c_str());
        break;

    case mode::luamin:
        cart.load(in);
        std::cout << z8::minify(cart.get_code()) << '\n';
        break;

    case mode::printast: {
        cart.load(in);
        auto &code = cart.get_code();
        printf("%s", z8::pico8::code::ast(code).c_str());
        break;
    }
    case mode::convert:
        cart.load(in);
        if (data.length())
        {
            std::string s;
            lol::File f;
            for (auto const &candidate : lol::sys::get_path_list(data))
            {
                f.Open(candidate, lol::FileAccess::Read);
                if (f.IsValid())
                {
                    s = f.ReadString();
                    f.Close();

                    lol::msg::debug("loaded file %s (%d bytes, max %d)\n",
                                    candidate.c_str(), int(s.length()), 0x4300);
                    break;
                }
            }
            using std::min;
            memcpy(&cart.get_rom(), s.c_str(), min(s.length(), size_t(0x4300)));
        }

        if (lol::ends_with(out, ".bin"))
        {
            std::ofstream f(out, std::ios::binary);
            auto const &bin = cart.get_bin();
            f.write((char const *)bin.data(), bin.size());
        }
        else if (lol::ends_with(out, ".png"))
            cart.get_png().save(out);
        else
            std::ofstream(out) << cart.get_p8();

        break;

    case mode::headless:
    case mode::run: {
        std::unique_ptr<z8::vm_base> vm;
        if (lol::ends_with(in, ".rcn.json"))
            vm.reset((z8::vm_base *)new z8::raccoon::vm());
        else
            vm.reset((z8::vm_base *)new z8::pico8::vm());
        vm->load(in);
        vm->run();
        for (bool running = true; running; )
        {
            lol::timer t;
            running = vm->step(1.f / 60.f);
            if (run_mode != mode::headless)
            {
                vm->print_ansi(lol::ivec2(128, 64), nullptr);
                t.wait(1.f / 60.f);
            }
        }
        break;
    }

    case mode::dither:
        z8::dither(in, out, hicolor, error_diffusion);
        break;

    case mode::compress: {
        std::vector<uint8_t> input;
#if _MSC_VER
        _setmode(_fileno(stdin), _O_BINARY);
#endif
        for (uint8_t ch : std::vector<char>{ std::istreambuf_iterator<char>(std::cin),
                                             std::istreambuf_iterator<char>() })
            input.push_back(ch);

        // Compress input buffer
        std::vector<uint8_t> output = z8::compress(input);

        // Output result, encoded according to user-provided flags
        if (raw > 0)
        {
            fwrite(output.data(), 1, std::min(raw, output.size()), stdout);
        }
        else
        {
            if (skip > 0)
                output.erase(output.begin(), output.begin() + std::min(skip, output.size()));
            std::cout << z8::encode59(output) << '\n';
        }
        break;
    }
    case mode::splore: {
        z8::splore splore;
        splore.dump(in);
        break;
    }
#if HAVE_UNISTD_H
    case mode::telnet: {
        z8::telnet telnet;
        telnet.run(in);
        break;
    }
#endif
    default:
        usage();
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}

