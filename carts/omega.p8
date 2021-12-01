pico-8 cartridge // http://www.pico-8.com
version 33
__lua__
-- omega enforcer x
-- by fartenko
-- version: 1.1


-- todo:
--[done!] couple more types of enemies
--[done!] powerups
--[done!] enemy shooting
--[done!] asteroids
--[done!] increasing difficulty
--[done!] boss
--[done!] leaderboard
--[don1!] credits
srand(6969)
debug=false

names={
		"zep",
		"lex",
		"tra",
		"imp",
		"lew",
		"pix",
		"jos",
		"kat",
		"jam",
		"___",
		"plr",
}
			
-- game state
-- -> "play"
-- -> "game_over"
-- -> "fadeout"   (transition)
-- -> "menu"
next_state="play"			-- sets after transition
game_state="fadeout"-- transition at start

score=0

boss_at_w=5
spawned_boss=false

t=0
power_box_t=0

-- menu stuff
enter_menu=true
first_start=false

menu_sect=0 -- 0-main 
												-- 1-leaderboards
												-- 2-credits
menu_item=0 -- 0-play
												-- 1-leaderboards
												-- 2-credits
menu_t1=0
show_lb=false
show_credits=false
cam_menu_y=0
lb_y_pos=-100

cartdata("omega_res_x_1")
highscore=dget(0)

leaderboard={}

function _init()
	score=0
	waves=0
	diff=1 -- 5 levels of difficulty?
	-- muzzle flash vars
	do_muzzle=false
	muzzle_t=0
	-- hit timer vars
	hit_timer=60
	hit_blink=false
	-- ship dead state
	ship_dead=false
	-- stops time for t frames
	stop_time=false
	stop_time_t=0
	-- camera shake vars
	shake_cur_dur=0
	make_shake=false
	shake_max=0
	shake_dur=0
	-- camera position
	cam_x=0
	cam_y=0
	-- shake position
	sh_x=0
	sh_y=0
	-- waiting helper
	t_helper=0
	-- count of enemy type 4
	type4_cnt=0
	
	-- ship object
	ship = {
		-- target sprite
		sp=2,
		-- current sprite
		cur_sp=2,
		sp_change=false,
		-- wait till spr change
		sp_change_d=6,
		sp_change_t=0,
		-- weapon fire rate
		fire_rate_d=20,
		fire_rate_t=0,
		-- weapon damage
		b_dmg=1,
		-- ship pos
		x=60,
		y=100,
		-- maximum speed
		spd=1.5,
		-- current speed by axis
		spdx=0,
		spdy=0,
		-- acceleration and deceleration
		acl=0.1,
		dcl=0.05,
		-- ship health points
		hp=3,
		-- was ship hit
		h=false,
		-- powerups
		-- firerate boost
		fr_b=false,
		fr_t=2000,
		-- shield boost
		sh_b=false,
		sh_t=2000,
		-- double score
		db_b=false,
		db_t=2000,
		-- collision box
		col={x1=0,y1=0,x2=7,y2=7}
	}
	-- other objects
	ship_trail={}				 -- ship trail
	ship_smoke={}				 -- ship smoke
	explosions={}				 -- explosions
	main_expl={}					 -- super explosions
	sub_expl={}						 -- smoke for explosions
	stars={}									 -- stars particle
	bullets={}							 -- ship bullets
	bullet_trails={}		-- bullet particles
	e_bullets={}						-- enemy bullets
	e_b_bullets={}				-- enemy bouncy bullets
	enemies={}	       -- enemies 
	asteroids={}						-- asteroids
	ast_particles={}  -- asteroid particles
	points_text={}    -- foaty text
	enemy_particles={}-- enemy particles
	powerups={}       -- powerups
	powerup_partcl={} -- powerup particles
	credits_partcl={}
	--rockets={}						-- secondary weapon
	-- message box
	msg={
		y=48,
		h=32,
		show=false,
		do_show=false,
		t=0,
		d=60,
	}	
	-- star particles at start
	init_start_particles()	-- spawning stars
	init_fadeout()         -- setting up fadeout effect
	load_leaderboard()
	
	--dset(32,0)	-- uncomment to reset
	if dget(32)==0 then
		init_pop_leaderboard()
		save_leaderboard()
		dset(32,1)
	end
	
	if not first_start then
		done_fi=true
		switch_state("play")		-- fading to menu state
		start_game();
	end
	spawn_enemies()								-- spawning enemies
	--drop_powerup(64,-20)
	
	--spawn_asteroid(64)
	first_start=true
end

-- is called only at first
-- start of the cart in pico-8
function init_pop_leaderboard()
	--⬅️⬅️⬅️
	highscore=0
	
	leaderboard[1].n=1
	leaderboard[1].s=2500
	
	leaderboard[2].n=2
	leaderboard[2].s=2125
 
 leaderboard[3].n=3
	leaderboard[3].s=1750
 
 leaderboard[4].n=4
	leaderboard[4].s=1500
 
 leaderboard[5].n=5
	leaderboard[5].s=1250
 
 leaderboard[6].n=6
	leaderboard[6].s=1000
 
 leaderboard[7].n=7
	leaderboard[7].s=750
 
 leaderboard[8].n=8
	leaderboard[8].s=500
	
	leaderboard[9].n=9
	leaderboard[9].s=200		
 
 leaderboard[10].n=10
	leaderboard[10].s=0		
end

function load_leaderboard()
	for i=0,9 do
		leaderboard[i+1]={
			n=dget(1+i*2),
			s=dget(2+i*2),
		}
	end
end

function save_leaderboard()
	dset(0,highscore) -- save highscore
	for i=0,9 do
		dset(1+i*2,leaderboard[i+1].n)
		dset(2+i*2,leaderboard[i+1].s)
	end
end

function apply_score()
	if score>highscore then
		highscore=score end
	for i=1,10 do
	 if leaderboard[i].s<score then
	 	for j=10,i+1,-1 do
	 		leaderboard[j].s=leaderboard[j-1].s
	 		leaderboard[j].n=leaderboard[j-1].n
	 	end
	 	leaderboard[i].s=score
	 	leaderboard[i].n=11-- player index
	 	break
	 end
	end
	save_leaderboard()
	load_leaderboard()
end

function credit_particles()
		local p={
			x=-2,
			m_y=rnd(87),
			y=0,
			dx=1+rnd(2),
			dy=4+rnd(4),
			per=60+rnd(60),
			t=rnd(60),
		}
		add(credits_partcl,p)
end

-- fadeout initialization
function init_fadeout()
	t_fo=0
	done_fo=false
	iter=0
end
-- fadein  initialization
function init_fadein()
	t_fi=60
	do_fi=true
	done_fi=false -- if true, allows update to work
end

-- spawns enemies
function spawn_enemies(cnt)
	local _hp=0
	
	if waves >=3 then 
		diff=2 end
	if waves >=6 then
		diff=3 end
	if waves >=12 then
		diff=4 
		end
	if waves >=18 then
		diff=5 
		_hp=1
	 end
	
	
	local _k=4+2*(diff-1)
	local k=flr(rnd(3))+_k
	if k>12 then k=12 end
	
	if cnt==nil then 
	 if waves%boss_at_w==0 and waves>boss_at_w then
			spawned_boss=true 
			k-=2	end	
		waves+=1
	else k=cnt end
	
	type4_cnt=0
	local _max_typ4=0
	if diff>1 then _max_typ4=1 end
	if diff>2 then _max_typ4=2 end
	if diff>4 then _max_typ4=3 end
	
	for i=1,k do
		local d=rnd(1)
		if d>0.5 then d=-1 else d=1 end
		
		::_nope_::
		local enemy_type=1+flr(rnd(4))
		if enemy_type==4 and type4_cnt==_max_typ4 then
			goto _nope_
		end
		
		if spawned_boss then
			--local y=-32+flr(i/7)*12
			local e={
				sp=41,
				h_sp=43,
				m_x=56,
				m_y=-32,
				t_y=32,
				x=-32,
				l_x=0,
				y=-32,
				r=0,
				d=0,
				dx=0.1,
				dy=0.15,
				hp=30,
				hit=false,
				ofs=0,
				scr=250,
				--ch_to_shoot=0,--0.002,
				shot_t=120,
				typ=10,
				col={x1=0,y1=0,x2=15,y2=15},
			}
			spawned_boss=false
			add(enemies,e)
		else
			if enemy_type==1 then
				local y=-32+flr(i/7)*12
				local e={
					sp=34,
					h_sp=36,
					m_x=16*(i%7)+12,
					m_y=y,
					t_y=y+48,
					x=-32,
					l_x=0,
					y=-32,
					r=10,
					d=d,
					dx=0.15,
					dy=0.1+rnd(0.2),
					hp=2+_hp,
					hit=false,
					ofs=i*5,
					scr=10+_hp*5,
					ch_to_shoot=0.001+rnd(0.002),
					shot_t=7+rnd(6),
					typ=enemy_type,
					col={x1=0,y1=0,x2=7,y2=7},
				}
				add(enemies,e)
			elseif enemy_type==2 then
				local e={
					sp=38,
					h_sp=40,
					m_x=16*(i%7)+12,
					m_y=-32+flr(i/7)*12,
					t_y=130,
					x=-32,
					l_x=0,
					y=-32,
					r=10,
					d=d,
					dx=0.15,
					dy=0.3+rnd(0.2),
					hp=1+_hp,
					hit=false,
					ofs=i*5,
					scr=5+_hp*5,
					--ch_to_shoot=0,
					--shot_t=0,
					typ=enemy_type,
					col={x1=0,y1=0,x2=7,y2=7},
					p_box={x1=2,y1=2,x2=5,y2=5}
				}
				add(enemies,e)
			elseif enemy_type==3 then
				local y=-32+flr(i/7)*12
				local e={
					sp=50,
					h_sp=52,
					m_x=16*(i%7)+12,
					m_y=y,
					t_y=y+48,
					x=-32,
					l_x=0,
					y=-32,
					r=15,
					d=d,
					dx=0.15,
					dy=0.1+rnd(0.2),
					hp=3+_hp,
					hit=false,
					ofs=i*5,
					scr=15+_hp*5,
					ch_to_shoot=0.001+rnd(0.001),
					shot_t=5+rnd(7),
					typ=enemy_type,
					col={x1=0,y1=0,x2=7,y2=7},
				}
				add(enemies,e)
			elseif enemy_type==4 then
				type4_cnt+=1
				local y=-32+flr(i/7)*12
				local e={
					sp=54,
					h_sp=56,
					m_x=16*(i%7)+12,
					m_y=y,
					t_y=y+48,
					x=-32,
					l_x=0,
					y=-32,
					r=5,
					d=d,
					dx=0.15,
					dy=0.35+rnd(0.2),
					hp=3+_hp,
					hit=false,
					ofs=i*5,
					scr=15+_hp*5,
					ch_t=rnd(45),
					ch=false,
					go=false,
					--∧∧∧
					--ch_to_shoot=0,
					--shot_t=0,
					typ=enemy_type,
					col={x1=0,y1=0,x2=7,y2=7},
				}
				add(enemies,e)
			end
		end
	end
