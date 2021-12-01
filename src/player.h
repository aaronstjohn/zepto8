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

#include <lol/engine.h> // lol::input
#include <map>    // std::map
#include <vector> // std::vector
#include <memory> // std::shared_ptr

#include "zepto8.h"
#include "pico8/cart.h"
#include <bitset>
#include <vector>
#include <tuple>

// The player class
// ————————————————
// This is a high-level Lol Engine entity that runs the ZEPTO-8 VM.

namespace z8
{

class input_buffer
{
public:
    input_buffer(std::string const& save_path);
    virtual ~input_buffer();
    void save(std::string const&path);
    void load(std::string const&path);
    
    bool button(int button,bool input_btn=false);
    void start_frame();
    void end_frame();
    bool is_playback_complete();
    
    int m_frame;
    std::string m_save_path;
    
    bool m_playback_mode;
    std::bitset<16> m_buttons;
    std::vector<std::bitset<16>> m_record_buffer;   
    std::vector<std::bitset<16>> m_playback_buffer;
};
class player : public lol::WorldEntity
{
public:
    player(bool is_embedded = false, bool is_raccoon = false,std::string const& input_save_pth="input.dat");
    virtual ~player();

    virtual void tick_game(float seconds) override;
    virtual void tick_draw(float seconds, lol::Scene &scene) override;
    void load_input(std::string const & path);
    
    void load(std::string const &name);
    void run();
    // void save_recording(std::string const &path);
    void load_input_recording(std::string const& path);
    std::shared_ptr<vm_base> get_vm() { return m_vm; }

    // HACK: if get_texture() is called, rendering is disabled (this
    // is so that we do not overwrite the IDE screen)
    lol::Texture *get_texture();
    lol::Texture *get_font_texture();

    

private:
    std::shared_ptr<vm_base> m_vm;

    std::map<lol::input::key, int> m_input_map;
    std::vector<lol::u8vec4> m_screen;

    // Video
    bool m_embedded = false;
    lol::ivec2 m_win_size;
    lol::ivec2 m_screen_pos;
    float m_scale;

    // Audio
    int m_streams[4];

     // Recording
    input_buffer m_input_record;
   
    // input_buffer& m_record_buf;
    // bool m_playback = false;
    // std::bitset<16> m_keystate;
    // std::vector<unsigned short> m_input_record;
    // std::string m_recording_path;


    lol::Camera *m_scenecam;
    lol::TileSet *m_tile;
#if 0
    lol::TileSet *m_font_tile;
#endif
};

} // namespace z8

