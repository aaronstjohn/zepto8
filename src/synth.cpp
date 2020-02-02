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

#if HAVE_CONFIG_H
#   include "config.h"
#endif

#include "synth.h"

namespace z8
{

float synth::waveform(int instrument, float advance)
{
    float t = lol::fmod(advance, 1.f);
    float ret = 0.f;

    // Multipliers were measured from PICO-8 WAV exports. Waveforms are
    // inferred from those exports by guessing what the original formulas
    // could be.
    switch (instrument)
    {
        case INST_TRIANGLE:
            return 0.354f * (lol::abs(4.f * t - 2.0f) - 1.0f);
        case INST_TILTED_SAW:
        {
            static float const a = 0.9f;
            ret = t < a ? 2.f * t / a - 1.f
                        : 2.f * (1.f - t) / (1.f - a) - 1.f;
            return ret * 0.406f;
        }
        case INST_SAW:
            return 0.653f * (t < 0.5f ? t : t - 1.f);
        case INST_SQUARE:
            return t < 0.5f ? 0.25f : -0.25f;
        case INST_PULSE:
            return t < 1.f / 3 ? 0.25f : -0.25f;
        case INST_ORGAN:
            ret = t < 0.5f ? 3.f - lol::abs(24.f * t - 6.f)
                           : 1.f - lol::abs(16.f * t - 12.f);
            return ret / 9.f;
        case INST_NOISE:
        {
            // Spectral analysis indicates this is some kind of brown noise,
            // but losing almost 10dB per octave. I thought using Perlin noise
            // would be fun, but it’s definitely not accurate.
            //
            // This may help us create a correct filter:
            // http://www.firstpr.com.au/dsp/pink-noise/
            static lol::perlin_noise<1> noise;
            for (float m = 1.75f, d = 1.f; m <= 128; m *= 2.25f, d *= 0.75f)
                ret += d * noise.eval(lol::vec_t<float, 1>(m * advance));
            return ret * 0.4f;
        }
        case INST_PHASER:
        {   // This one has a subfrequency of freq/128 that appears
            // to modulate two signals using a triangle wave
            // FIXME: amplitude seems to be affected, too
            float k = lol::abs(2.f * lol::fmod(advance / 128.f, 1.f) - 1.f);
            float u = lol::fmod(t + 0.5f * k, 1.0f);
            ret = lol::abs(4.f * u - 2.f) - lol::abs(8.f * t - 4.f);
            return ret / 6.f;
        }
    }

    return 0.0f;
}

} // namespace z8