end

-- spawning asteroid
function spawn_asteroid(x)
	if game_state!="game_over" then
	sfx(7) end
	local d=rnd(1)
	if d>0.5 then d=1 else d=-1 end
	local a={
		t=0,
		x=x,
		y=-96-rnd(32),
		dx=d*(0.025+rnd(0.025)),
		dy=1.5+rnd(1.75),
		sp=10,
		--hp=1+flr(rnd(2)),
		w=true,	-- flip flop for warning
		w_sp=32,
		col={x1=0,y1=0,x2=7,y2=7},
	}
	add(asteroids,a)
end

-- asteroid particles
function asteroid_particles(x,y)
	local d=30+rnd(25)
	local p={
		x=x,
		y=y,
		t=d,
		d=d,
	}
	add(ast_particles,p)
end

-- adds enemy bullet
function enemy_fire(x,y)
	local b={
		sp=5,
		x=x,
		y=y,
		dx=0,
		dy=1+rnd(1),
		col={x1=3,y1=0,x2=5,y2=4}
	}
	add(e_bullets,b)
end

function enemy_bouncy_fire(x,y)
	local _dy=0.5+rnd(0.75)
	for i=-1,1,1 do
		local b={
			sp=14,
			x=x,
			y=y,
			dx=_dy*i,
			dy=_dy-abs(i)*0.125,
			col={x1=2,y1=2,x2=5,y2=5},
		}
		add(e_b_bullets,b)
	end
end

-- enemy particles
function enemy_prtcl(x,y,d)
	if d==nil then d=10 end
	local p={
		x=x+rnd(2)-1,
		y=y,
		r=4,
		dy=-1,
		d=d,
		t=0,
	}
	add(enemy_particles,p)
end

-- powerups
function drop_powerup(x,y)
	--sfx(0)
	local typ=1+flr(rnd(4))
	local sp=72
	if typ==2 then sp=88 end
	if typ==3 then sp=104 end
	if typ==4 then sp=120 end 
	local p={
		x=x,
		y=y,
		typ=typ,
		dy=0.5+rnd(0.5),
		sp=sp,
		t=0,
		col={x1=0,y1=0,x2=7,y2=7}
	}
	add(powerups,p)
end


function play_start()
	ship_dead=true
end

-- player fire
function fire()
	local b = {
		sp=4,
		x=ship.x,
		y=ship.y,
		dx=0,
		dy=-8,
		col={x1=3,y1=0,x2=5,y2=7}
	}
	--ship.spdy+=0.35
	--shake(1.5,5)
	add(bullets,b)
end

--function secondary_fire()
--	--➡️➡️➡️
--	r={
--		x=8,
--		y=100,
--		dx=0,
--		dy=0,
--		sp=19,
--		t=0,
--	}
--	add(rockets,r)
--end

-- bullet particles
function bullet_trail(x,y,b_col,dy,c)
	local t={
		x=x+flr(b_col.x1+rnd(b_col.x2-b_col.x1)),
		y=y+flr(b_col.y1+rnd(b_col.y2))+1,
		dy=dy/(rnd(6)+4),
		c=c,
		t=0,
		d=10+rnd(20),
	}
	add(bullet_trails,t)
end

-- floaty text for points
function points(x,y,p)
	local p={
		x=x,
		y=y,
		str="+"..p,
		dy=0.5,
		d=60,
		t=0,	
	}
	add(points_text,p)
end

-- background stars particles
function star(x,y,dy)
	local s={
		x=x,
		y=y,
		dy=dy,
		col=4+dy
	}
	if flr(s.col)==5 then s.col=1 end 
	add(stars,s)
end

-- ship trail
function trail() 
	local s={
		x=ship.x+4+rnd(2)-1,
		y=ship.y+7,
		r=rnd(1.66)+1,
		dy=rnd(2)+0.2,
		dx=rnd(0.1)-0.05,
		dr=rnd(0.1)+0.05,
		t=20,
		dur=20,
		col=flr(rnd(2))+9,
	}
	add(ship_trail,s)
end

-- ship smoke
function smoke() 
	local s={
		x=ship.x+4+rnd(2)-1,
		y=ship.y+7,
		r=rnd(1.5)+2,
		dy=rnd(0.5)+1.7,
		dx=rnd(0.5)-0.25,
		dr=0.05,
		t=60,
		dur=60,
		col=flr(rnd(2))+4,
	}
	add(ship_smoke,s)
end

-- explosion ring
function explode(x,y,r,dr,t)
	local e={
		x=x,
		y=y,
		r=r,
		t=t,
		st=t,
		dr=dr,
	}
	add(explosions,e)
end

--death explosion
function create_expl(x,y,dx,dy,c,par,t)
	mult=3
	local e={
		x=x,
		y=y,
		dx=dx*mult,
		dy=dy*mult,
		grav=0.05,
		c=c,
		st=t,
		t=t+rnd(t),
	}
	add(par,e)
end
-- calls death explosion
function super_explode(x,y,k)
	for i=1,k,1 do
	create_expl(x,y,rnd(2)-1,rnd(2)-1,10,main_expl,15)
	end
end

-- fill screen with particles
function init_start_particles()
	for i=1,flr(rnd(5))+50 do
		star(flr(rnd(128)),flr(rnd(128)),rnd(3)+1)
	end
end

-- gets collision of object
function get_col(s)
	local col={}
	col.x1=s.col.x1+s.x
	col.y1=s.col.y1+s.y
	col.x2=s.col.x2+s.x
	col.y2=s.col.y2+s.y
	return col
end

-- checks collision between a and b
function coll(a,b)
	local col_a=get_col(a)
	local col_b=get_col(b)
	
	if col_a.x1>col_b.x2 or
				col_a.y1>col_b.y2 or
				col_a.x2<col_b.x1 or
				col_a.y2<col_b.y1 then
		return false
	end
	return true
end

-- updating stars particles
function upd_stars_particles()
	for i=1,flr(rnd(2))+1 do
		star(flr(rnd(128)),0,rnd(3)+1)
	end
	
	for s in all(stars) do
		s.y += s.dy
		if s.y > 128 then
			del(stars,s)
		end
	end
end

-- updating ship particles
function upd_ship_particles()
	-- player trail
 if ship_dead==false then trail() end
 for s in all(ship_trail) do
		s.y += s.dy --+ ship.spdy/3
		s.x += s.dx --+ ship.spdx/4
		s.r -= s.dr
		s.t -= 1
		if s.t <= 0 or s.r <= 0 then
			del(ship_trail,s)
		end
	end
	
	-- player smoke
	if ship_dead==false then
	 for i=1,2-ship.hp do
	 	smoke()
	 end
 end
 --smoke()
 for s in all(ship_smoke) do
		s.y += s.dy - s.dy*(1-s.t/s.dur)
		s.x += s.dx
		s.r -= s.dr
		s.t -= 1
		if s.t <= 0 or s.r <= 0 then
			del(ship_smoke,s)
		end
	end
	
	for t in all(bullet_trails) do
		t.y+=t.dy*(1-t.t/t.d)
		t.t+=1
		if t.t>=t.d then
			del(bullet_trails,t)
		end
	end
end

-- updating floaty text
function upd_points_text()
	for p in all(points_text) do
		p.t+=1
		p.y-=p.dy
		if p.t >= p.d then
			del(points_text,p)
		end
	end
end

-- updating shooting behaivour
function upd_ship_shooting()
	-- recoil controll
	if muzzle_t <=0 then
	do_muzzle=false
	end
	muzzle_t-=1
	
 ship.fire_rate_t-=1

 -- move bullets
 for b in all(bullets) do
 	b.x += b.dx
 	b.y += b.dy
 	bullet_trail(b.x,b.y,b.col,b.dy,12)
		bullet_trail(b.x,b.y,b.col,b.dy,12)
		if ship.db_b then
		 --bullet_trail(b.x,b.y,b.col,b.dy,10)
		 bullet_trail(b.x,b.y,b.col,b.dy,10)
		end
		
 	if b.x < -3 or b.x > 130 or
 				b.y < -3 or b.y > 130 then
 		del(bullets,b)
 	end
 	for e in all(enemies) do
 		if coll(e,b) then
 			shake(4,15)
 			sfx(1)
 			if e.typ==10 then
 			explode(e.x+8,e.y+8,1,4,5)
	 		explode(e.x+8,e.y+8,1,2,10)
				explode(e.x+8,e.y+8,1,1,15)
				explode(e.x+8,e.y+8,1,1,20)
 			else
 			explode(e.x+4,e.y+4,1,4,5)
	 		explode(e.x+4,e.y+4,1,2,10)
				explode(e.x+4,e.y+3,1,1,15)
				explode(e.x+4,e.y+4,1,1,20)
 			end
 			e.hp-=1
 			e.hit=true
 			if(e.hp==0)then
 				if rnd(100)>75 then drop_powerup(e.x,e.y) end
 				sfx(3)
 				del(enemies,e)
 				local m_score=e.scr -- repalce it!
 				if ship.db_b then m_score*=2 end
 				score+=m_score
 				if e.typ==10 then
 				drop_powerup(e.x+8,e.y+8)
 				points(e.x+8,e.y+8,m_score)
 				explode(e.x+8,e.y+8,1,1.5,40)
 				super_explode(e.x+8,e.y+8,8+flr(rnd(3)))
 				else
 				points(e.x+4,e.y+4,m_score)
 				explode(e.x+4,e.y+4,1,1.5,40)
 				super_explode(e.x+4,e.y+4,5+flr(rnd(3)))
 				end
 				shake(6,20)
 			end
 			--stop_time_t=2
				--stop_time=true
 			del(bullets,b)
 		end
 	end
 end
 
 if ship_dead==false then
	 -- shooting
	 if (btn(4) and ship.fire_rate_t <= 0) then 
	 	fire()
	 	sfx(0)
	 	do_muzzle=true
	 	muzzle_t=3
	 	local firerate = ship.fire_rate_d
	 	if ship.fr_b then firerate = firerate*0.66 end 
	 	ship.fire_rate_t = firerate
	 end
	 if btnp(5) and true then
	 	-- shoot the rocket
	 end
 end
end

-- updating movement
function upd_ship_movement()
	-- position clamping
	if ship.x<-2 then
		ship.x=-2
	elseif ship.x>122 then
		ship.x=122
	end
	
	if ship.y<7 then
		ship.y=7
	elseif ship.y>121 then
		ship.y=121
	end
	-- hor movement and sprite target change
 if (btn(0) and not btn(1)) then
 	ship.sp=1
 	ship.spdx-=ship.acl
 	if ship.spdx < -ship.spd then ship.spdx = -ship.spd end
 	 elseif (btn(1) and not btn(0)) then 
  ship.sp=3
  ship.spdx+=ship.acl
  if ship.spdx > ship.spd then ship.spdx = ship.spd end
 else
 	ship.sp=2
 	if ship.spdx < -0.1 then
 		ship.spdx += ship.dcl
 	elseif ship.spdx > 0.1 then
 		ship.spdx -= ship.dcl
 	else
 		ship.spdx = 0
 		ship.x = flr(ship.x)
 	end
 end
 ship.x += ship.spdx
 -- vert movement
 if (btn(2) and not btn(3)) then
 	ship.spdy -= ship.acl
 	if ship.spdy < -ship.spd then ship.spdy = -ship.spd end
 elseif (btn(3) and not btn(2)) then
 	ship.spdy += ship.acl
 	if ship.spdy > ship.spd then ship.spdy = ship.spd end
 else
 	if ship.spdy < -0.1 then
 		ship.spdy += ship.dcl
 	elseif ship.spdy > 0.1 then
 		ship.spdy -= ship.dcl
 	else
 		ship.spdy = 0
 		ship.y = flr(ship.y)
 	end
 end
 ship.y += ship.spdy
 
 -- check if sprite needs change
 if ((ship.cur_sp != ship.sp) and ship.sp_change==false) then
 	ship.sp_change=true
 end
 
 -- sprite change behaviour
 if ship.sp_change==true then
 	ship.sp_change_t += 1
 	if (ship.sp_change_t > ship.sp_change_d) then
 		if(ship.sp < 2) then
 			ship.cur_sp -= 1 
 		elseif(ship.sp > 2)then
 			ship.cur_sp += 1
 		else
 			ship.cur_sp = 2
 		end
 		ship.sp_change=false
 		ship.sp_change_t=0
 	end
 end
 -- check if frame is right
 if ship.cur_sp < 1 then
  ship.cur_sp = 1
 elseif ship.cur_sp > 3 then
 	ship.cur_sp = 3
 end
end

-- updating ship health state
function upd_ship_dmg()
	-- player damage
 hit_timer-=1
 
 if ship.hp>3 then ship.hp=3 end
 
 if hit_timer%4==0 then
 	hit_blink=not(hit_blink)
 end
 
 if ship.sh_b then return end
 
 if ship_dead==false then
	 if ship.h==true and hit_timer<=0 then
	 	ship.hp-=1
	 	ship.h=false
	 	sfx(11)
	 	if ship.hp <= 0 then 
	 		ship_dead=true 
	 		ship.sh_b=false
	 		ship.fr_b=false
	 		ship.db_b=false
	 		sfx(2)
	 		explode(ship.x+4,ship.y+4,1,4,15)
	 		explode(ship.x+4,ship.y+4,1,2,30)
	 		explode(ship.x+4,ship.y+4,1,1,45)
				explode(ship.x+3,ship.y+4,1,1,45)
				explode(ship.x+4,ship.y+3,1,1,45)
				explode(ship.x+4,ship.y+4,1,1,60)
	 		super_explode(ship.x+4,ship.y+4,7+flr(rnd(3)))
	 		stop_time=true
	 		stop_time_t=10
	 		shake(30,30)
	 		t_helper=0
	 		game_state="game_over"
			end_game(json.stringify({score=score}));
	 		music(22,1000)
	 		ship.x=60
	 		ship.y=140
	 	else
		 	hit_timer=90
		 	explode(ship.x+4,ship.y+4,1,4,15)
		 	stop_time=true
		 	stop_time_t=5
		 	shake(20,15)
	 	end
	 end
 end
end

-- explosion ring particles
function upd_explosio_particles()
	for e in all(explosions) do
		e.r+=e.dr
		e.t-=1
		if e.t<=0 then del(explosions,e) end
	end
end

-- death explosion particles
function upd_super_explosions()
	for e in all(main_expl) do
		e.x+=e.dx
		e.y+=e.dy
		e.dy+=e.grav
		e.t-=1
		create_expl(e.x,e.y,0,0,4,sub_expl,10)
		if e.t <= 0 then del(main_expl,e) end
	end
	
	for e in all(sub_expl) do
		e.t-=1
		if e.t <= 0 then del(sub_expl,e) end
	end
end

-- screenshake
function shake(shmax,shdur)
	make_shake=true
	shake_cur_dur=0
	shake_max=shmax
	shake_dur=shdur
end

-- updating screenshake
function upd_shake()
	if make_shake==true then
		if shake_cur_dur < shake_dur then
			sh_x=rnd(shake_max)-shake_max/2
			sh_y=rnd(shake_max)-shake_max/2
			shake_left=1-shake_cur_dur/shake_dur
			sh_x*=shake_left
			sh_y*=shake_left
			camera(cam_x+sh_x,cam_y+sh_y)
			shake_cur_dur+=1
		else
			camera(cam_x,cam_y)
			make_shake=false
		end
	end
end

-- powerup particles
function powerup_pickup_eff(typ)
	local col=8
	if typ==2 then col=12 end
	if typ==3 then col=11 end
	if typ==4 then col=10 end
	for i=1,8 do
		local dx=cos(((360/8)/360)*i)
		local dy=sin(((360/8)/360)*i)
		local p={
			x=ship.x+4,
			y=ship.y+4,
			dx=dx,
			dy=dy,
			c=col,
			t=15,
		}
		-- ✽✽✽
		add(powerup_partcl,p)
	end 
end

-- updating powerups
function upd_powerups()
	for p in all(powerups) do
		p.y+=p.dy
		
		if p.t==6  then p.sp+=1 end
		if p.t==12 then p.sp+=1 end
		if p.t==18 then p.sp+=1 end
		if p.t==24 then 
			p.sp-=3
			p.t=0
		end
		
		p.t+=1
		
		local p_name="health"
		if coll(ship,p) then
			if p.typ==1 then ship.hp+=1 end -- hp
			if p.typ==2 then -- fr 
				ship.fr_b=true
				ship.fr_t=600
				p_name="firerate boost"
			end 
			if p.typ==3 then -- sh 
				ship.sh_b=true
				ship.sh_t=600
				p_name="shield"
			end 
			if p.typ==4 then -- db
				ship.db_b=true
				ship.db_t=600
				p_name="double points"
			end
			sfx(5)
			powerup_pickup_eff(p.typ)
			points(ship.x+4,ship.y,p_name)
			del(powerups,p)
		end
		
		if p.y > 130 then
			del(powerups,p)
		end
	end
	-- powerup particles
	for p in all(powerup_partcl) do
		p.x+=p.dx
		p.y+=p.dy
		p.t-=1
		if p.t<=0 then del(powerup_partcl,p) end
	end
	-- apply powerups to ship vars
	if ship.fr_b then 
		ship.fr_t-=1
		if ship.fr_t<=0 then ship.fr_b=false end
	end
	if ship.sh_b then 
		ship.sh_t-=1
		if ship.sh_t<=0 then ship.sh_b=false end
	end
	if ship.db_b then 
		ship.db_t-=1
		if ship.db_t<=0 then ship.db_b=false end
	end	 
	
end

-- updating enemies
function upd_enemies()
	if #enemies==0 then spawn_enemies() end
	for e in all(enemies) do
		e.l_x=e.x
		e.x=e.r*e.d*sin((t+e.ofs)/180)+e.m_x
		e.y=e.r*sin((t+e.ofs*5)/180)+e.m_y
		
		if e.typ == 2 then
			bullet_trail(e.x,e.m_y-2,e.p_box,0,2)
			e.y=e.m_y	
		end
			
		if e.typ == 3 then
			e.y=e.r/2*sin((t+e.ofs*5)/90)+e.m_y
		end
			
		if e.typ!=2 and e.typ!=4 then
			e.m_x+=e.dx
			if e.m_x>108 or e.m_x<14 then
			if e.m_x<14 then e.m_x=15 end
			e.dx*=-1
			end
		end
		
		if e.m_y < e.t_y then
			e.m_y+=e.dy
		end
		
		if e.typ==4 then
			if not e.go then
				e.y=e.m_y
				if not e.ch then
					if e.m_y+1>=e.t_y then
						if e.ch_t<=0 then
							e.ch=true
							e.ch_t=60
						else
							e.ch_t-=1
						end
					end
				else
					e.y=e.m_y+rnd(2)-1
					if game_state!="game_over" then
					sfx(10) end
					enemy_prtcl(e.x+2+rnd(4),e.y+1)
					e.ch_t-=1
					if e.ch_t<=0 then
						-- calculate dx
						local diff_y=ship.y-e.m_y
						local diff_x=ship.x-e.m_x
						e.dx=diff_x/35
						e.dy=diff_y/35
						e.r=0
						e.go=true
						e.ch=false
						if game_state!="game_over" then
						sfx(9) end
					end
				end
			else
				enemy_prtcl(e.x+2,e.y+1,25)
				e.m_y+=e.dy
				e.m_x+=e.dx
			end
		end
		-- boss
		if e.typ==10 then
			-- do boss_stuff here
			-- if e.hp==15 and e.hit then drop_powerup(e.x+7,e.y+7) end
			enemy_prtcl(e.x+4 ,e.y+1)
			enemy_prtcl(e.x+12,e.y+1)
			if e.m_y+1>=e.t_y then
				e.shot_t-=1
				if e.shot_t<=0 then
					e.shot_t=100
					if game_state!="game_over" then
					sfx(4) end
					enemy_bouncy_fire(e.x+1,e.y+13)
					enemy_bouncy_fire(e.x+12,e.y+12)
					enemy_fire(e.x+7,e.y+15)
					if #enemies==1 then
						spawn_enemies(4)
					end
				end
				if e.m_x<=32 then
					e.m_x=33
					e.dx*=-1
				elseif e.m_x>=80 then
					e.m_x=79
					e.dx*=-1
				end
			else
				e.m_x-=e.dx
			end
		end
		--enemy_prtcl(e.x+4,e.y+1)
		--░░░
		if e.typ==1 or e.typ==3 then 
			enemy_prtcl(e.x+4,e.y+1)
			if rnd(1)<e.ch_to_shoot then
				if #e_bullets < 5 and e.typ==1 then
					enemy_fire(e.x+4,e.y+4)
					if game_state!="game_over" then
					sfx(4) end
				end
				if e.typ==3 then
					enemy_bouncy_fire(e.x+4,e.y+4)
					if game_state!="game_over" then
					sfx(4) end
				end
			end
		end
		
		if coll(ship,e) and hit_timer<=0 and not(ship.sh_b)then
			if e.typ!=10 then
			del(enemies,e)
			end
			ship.h=true
		end
		if e.y>130 then
			del(enemies,e)
		end
	end
	for p in all(enemy_particles) do
		p.y+=p.dy/10
		p.t+=1
		if p.t >= p.d then del(enemy_particles,p) end
	end
	for b in all(e_bullets) do
		b.y+=b.dy
		bullet_trail(b.x,b.y,b.col,b.dy,8)
		bullet_trail(b.x,b.y,b.col,b.dy,8)
		if coll (ship,b) and hit_timer<=0 then
			--todo collisions
			del(e_bullets,b)
			if ship.sh_b==false then
				ship.h=true
			end
		end
		if b.y >130 then
			del(e_bullets,b)
		end
	end
	for b in all(e_b_bullets) do
		b.y+=b.dy
		b.x+=b.dx
		if coll(ship,b) and hit_timer<=0 then
			del(e_b_bullets,b)
			if ship.sh_b==false then
				ship.h=true
			end
		end
		if b.y >130 then
			del(e_bullets,b)
		end
		if b.x<=0 or b.x>=125 then
			b.dx*=-1
		end
	end
end

-- fadeout update (transition)
function upd_fadeout()
	if done_fo then
		game_state=next_state
		done_fo=false
		init_fadein()
	end 

	t_fo+=1
end

-- fadein update
function upd_fadein()
	if do_fi then
		if t_fi <= 0 then 
			do_fi=false
			done_fi=true
		end
		t_fi-=1
	end
end

--♪♪♪ updating asteroids
function upd_asteroids()
	local _t=60*(diff-1)
	if t%(270-_t)==0 and waves>9 then
		local ch=rnd(100)
		if ch>75 then
			-- spawn asteroid
			local x=ship.x+rnd(48)-24
			if x>104 then x=104 end
			if x<12  then x=12  end
			spawn_asteroid(x)
		end
	end
	
	for a in all(asteroids) do
		a.x+=a.dx
		a.y+=a.dy
		a.t+=1
		asteroid_particles(a.x,a.y)
		if a.y > 130 then
			del(asteroids,a)
		end
		if coll(a,ship)then
			del(asteroids,a)
			if ship.sh_b then
				sfx(3)
				ship.sh_b=false
				super_explode(a.x+4,a.y+4,4+flr(rnd(3)))
				shake(6,20)
			else
				ship.hp-=3
				ship.h=true
			end
		end
		
		for b in all(bullets) do
			if coll(a,b) then
				explode(b.x+4,ship.y,1,1,15)
	 		explode(b.x+4,ship.y,1,1,30)
				del(bullets,b)
			end
		end
	end
	
	for p in all(ast_particles) do
		p.t-=1
		if p.t<=0 then del(ast_particles,p) end
	end
end

-- updating play state
function update_play()
	if stop_time==false then
		-- put update functions here
	 upd_enemies()
	 upd_stars_particles()
	 upd_ship_particles()
	 if ship_dead==false then
	 	upd_ship_movement()
	 end
	 upd_ship_shooting()
	 upd_ship_dmg()
	 upd_explosio_particles()
	 upd_super_explosions()
	 upd_shake()
	 upd_points_text()
	 upd_powerups()
	 upd_asteroids()
 else
 	stop_time_t-=1
 	hit_blink=true
 	ship.cur_sp=18
 	if stop_time_t<=0 then 
 		stop_time=false
 	end
 end
end

-- updating menu state
function update_menu()
	upd_shake()
	menu_t1+=1
	credit_particles()
	for p in all(credits_partcl) do
		p.x+=p.dx
		p.y=p.m_y+p.dy*sin((t-p.t)/p.per)
		if p.x >127 then del(credits_partcl,p) end
	end
	
	if show_credits then
		if cam_menu_y<127 then
		cam_menu_y+=max((1-cam_menu_y/127)*16,0.5)
		end
	else
		if cam_menu_y>1 then
		cam_menu_y-=max((cam_menu_y/127)*16,0.5)
		end	
	end
	
	if show_lb then
		if lb_y_pos<0 then
		lb_y_pos+=max((abs(lb_y_pos)/100)*16,0.5)
		end
	else
		if lb_y_pos>-100 then
		lb_y_pos-=max((1-abs(lb_y_pos)/100)*16,0.5)
		end
	end
	
	if enter_menu then
		t_helper+=1
		if t_helper > 8 then
			t_helper=0
			sfx(8)
			shake(15,20)
			enter_menu=false
		end
	end
	if menu_sect==2 then
		if btnp(5) then
			show_credits=false
			menu_sect=0
			sfx(6)
		end
	elseif menu_sect==1 and btnp(5) then
		menu_sect=0
		show_lb=false
		sfx(6)
	else
		if menu_sect==0 then
			if not enter_menu then
				if btnp(2) then menu_item-=1 sfx(6) end
				if btnp(3) then menu_item+=1 sfx(6) end
				if menu_item<0 then menu_item=2 end
				if menu_item>2 then menu_item=0 end
			end
		end
		if menu_item==0 and btnp(5) then
			--▒▒▒
			_init()
			sfx(6)
			switch_state("play")
		elseif menu_item==1 and btnp(5) then
			-- show leaderboards
			show_lb=true
			menu_sect=1
			sfx(6)
		elseif menu_item==2 and btnp(5) then
			menu_sect=2
			show_credits=true
			sfx(6)
		end
	end
end

-- updating message box
function upd_msg_box()
	if msg.do_show==true then
		msg.show=true
		msg.t+=4
		if msg.t>msg.d then
			msg.t=msg.d
		end
	else
		msg.t-=4
		if msg.t<=0 then
			msg.t=0
			msg.show=false
		end
	end
end

-- updating gameover state
function update_game_over()
	update_play()
	upd_msg_box()
	t_helper+=1
	if t_helper > 60 then
		msg.do_show=true
	end
	
	if t_helper > 70 then
		if btnp(5) then
			apply_score()
			_init() 
			sfx(6)
			switch_state("play")
			--game_state="play"
			t_helper=0 
		end
		-- if btnp(4) then 
		-- 	apply_score()
		-- 	sfx(6)
		-- 	switch_state("menu") 
		-- 	--game_state="menu"
		-- 	t_helper=0
		-- end
	end
end

-- switches game between states
function switch_state(state)
	init_fadeout()
	game_state="fadeout"
	next_state=state
	enter_menu=true
	if state=="menu" then
		music(0,1000)
	else
	 music(3,3000)
	end
end


-- updating the game
function _update60()
	-- if fadein is done
	if done_fi then
		t+=1
		
		if game_state=="play" then
			update_play()
		end
		if game_state=="game_over" then
			update_game_over()
		end
		if game_state=="menu" then
			update_menu()
		end
		if game_state=="fadeout" then
			upd_fadeout()
		end
	end
	-- updating fadein
	upd_fadein()
end

-- faddout draw
function draw_fadeout() 
	if iter < 16 then
		if t_fo > 2 then
			for x=0,127 do
				for y=0,127 do
					if pget(x,y)!=0 then 
						pset(x,y,pget(x,y)-1) 
					end
				end
			end
			iter+=1
			t_fo=0
		end
	else
		-- fadeout done
		done_fo=true
	end
end

-- drawing play state
function draw_play()

	cls()
	
	-- actual stuff
	-- draw stars
	for s in all(stars) do
		--line(s.x,s.y,s.x,s.y,s.col)
		pset(s.x,s.y,s.col)
	end
	-- draw powerups
	for p in all(powerups) do 
		--rectfill(p.x,p.y,p.x+7,p.y+7,8)
		spr(p.sp,p.x,p.y)
	end
	-- draw bullet trails
	for t in all(bullet_trails) do
		if t.t/t.d<0.9 then
			pset(t.x,t.y,t.c)
		else
			pset(t.x,t.y,2)
		end
	end
	-- draw enemy particles
	for p in all(enemy_particles) do
		local c
		if rnd(1)>0.5 then c=2 else c=8 end
		circfill(p.x-0.5,p.y,3*(1-p.t/p.d),c)
	end
	-- draw enemies
	for e in all(enemies) do
		if e.typ==10 then
			if e.hit==false then
			spr(e.sp,e.x,e.y,2,2)
			else
			spr(e.h_sp,e.x,e.y,2,2)
			e.hit=false
			end
		else
			if e.hit==false then
				if e.x-e.l_x>0.125 then 
					spr(e.sp+1,e.x,e.y)
				elseif e.x-e.l_x<-0.125 then
					spr(e.sp-1,e.x,e.y)
				else
					spr(e.sp,e.x,e.y)
				end
			else
			spr(e.h_sp,e.x,e.y)
			e.hit=false
			end
		end
		--pset(e.x+e.col.x1,e.y+e.col.y1,8)
		--pset(e.x+e.col.x2,e.y+e.col.y1,8)
		--pset(e.x+e.col.x1,e.y+e.col.y2,8)
		--pset(e.x+e.col.x2,e.y+e.col.y2,8)
	end
	-- draw boss
	
	-- draw enemy bullets
	for b in all(e_bullets) do
		spr(b.sp,b.x,b.y)
	end
	for b in all(e_b_bullets) do
		if t%4==0 then
			if b.sp==14 then b.sp=15 else
				b.sp=14 end
		end
		spr(b.sp,b.x,b.y)
	end
	-- draw powerup particles
	for p in all(powerup_partcl) do
		circfill(p.x,p.y,6*(p.t/15),p.c)
	end
	-- draw ship shield
	if ship.sh_b then
		for i=1,8 do
				local x=ship.x+4+cos((t+i*7.5)/60)*(6+sin(t/60)*2)
				local y=ship.y+4+sin((t+i*7.5)/60)*(6+sin(t/60)*2)
				circ(x,y,1,11)
		end
	end
	-- draw ship firerate
	if ship.fr_b then
		for i=0,1 do
				local x=ship.x+i*7--sin((t+i*7.5*2)/30)*(6+cos(t/60)*2)
				local y=ship.y+4+cos(t/30)*(6+cos(t/60)*2)
				circfill(x,y,1,12)
		end
	end
	-- draw ship double score
	if ship.db_b then
		-- ●●●
		bullet_trail(ship.x,ship.y,ship.col,-10,10)
	end
	-- draw ship_smoke
	for s in all(ship_smoke) do
		circfill(s.x,s.y,s.r,s.col)
	end
	-- draw ship_trail
	for s in all(ship_trail) do
		circfill(s.x,s.y,s.r,s.col)
	end
	-- death blink
	if ship_dead and stop_time_t>5 and stop_time  then
		rectfill(-16,-16,144,144,7)
	end
	-- draw ship
	if ship_dead == false then
		if hit_timer <= 0 then
			spr(ship.cur_sp,ship.x,ship.y)
		else
			if hit_blink==true then
				spr(ship.cur_sp,ship.x,ship.y)
			end
		end
	end
	-- draw ship bullets
	for b in all(bullets) do
		spr(b.sp,b.x,b.y)
	end
	-- draw ship rockets
	--for r in all(rockets) do
	--	local s=r.sp
	--	if r.t<10 then s=r.sp+2 end
	--	if r.t<5 then s=r.sp+1 end
	--	if r.t==15 then	r.t=0 end
	--	spr(s,r.x,r.y)
	--end
	-- draw asteroid particles
	for p in all(ast_particles) do
		local d=p.t/p.d
		local c=10
		if d>=0  then c=1  end
		if d>0.4 then c=2  end
		if d>0.7 then c=8  end
		if d>0.8 then c=9  end
		if d>0.95then c=10 end
		circfill(p.x+4,p.y+4,6*p.t/p.d,c)
	end
	-- 😐😐😐
	-- draw asteroids
	for a in all(asteroids) do 
		local s=a.sp
		-- warning
		if a.y < 4 then
			if a.t%8==0 then
				a.w=not(a.w)
			end
			local ws=a.w_sp -- warning sprite
			if a.w==false then ws+=16 end
			spr(ws,a.x,12)
		end
		-- actual asteroid
		if a.t >= 24 then a.t=0
		elseif a.t >= 16 then  
			s=a.sp+2
		elseif a.t >=8 then
			s=a.sp+1
		end
		spr(s,a.x,a.y)
	end
	
	-- draw death explosions
	--sub
	for e in all(sub_expl) do
		local c=e.c
		if e.t/e.st < 0.9 then e.c=5 end
		circfill(e.x,e.y,2*e.t/e.st,c)
	end
	--main
	for e in all(main_expl) do
		circfill(e.x,e.y,4*e.t/e.st,e.c)
	end
	
	-- draw explosions
	for e in all(explosions) do
		local col=7
		if e.t/e.st < 0.8 then col=10 end
		if e.t/e.st < 0.6 then col=9 end
		if e.t/e.st < 0.4 then col=2 end
		if e.t/e.st < 0.4 then col=1 end
		circ(e.x,e.y,e.r,col)
	end
	-- draw points text
	for p in all(points_text) do
		color(7)
		if p.t>30 then color(6) end
		if p.t>45 then color(13) end
		if p.t>50 then color(5) end
		if p.t>55 then color(1) end
		print(p.str,p.x+4*sin(p.t/45),p.y)
	end
	
	--- debug
	if debug==true then
		print("",0,0,7)
		print("")
		print("")
		print("spdx ="..ship.spdx)
		print("spdy ="..ship.spdy)
		local ss=stat(1)
		local ss_c=7
		if ss >0.7 then ss_c=10 end
		if ss >0.9 then ss_c=9 end
		if ss >= 1 then ss_c=8 end 
		print("cpu:" .. flr(ss*100) .. "%",1,123,ss_c)
		rect(ship.x,ship.y,ship.x+7,ship.y+7)
	end	
	
	-- draw ui
	--rectfill(1,-2,126,9,0)
	for i=1,3 do
		spr(17,3+6*(i-1),1)
	end
	for i=1,ship.hp do
		spr(16,3+6*(i-1),1)
	end
	local scr_x=44
	local scr_c=7
	if ship.db_b then scr_c=10 end
	if score<10 then
	print("score:000"..score,scr_x,2,scr_c)
	elseif score<100 then
	print("score:00"..score,scr_x,2,scr_c)
	elseif score<1000 then
	print("score:0"..score,scr_x,2,scr_c)
	else
	print("score:"..score,scr_x,2,scr_c)
	end
	print("hi:"..highscore,92,2,1)
	map(0,0,0,0)
	-- powerup ui
	local py=64
	if ship.fr_b then
	print("fr",2,py+1,1)
	print("fr",3,py,12)
	line(2,py+7,2+24*(ship.fr_t/600),py+7,12) 
	line(1,py+8,1+24*(ship.fr_t/600),py+8,1)end
	if ship.sh_b then 
	print("sh",2,py+11,3)
	print("sh",3,py+10,11)
	line(2,py+17,2+24*(ship.sh_t/600),py+17,11) 
	line(1,py+18,1+24*(ship.sh_t/600),py+18,3) end
	if ship.db_b then
	print("db",2,py+21,2)
	print("db",3,py+20,10)
	line(2,py+27,2+24*(ship.db_t/600),py+27,10) 
	line(1,py+28,1+24*(ship.db_t/600),py+28,2) end


	--print("w:"..waves,116,2,7)
	--print("d:".. diff,116,8,7)
end

-- drawing menu state
function draw_menu()
	cls()
	
	for p in all(credits_partcl) do
		pset(p.x,p.y+167,7)
	end
	
	for x=0,8,1 do
		for y=0,8,1 do
			local r=t/2%16
			rect(16*x-r,16*y-r,16*x+16-r,16*y+16-r,1)
		end
	end
	
	if show_credits then
	camera(0,cam_menu_y)
	else
		if not make_shake then
		camera(0,cam_menu_y)
		end
	end
	
	print("highscore:"..highscore,37+sin((t-10)/180)*32,119,2)
	print("highscore:"..highscore,37+sin(t/180)*32,118,7)
	
	map(15,0,-10,8-abs(cos(t/55)*8))
	if not enter_menu then
		spr(201,78,36-abs(cos((t-8)/55))*8,4,4)
	end
	
	local _m0=1
	local _m1=0
	local _m2=0
	if menu_item==0 then
	 _m0=1
	 _m1=0 
	 _m2=0 elseif menu_item==1 then
	 _m0=0
	 _m1=1 
	 _m2=0 else
	 _m0=0
	 _m1=0
	 _m2=1 end
	
	local sum=(_m1+_m2*2)*12
	
	rectfill(14,72+sum,74,75+sum,8)
	
	print(">>",16,71+sum,8)
	print(">>",16,70+sum,7)
	
	print("play",16+12*_m0,71,8)
	print("play",16+12*_m0,70,7)
	
	print("leaderboard",16+12*_m1,83,8)
	print("leaderboard",16+12*_m1,82,7)
	
	print("credits",16+12*_m2,95,8)
	print("credits",16+12*_m2,94,7)
	-- credits
	rectfill(0,127,127,167,0)
	rect(0,0,127,127,2) -- frame
	rect(0,127,127,167,2)
	
	print("made by vitaliy brydinskiy",4,132,8)
	print("made by vitaliy brydinskiy",4,131,7)
	print("twitter: @_fartenko",4,140,8)
	print("twitter: @_fartenko",4,139,7)

	print("music by chris donnelly",4,151,8)
	print("music by chris donnelly",4,150,7)
	print("twitter: @gruber_music",4,159,8)
	print("twitter: @gruber_music",4,158,7)
	-- credits end
	
	print("v1.1",109,6,8)
	print("v1.1",109,5,7)
	
	-- leaderboard
	--if show_lb then
		rectfill(30,12+lb_y_pos,94,96+lb_y_pos,0)
		rect(30,12+lb_y_pos,94,96+lb_y_pos,7)
		print("~ leaderboard ~",33,15+lb_y_pos,7)
		line(30,22+lb_y_pos,94,22+lb_y_pos)
		local col=8+flr(menu_t1/5)
		if col>=15 then
		col=8
		menu_t1=0
		end
		local l=leaderboard
		for i=1,10 do -- y+=7
			local str=""
			local c=13
			local ind=l[i].n
			local n=names[ind]
			if ind==11 then c=7 end
			if i==3 then c=9 end
			if i==2 then c=10 end
			if i==1 then c=col end
			if i<10 then str=" " end
		 
			print(str..i.."."..n.." - "..l[i].s,35,25+7*(i-1)+lb_y_pos,c)
		end
	--end
end

-- drawing gameover state
function draw_game_over()
	draw_play()
	if msg.show==true then
		rectfill(0+64*(1-msg.t/msg.d),msg.y,127-64*(1-msg.t/msg.d),msg.y+msg.h,0)
		rect(0+64*(1-msg.t/msg.d),msg.y,127-64*(1-msg.t/msg.d),msg.y+msg.h,7)
	end
	if t_helper > 64 then
		chars={"g","a","m","e"," ","o","v","e","r"}
		--print("game over", 48,54,7)
		local x=44
		local y=54
		for i=1,#chars do
		print(chars[i],
								x+4*i,
								y+sin((t-i*4)/70)*2,7)
		end
		if score>highscore then
			print("new highscore!", 40-cos(t/90)*8,40,7)
		end
		print("❎ restart",46+sin(t/90)*8,64,7)
		-- print("🅾️  menu",  46-sin(t/90)*8,70,7)
	end
end

-- drawinf fadein effect
function draw_fadein()
	if do_fi then 
		if t_fi>0 then
			rectfill(0,127-127*(t_fi/60),127,127,0)
		end
	end
end

-- drawing the game
function _draw()
	if game_state=="play" then
		draw_play()
	end
	if game_state=="game_over" then
		draw_game_over()
	end
	if game_state=="menu" then
		draw_menu()
	end
	if game_state=="fadeout" then
		draw_fadeout()
	end 
	
	draw_fadein()
end

__gfx__
00000000000280000080080000082000000cc0000008800000077000000000000088880070000000004444000024420000444400000000070000000000000000
00000000000280000080080000082000000cc0000008800000700700000000000800008070000000042244400444422004422440000000070000000000000000
00700700001288000280082000882100000cc0000008800000700700000000000800008070000000442244444444444424422422000000070008800000077000
00077000001288000281182000882100000cc0000008800000600700000dd0000800008070000000444444244224444444244442000000070087880000787700
00077000007c88000287c8200088c700000cc0000008800000700600000000000800008070000000442224444224422444444444000000070088880000777700
0070070000cc8800028cc8200088cc00000cc0000000000000700700000000000800008070000000244224444444424422444444000000070008800000077000
00000000001998000209902000899100000cc0000000000000700700000dd0000800008070000000044444400224444002442240000000070000000000000000
00000000002008000800008000800200000cc0000000000000600600000000000800008070000000004422000022440000422400000000070000000000000000
00007000000010000070070000000000000000000000000000600700000000000800008070000000000000000000000000000000000000070000000000000000
00070000000100000070070000066000000660000006600000700600000550000800008007777777777777777770770770770777777777707707707007077077
00770000001100000770077000066000000660000006600000600600000000000800008000000000000000000000000000000000000000000000000000000000
077770000111100007777770000dd000000dd000000dd00000d00700000000000800008000000000000000000000000000000000000000000000000000000000
00770000001100000777777000766700000760000006700000600600000550000800008000000000000000000000000000000000000000000000000000000000
00700000001000000777777000799700000790000009700000d00600000000000800008000000000000000000000000000000000000000000000000000000000
07000000010000000707707000000000000000000000000000d00d00000000000800008000000000000000000000000000000000000000000000000000000000
000000000000000007000070000000000000000000000000000dd000000000000088880000000000000000000000000000000000000000000000000000000000
000aa0000078a00000a78a00000a8700007777000000000000000000000000000000000002112000000211200777700000077770000000000000000000000000
000aa000008899000998899000998800077777700005600000d00d00000650000070070007dd755dd557dd700777777777777770000000000000000000000000
00aeea0004d9a6904daaaad4096a9d4077777777006dc7000d6556d0007cd600077777700676666ee66667600777777777777770000000000000000000000000
00a88a0009dd6790966666690976dd90770000770078c70006c78c60007c870007777770d66d66e87e66d66d7777777777777777000000000000000000000000
0aa88aa009d006a0ad0000da0a600d90700000070088c60006c88c60006c880007777770d67576788767576d7777777777777777000000000000000000000000
0aaaaaa000900a00a900009a00a009007000000700ddcd000dcddcd000dcdd00077777707675765dd56757677777777777777777000000000000000000000000
aaa88aaa00900a000a0000a000a00900070000700005d00000d00d00000d50000070070066ed66d11d66de667777777777777777000000000000000000000000
aaaaaaaa00000000000000000000000000000000000000000000000000000000000000006e8e66666666e8e67777777777777777000000000000000000000000
000880000003b00000b00b00000b30000070070000d56d000600006000d65d000700007067876676676678767777777777777777000000000000000000000000
000880000533b3b030b55b030b3b33507077770700d26d0006d22d6000d62d00077777706ddd60766706ddd67777707777077777000000000000000000000000
0086680005d576b0306336030b675d50707777070078e6000de78ed0006e870007777770d6e6d066660d6e6d7777707777077777000000000000000000000000
0087780005786db035d78d530bd68750777777770088ed0000e88e0000de8800007777000e8e00eeee00e8e00777007777007770000000000000000000000000
0887788005886bd03b3883b30db688507777777700ded00000deed00000ded00007777000d0d00878800d0d00707007777007070000000000000000000000000
0888888000353b000b0330b000b35300070770700066000000066000000066000007700000000068860000000000007777000000000000000000000000000000
8887788800300b000b0000b000b003000700007000dd0000000dd0000000dd00000770000000001dd10000000000007777000000000000000000000000000000
88888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000776766007776760077767600777676000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007eeeeee77e7eee267ee77ee67eeee6e600000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007e8ee8e66e7e8e8678e76e2d78e8e7e600000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007e8888e77e6e888d68e76e2d6888e7ed00000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006e8ee8e66e7e8e8678e7de2678e8e6e600000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007e8ee8e66e6e8e8d68e66e2d68e8e7ed00000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006eeeeeed6e6eee2d6ee7deed6eeee6ed00000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000006d6ddd006d6ddd006d66dd0066d6dd000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000776766007776760077767600777676000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007dddddd77d7ddd167dd77dd67dddd6d600000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007dccccd66d7dccc67cd76d1d7cccd7d600000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007dcdddd77d6dcd1d6cd76d1d6cddd7dd00000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006dcccdd66d7dccd67cd7dd167ccdd6d600000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007dcdddd66d6dcd1d6cd66d1d6cddd7dd00000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006ddddddd6d6ddd1d6dd7dddd6dddd6dd00000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000006d6ddd006d6ddd006d66dd0066d6dd000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000776766007776760077767600777676000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007333333773733356733773367333363600000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000733bbb3663733bb67b37635d73bb373600000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000073bb33377363bb5d6b37635d6bb3373d00000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006333bb3663733bb67b37d35673bb363600000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000073bbb3366363bb5d6b36635d6bb3373d00000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006333333d6363335d6337d33d6333363d00000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000006d6ddd006d6ddd006d66dd0066d6dd000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000776766007776760077767600777676000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007999999779799946799779967999969600000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000079aaa9966979aa967a97694d7aa9979600000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000079a99a977969a9ad6a97694d6a9a979d00000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000069a99a966979a9a67a97d9467a9a969600000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000079aaa9966969aa9d6a96694d6aa9979d00000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000006999999d6969994d6997d99d6999969d00000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000006d6ddd006d6ddd006d66dd0066d6dd000000000000000000000000000000000
00007888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00078888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00788888888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
78888888888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888882288888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888880088888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888880088888880000007888888888888800000000078888888888000000000788888888888888800000007888888800000000000000000000000000000000
88888880088888880000078888888888888880000000788888888888800000007888888888888888880000078888888880000000000000000000000000000000
88888880088888880000788888888888888888000007888888888888880000078888888888888888888000788888888888000000000000000000000000000000
88888880088888880007888888888888888888800078888888888888888000788888888888888888888007888888888888800000000000000000000000000000
88888880088888880078888888888888888888880788888888888888888807888888888888888888882078888888888888880000000000000000000000000000
88888880088888880088888888888888888888880888888888888888888808888888888888888888820088888888888888880000000000000000000000000000
88888880088888880088888828888888288888880888888820002888888808888888888888888888200088888888888888880000000000000000000000000000
88888880088888880088888808888888088888880888888800000888888808882220000000000000000088888820028888880000000000000000000000000000
88888880088888880088888808888888088888880888888800000788888808821110000000000000000088888800008888880000000000000000000000000000
88888880088888880088888808888888088888880888888800007888888808210000000000000000000088888800008888880000000000000000000000000000
88888880088888880088888808888888088888880888888800078888888802107888888888888888882088888801108888880000000000000000000000000000
88888880088888880088888808888888088888880888888880228888888201078888888888888888888088888801108888880000000000000000000000000000
88888880088888880088888808888888088888880888888888012888882000788888888888888888888088888802208888880000000000000000000000000000
88888880088888880088888808888888088888880888888888801288820007888888888888888888888088888802208888880000000000000000000000000000
88888880088888880088888808888888088888880088888888880128200078888888888888888888888088888802208888880000000000000000000000000000
88888880028888820088888808888888088888880008888888888012000788888888888888888888888088888802208888880000000000000000000000000000
88888880011888100788888808888888088888880000888888888800007888888888000000000888888088888801108888880000000000000000000000000000
88888888000000007888888808888888088888880002088888888880078888888880100000000788888088888801108888880000000000000000000000000000
88888888888888888888888808888888088888888872108888888888788888888801288888887888888088888800008888880000000000000000000000000000
88888888888888888888888208888888088888888888210888888888888888888012888888888888882088888800008888880000000000000000000000000000
08888888888888888888882008888888008888888888821088888888888888880128888888888888820088888800008888880000000000000000000000000000
00888888888888888888820008888882000888888888882108888888888888801288888888888888200088888800008888880000000000000000000000000000
00088888888888888888200000888820000088888888888200888888888888000888888888888882000008888000000888800000000000000000000000000000
00008888888888888882000000088200000008888888888000088888888880000088888888888820000000880000000088000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000d7d000000000000000000d7d0000000000000000000000000000
000000000000000000000000000000000000000000000000000000000700077700000000000d756d0000000000000000d756d000000000000000000000000000
00000000000000000000000000000000000000000000000000000000070007870000000000d76666d00000000000000d76666d00000000000000000000000000
0077770700707777007700777000777077770777000000000000000007000707000000000d766d666d000000000000d766d766d0000000000000000000000000
007888070070788807887078870788807888078870000000000000000700070700000000d766ddd666d0000000000d766d76667d000000000000000000000000
007000077070700007007070070700007000070070000000000000000707077700000000756dd6dd666d00000000d766d76dd656000000000000000000000000
007777077070777007007077780700007777077780000000000000000808088800000000d666dd6d6556d000000d766d76dd6665000000000000000000000000
0078880787707880070070788707000078880788700000000000000000000000000000000d666dd75d667d0000d766d76dd66650000000000000000000000000
00700007077070000700707007070000700007007000000000000000000000000000000000d666756dd666d00d766d76dd766500000000000000000000000000
008777070870700008778070070877708777070070000000000000000000000000000000000d665dd6dd667dd766d76dd7665000000000000000000000000000
0008880800808000008800800800888008880800800000000000000000000000000000000000d656dd6d6557766d76dd66650000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000d666dd75d6666d76dd766500000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000d766756dd66d76dd7665000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000d665dd6ddd76dd76650000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000d756dd7dd6dd766500000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000d766dd7ddd7665000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000d766ddd6dd766d000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000d766d76dd6dd766d00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000d766d76dddd6d6556d0000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000d766d76dd77dd75d666d000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000d766d76dd7667756dd666d00000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000d766d76dd766665dd6dd666d0000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000d766d76dd7665d656dd6d6556d000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000d766d76dd766500d667dd75d766d00000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000d766d76dd66650000d666756dd766d0000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000d766d76dd7665000000d665dd6dd667d000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000756d76dd766500000000d657dd6dd756000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000d6676dd66650000000000d667ddd7665000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000d666d6665000000000000d666d76650000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000d66766500000000000000d66766500000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000d65650000000000000000d7565000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000d65000000000000000000d650000000000000000000000000000
__label__
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000107070770000007710002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000107070870000008710002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000107070070000000710002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000107770070000000710002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000108780777007007770002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100800888008008880002
21111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111112
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000078888888010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000788888888810000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100007888888888880000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100078888888888888000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100788888888888888800000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100888888888888888800000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100888888822888888800000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100888888800888888800000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100888888800888888800000078888888888888000000000788888888880000010007888888888888888000000078888888000000000000010002
20000000000100888888800888888800000788888888888888800000007888888888888000010078888888888888888800000788888888800000000000010002
20000000000100888888800888888800007888888888888888880000078888888888888800010788888888888888888880007888888888880000000000010002
20000000000100888888800888888800078888888888888888888000788888888888888880017888888888888888888880078888888888888000000000010002
20000000000100888888800888888800788888888888888888888807888888888888888888078888888888888888888820788888888888888800000000010002
20000000000100888888800888888800888888888888888888888808888888888888888888088888888888888888888200888888888888888800000000010002
21111111111111888888811888888811888888288888882888888818888888211128888888188888888888888888882111888888888888888811111111111112
20000000000100888888800888888800888888088888880888888808888888000008888888088822200000000001000000888888200288888800000000010002
20000000000100888888800888888800888888088888880888888808888888000007888888088211100000000001000000888888000188888800000000010002
20000000000100888888800888888800888888088888880888888808888888000078888888082100000000000001000000888888000188888800000000010002
2000000000010088888880088888880088888808888888088888880888888800078888888802107888d7d888888888882088888d7d1188888800000000010002
200000000001008888888008888888008888880888888808888888088888888022888888820107888d756d8888888888808888d756d188888800000000010002
20000000000100888888800888888800888888088888880888888808888888880128888820017888d76666d88888888880888d76666d88888800000000010002
2000000000010088888880088888880088888808888888088888880888888888801288820007888d766d666d888888888088d766d766d8888800000000010002
200000000001008888888008888888008888880888888808888888008888888888012820007888d766ddd666d8888888808d766d76667d888800000000010002
200000000001008888888002888882008888880888888808888888000888888888801200078888756dd6dd666d88888880d766d76dd656888800000000010002
200000000001008888888001188810078888880888888808888888000088888888880000788888d666dd6d6556d888888d766d76dd6665888800000000010002
2000000000010088888888000001007888888808888888088888880002088888888880078888888d666dd75d667d8888d766d76dd66658888800000000010002
20000000000100888888888888888888888888088888880888888888721188888888887888888888d666756dd666d88d766d76dd766588888800000000010002
200000000001008888888888888888888888820888888808888888888821088888888888888888801d665dd6dd667dd766d76dd7665188888800000000010002
2000000000010008888888888888888888882008888888008888888888821088888888888888880128d656dd6d6557766d76dd66650188888800000000010002
20000000000100008888888888888888888200088888820008888888888821088888888888888012888d666dd75d6666d76dd766500188888800000000010002
211111111111111118888888888888888821111188882111118888888888821188888888888811188888d766756dd66d76dd7665111118888111111111111112
2000000000010000008888888888888882000000088200000008888888888000088888888881000088888d665dd6ddd76dd76650000100880000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000d756dd7dd6dd766500000100000000000000010002
200000000001000000000000000100000000000000010000000000000001000000000000000100000000000d766dd7ddd7665000000100000000000000010002
200000000001000000000000000100000000000000010000000000000001000000000000000100000000000d766ddd6dd766d000000100000000000000010002
20000000000100000000000077770700707777007701777000777077770777000000000000010000000000d766d76dd6dd766d00000100000000000000010002
2000000000010000000000007888070070788807887178870788807888078870000000000001000000000d766d76dddd6d6556d0000100000000000000010002
200000000001000000000000700107707070000700717007070000700007007000000000000100000000d766d76dd77dd75d666d000100000000000000010002
20000000000100000000000077770770707770070071777807000077770777800000000000010000000d766d76dd7667756dd666d00100000000000000010002
2000000000010000000000007888078770788007007178870700007888078870000000000001000000d766d76dd766665dd6dd666d0100000000000000010002
200000000001000000000000700107077070000700717007070000700007007000000000000100000d766d76dd7665d656dd6d6556d100000000000000010002
20000000000100000000000087770708707000087781700708777087770700700000000000010000d766d76dd766500d667dd75d766d00000000000000010002
2000000000010000000000000888080080800000880180080088800888080080000000000001000d766d76dd66650000d666756dd766d0000000000000010002
200000000001000000000000000100000000000000010000000000000001000000000000000100d766d76dd7665100000d665dd6dd667d000000000000010002
200000000001000000000000000100000000000000010000000000000001000000000000000100756d76dd766501000000d657dd6dd756000000000000010002
200000000001000000000000000100000000000000010000000000000001000000000000000100d6676dd66650010000000d667ddd7665000000000000010002
2111111111111111111111111111111111111111111111111111111111111111111111111111111d666d6665111111111111d666d76651111111111111111112
20000000000100000000000000010000000000000001000000000000000100000000000000010000d66766500001000000000d66766500000000000000010002
200000000001000000000000000100000000000000010000000000000001000000000000000100000d65650000010000000000d7565100000000000000010002
2000000000010000000000000001000000000000000100000000000000010000000000000001000000d65000000100000000000d650100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100007000700000017770700077707071000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100008700870000017870700078707071000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100888878887888887778788877787778888888888888888888888888888888810000000000000001000000000000000100000000000000010002
20000000000100888788878888887888788878788878888888888888888888888888888888810000000000000001000000000000000100000000000000010002
20000000000100887888788888887888777878787778888888888888888888888888888888810000000000000001000000000000000100000000000000010002
21111111111111888888888888888888888888888888888888888888888888888888888888811111111111111111111111111111111111111111111111111112
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100007000777077717700777077707771077077707770770100000000000000010000000000000001000000000000000100000000000000010002
20000000000100007000788078717870788078707871787078707870787100000000000000010000000000000001000000000000000100000000000000010002
20000000000100007000770077717070770077807781707077707780707100000000000000010000000000000001000000000000000100000000000000010002
20000000000100007000780078717070780078707871707078707870707100000000000000010000000000000001000000000000000100000000000000010002
20000000000100007770777070717770777070707771778070707070777100000000000000010000000000000001000000000000000100000000000000010002
20000000000100008880888080818880888080808881880080808080888100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
21111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111112
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000770777077717700777077700771000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100007880787078817870878087807881000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100007000778077017070070007007771000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100007000787078017070070007008871000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100008770707077717770777007007781000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000880808088818880888008008801000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
21111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111112
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001707077700770707107700770077077717770000077700001000000000000000100000000000000010002
20000000000100000000000000010000020202220022727207227022707272227222707072727000070070700001000000000000000100000000000000010002
20000000000100000000000000010000020200200201777207007200777277727200707077027700000070700001000000000000000100000000000000010002
20000000000100000000000000010000022200200201727207227270727202707220707072727000070070700001000000000000000100000000000000010002
20000000000100000000000000010000020200200202727277727770727277020770772072727770000077700001000000000000000100000000000000010002
21111111111111111111111111111111121212221222121212211122122112121222111112221111111111111111111111111111111111111111111111111112
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
20000000000100000000000000010000000000000001000000000000000100000000000000010000000000000001000000000000000100000000000000010002
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222

__map__
0900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
191a1b00001c1a1a1a1a1e000000000000008081000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000909192939495969798999a9b9c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000a0a1a2a3a4a5a6a7a8a9aaabac00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000b0b1b2b3b4b5b6b7b8b9babbbc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000c0c1c2c3c4c5c6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000d0d1d2d3d4d5d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010100002b52329543265532555323551215511f5511c5511955118551165511455113541105410d5310b52108521075210551103511025110151102400023000130003400024000140001400024000240001400
0101000020652206421844214442114320d42208422034120141206302053060230601300056001c6001f60022600000002460000000266000e6002a6000c6002d60030600066003360036600376003760000000
010200003c651356512f65129651226511d6511665110651094530c4531044313443174431b4420744207445094450b4450f445114351343513435084350a4350c4350d4250e4250f4250342506415094150a415
01020000396402c6312062110611234451d2451f0451d4452323119032094320a2320c0230c0230a0130201301600016000160001600016000160001600016000160001600016000160001600016000160001600
01010000147461d7462075621756205511b5511154109541055410553109531095310652101521015110230001300013000000000000000000000000000000000000000000000000000000000000000000000000
0102000021561275612b5512f54133531385213d51300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200002605126052260432603326023260112601126003260000300003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500002b2522b252000022b2522b252000022b2522b252000022b0022b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300003764337643376433764337643013430134101341013410134101341013410134102341033410433106331083310a3310d3310e331113211332115311183111c3112131126311293112d3113331139311
010200001a651190511805118051160511505112051100510e0510d0510b051090510705106051040510305103051020510205101051010510105101051010410104101041010310103101021010210101101011
010100000d610116200d610116200d610116200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101000025650286502965029650286502565023450204501e4501c4501a45018450164401444012440104400f4400d4400c4400a440094400744006440054400544004430034300343003430034200241002400
011000200032500315003150032500325003150031500325003250031500315003250032500315003150032502325023150231502325023250231502315023250232502315023150232502325023150231502325
011000200532505315053150532505325053150531505325053250531505315053250532505315053150532507325073150731507325073250731507315073250732507315073150732507325073150731507325
00100000012111921121211282112e2112e2112e2112e2112e2112e2112e2112e2112e2112e2112e2112e2112e2112e2112e2112e2112e2112e2112e2112e2112e2112e2112e2112e21128211202111821102211
011100000042500315002150042500315002150042500315002250041500325002150041500325002150041500325002150041500325002150041500325002150042500315002250041500315002250041500315
010e00000c033195151b5150f1101b5151e51509115081201e515195151b7150c003195151b5151e5151b7150c033195151b715197170c033217151e5151b7150c033195151b715197160c033195151e5151b715
010e00000d1300f1121e515031300c0330d02009135081200c0330613009125081300c0331e5150d1300f110031301e51501130035200c0330953508135091200c0331e51506130080200d0200f1201212206532
010e00000c043254102241027410273121e4121b210202102031020212202121b715195151b5151e5151b7150c043214101e41023410233122641223210282102831228212272152541022215204101e2101b410
010e00000d1300f1121e515031300c0330d02009135081200c0330613009125081300c0331e5150d1300f1100313001035021250413506130080200d0250f120091300b025141201213012122121121201206031
010e00000b1300d1121c515011300c0330b02007135061200c0330413007125061300c03306515091300b1100e130105151f515041200c03309535041350b1220b1221e515091300b0250e020101201312213532
010e00000c03317515195150d110195151c51507115061201c51517515197150c00317515195151c515197150c0331a5151c715177170c033157151c025170100c033195151a0121c5120c0331f0122301223712
011100000a1300c1221b51500130116150a02006135051200c0330313006125051300c0331b5150a1300c110001301b5150a13000520116150653505135061200c0331b51503130050200a0200c1200f12203532
011100000c033165141b0141f514110141601412025165141b0141f5141271416514220141d5141f0141b514110140c5141f0141b5141d01418514130141b5141f014165141d0141651411014160141851418515
011100000c033225141b014245141d0142201412025225141b0141f5141271416514220141d5141f0141b514110140c5141f0141b5141c01417517150141a5141f0142251126014225141d0141f5172201427514
01110000275242b52429524295202852129521295202952029522295122951516514220141d5141f0141b514110140c5141f0141b5141d01418514130141b5141f014165141d0141651411014160141851424524
0111000027524245241f5241f5201f5201f5201f5101f5121f5121f5121f51516514220141d5141f0141b514110140c5141f0141b5141c01417517150141a5141f0142251126014225141d0141f5172201427514
0111000001130080200f115011301161501130080150c03301130117151651505130070201b5151c5151d51601130080200f115011301161501130080150c0330113011715070201b5150a0200c1200f12203532
01110000275242b52429524295202952029510295102951029512295122951516514116151d5141d5151f5160c0330c5141f0140c0331c01417517150141a5141f014225111d0141f5172201427514295162e524
0111000033524305242b5242b5202b5202b5202b5202b5202b5222b5122b51516514220141d5141f0141b514110140c5141f0141b5141c01417517150141a5141f0142251126014225141d0161f511160110f511
0111000001135010250b135010351901501135010250b135010351f0141f5151f014116151f017120151051501135010250b135010351901501135010250b1350103512015105151161405115040250f5250e035
011100000c033285172a5151161500000116150c0331c0151161520014200152071420017145160d0150b5150c033285162a515116150f303116150c0331c015116150d0150b515277111e0141c5152301420515
011100000c0330c1221b51500130116150a02006135051200c0330313006125051300c0331b5150a1300c110001301b5150a13000520116150653505135061200c0331b515031300502005115040250313502045
0111000033524305242b5242b5202b5202b5202b5202b5202b5222b5122b51516514220141d5141f0141b514110140c5141f0141b5141c01417517150141a5141f0142251126014225141d0141f517160141b514
0111000004135040250e135040351c01504135040250e13504035215162250522505116152f01523516235150c033071351312507135116150713505125071350c03307100071351310511615040051d6051d615
011100000c033101151a025116150000011615101151a02511615225152350517016200071450611615245202652026510265122252022510225122251222515056142251723505170161f53021521215121f530
011100000c033031350e135030351b01503135030250e1350303521516225052250511615117101171501115011350d125010150113503105011350d135010250113500000000000451405511067001161511615
011100001f5301f5301f522116151f5050c0331f01513115116151d7141f711137161351613712137150c0230c0331f0151311511615000000c0331f0151311511615000000c0330351404511057000652107531
0111000003135031250e035030351b01503135030250e13503035215162250522505116152f01523516235150c033051350f025051351161505135051350c0230c0330710007135131051161511025071351d615
011100000c0331111513125116150000011615111151311511615225162350513515200071151511615245202652026510265122b5202b5102b5122b5122b5150561422517235052e5002e5202e5102e51230520
011100003052030522325122b5202b5222b512180171a01528520280222a512255202552225512100161201523520255262551520015285202a5202a5150c0332301525517280202a515290242b5152e01633520
011100000c0330c1221b51500130116150a02006135051200c0330313006125051300c0331b5150a1300c110001301b5150a13000520116150653505135061200c0331b51503130050200a0200c1200f12203532
0111000030520305223051230515110141601412025165141b0141f5141271416514220141d5141f0141b514110140c5141f0141b5141d01418514130141b5141f014165141d0141651411014160141851418515
011100000c033031350f12503135116150513511116131250c033011350d12501135116150b1350d115011250c0330413501025081350b6150b1350d135080250c0330a135070350513511615030350213501035
010400002a5342a53529524295252851428515275342753526524265252551425515245342453523524235252251422515215342153520524205251f5141f5151e5341e5351d5241d5251c5141c5151b5341b535
010400002502425025240142401523014230152202422025210142101520014200151f0241f0251e0141e0151d0141d0151c0241c0251b0141b0151a0141a0151902419025180141801517014170151602416025
010400000f1240f1250e1140e1150d1140d1150c1240c1250b1140b1150a1140a1150912409125081140811507114071150612406125051140511504114041150312403125021140211501114011150012400125
010d0000001200011000112071250a1250c1250312003110031120a1250d1250f1250612510125121250912513125151251811018110121110c11106111001110011200115001000010000100001000010000100
010400000061500615006150061500615006150061500615006150061500615006150061500615006150061500615006150061500615006150061500615006150061500615006150061500615006150061500615
010d0000386102b611206111561109611016112d4102e3112e2102e4102e3122e2122e4102d3152c2102a41527310252152a4102a3122a2122a412343113f2113f50001605016050160501605016050160501605
010d00000c0200c5160c0121352516525185250f0200f5160f01216525195251b525120151c0151e025150151f0152101524020240161e01118011120110c0110c0120c015000000000000000000000000000000
010d00000711007110071120712511025130250a1100a1100a1120a12514025160250d1151711519025100151a0151c01518020180101e01118011120110c0110c0120c015000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010800002a534295242851427534265242551424534235242251421534205241f5140000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004
010800002503424024230142203421024200141f0341e0241d0141c0341b0241a0141900400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010200002c6531a6431663305623234451d2451f0451d4452323119032094320a2320c0230c0230a0130201301600016000160001600016000160001600016000160001600016000160001600016000160001600
__music__
01 11104344
00 11104344
02 14154344
00 16174344
01 16184344
00 16194f44
00 161a4344
00 1b1c4344
00 16214344
00 16174344
00 16184344
00 16194344
00 161a4344
00 1b1c4344
00 201d4344
00 1e1f4344
00 1e1f4344
00 22234344
00 24254344
00 26274344
00 2b284344
02 292a4344
00 2c2d2e30
00 2f323331

