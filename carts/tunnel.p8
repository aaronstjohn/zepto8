pico-8 cartridge // http://www.pico-8.com
version 15
__lua__
-- tunnel
-- by rez

function _init()
	cursor(0,0)
	f=128 --focale
	r=32  --radius
	z=512 --max z
	s=2   --speed
	d={}  --dots
	c={}	 --circle
	n1=32
	n2=24
	nc=n2*32
	for i=0,n1 do
		d[i]={}
		d[i].x=0
		d[i].y=1024
		d[i].z=z/n1*i
	end
	for i=0,nc do
		a=1/nc*i
		c[i]={}
  c[i].x=r*cos(a)
  c[i].y=r*sin(a)
	end
	a=0  --angle
	p=0
	x=0
	y=0
	cr=z/8
	cam=0.05
end

function _draw()
	cls()
	---------------------draw dots
 x1=x+dotx(a+cam)
 y1=y+doty(a+cam)
	for i=p-1,0,-1 do
	 dot(d[i],i)
	end
	for i=n1-1,p,-1 do
	 dot(d[i],i)
	end
	--info()
end

function dot(v,i)
	x2=64+((x1+v.x)/v.z)*f
	y2=64+((y1+v.y)/v.z)*f
	ac=nc/n1*i-a*1024
	for j=0,n2 do
 	col=(v.z-32+rnd(64))/cr
 	o=0
 	if(j%4>1) then o=1 end
	 color(sget(flr(col),o))
		k=flr(ac+nc/n2*j)%nc
	 x3=x2+(c[k].x/v.z)*f
	 y3=y2+(c[k].y/v.z)*f
	 pset(x3,y3)
	end
	--if(btn(0)) then x-=0.1 end
	--if(btn(1)) then x+=0.1 end
	--if(btn(2)) then y-=0.1 end
	--if(btn(3)) then y+=0.1 end
	--if(btn(4)) then cam-=s/2/z/n1 end
	--if(btn(5)) then cam+=s/2/z/n1 end
end

function dotx(v)
	return 48*cos(v)+32*sin(v)
end

function doty(v)
 return 48*sin(v)-32*cos(v)
end

function _update60()
	a+=s/2/z
 for i=0,n1 do
		local v=d[i]
		v.z-=s
		if(v.z<s) then
			v.z=v.z+z
		 v.x=dotx(a)
		 v.y=doty(a)
			p+=1
			if(p>n1) then p=0 end
		end
	end
end

function info()
 print("cam:"..cam,1,7,13)
	print("x:"..x,1,13,13)
	print("y:"..y,1,19,13)
end
__gfx__
7777fe21000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
dddddd51000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000d000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000d000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000d00000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000d0000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0000000000000000000000000000000000000000
000000000000000000000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000d0000000000000000700000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000d00000000000000000007000000000000000070000000000000000000
00000000000000000000000000000000000000000d00000000000000000000000000000000000000000070000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000d0000000000000000000000000000000000000000000070000000
00000000000000000000000000000000000000000000000000000700000000000000000000000007070000700000070000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000070000d00000000000000dd0000d00000d000007000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000d00707dd000070000d700000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000d00fdd0ef000fdd0000700000d000000d00000070000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000ee07d700d0000f000000dd000007000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000ded70ddd000d000dd000007700000007000000d00000000000000000000000000
0000000000000000000000000000000000000000000000000000000000007ed00dd0700e0e000e000000d0000000dd0000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000700005eedf20d700d0000e000000d0000000070000000070000000d0000000007000000000
0000000007000000000000000000000d000000000000d0000000000002ed200d0d70000000d000000f000000df00000000070000000000000000000000000000
00000000000000000000000000000000000000000000000000000005510df05000000500d0000d0f000000d0000000000dd00000000d00000000000000000000
0000000000000000000000000000000000000000000000000000000250050f0d270020000000000000f0f0000000000700000000000000000000000000000000
00000000000000000000000000000000000000000000000000000522dd172d0d0020000e0000d0000d0000000000d07000000000007000000000000000000000
0000000000000000000000000000000000000000000000000000110101e00d0700000e000020000d00000000f0d0000000000000070000000000d00000000000
0000000000000000000000000000000000000000000000000005e27d000d00d005005000e0000e00000000f00000000000000d0d000000000000000000000000
00000000000000000000000000000000000000000000000000501000e010d1d010000050000e00000d00d00000000000070070000000000000d0000000000000
000000000000000000000000000000000000000000000000d10000000e070070001005000d00000e00000000000f0d0d00000000000000000000000000000000
00000000000000000000000000000000000000000000000055225d0e00d07d010100000000000e00000000d00f00000000000000000000007000000000000000
00000000000000000000000000000000000000000000000110000000e00d0d0000010005000500000000d0000000000000000000000000700000000000000000
00000000000000000000000000000000000000d000000010012550070d00ff0010100200050000000f000000000000000000000000d0d0000000000000000000
0000000000000000000000000000000000000000000000051000002e00d71d100000000200000d0e0000000000000000d00d07070000000000000000000000d0
00000000000000000000000000000000000000000000011000000000d00efd001001000000d00000000000d0d00f0f0000000000000000000000000000000000
000000000000000000000000700000000000000000000001125d520e00d0000100100200e00000d00f0e00000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000011000000000d70e7d00100500200000d000000000000000000000000000000000000000000000d00000
0000000000000000000000000000000000000000000000012015022000d00100010050020e000000000000000000000000000000000000000000000000000000
07000000000000000000000000000000000000000000d01000000000d0de0dd10050050000e0d00d00f0f00d00d0070700d00000000000000007007000000000
00000000000000000000000000000000000000000000000010110d20d070e7d02050050e00000000000000000000000000000d0070070d00d000000000000000
0000000000000000000000000000000000000000000000110000000205d0e1dd20050d0200e00d0d00f000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000110200050d127dd05d050e0000000000000f00d000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000011000110205007007ddd0d00000f00d0000000000000d007000000000000000000000000000000000
0000000000000000000000000000000000700000000000000d100010d050000007ddd0fe0f00000d00f000000000000007000000000000000000000000000000
000000000000000000000000000000000000000000000000000010100000007000707f00f000d00000000f00000000000000d000000000000000000000000000
00000000000000000000000000000000000000000000000000000101000d00007000000f0000000d00000000d00000000000000d007000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000007070f0000d00000f000000000d000000000000000007000000000000000000
00000000000000000000000000000000000000000000000000000d00000000d00000000000d000d00000f000000000700000000000000000d000000000000000
00000000000000000000700000000000000000000070000000000000000000000d000000d0000000000000000000000007000000000000000000d00070007000
0000000000000000000000000000000000000000000000000000000000000000000d00d00000d0007000000d0000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000d000000000000000d00000000f000000d000000000d000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000d00000000d0000007000000000000000000000000d000000000000000000000000
00000000000000000000000000000000000000000000000007000000000000000d000d0000000000000000d00000070000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000007000070000000000000000000000000700000000000000000000
00000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000000070000000000000000000000000000000
00000000000000000000000000000000070000000000000000000000000000000000000007000000000000000d00000000000000000000700000000000000000
00000000000000000000000000000000000000000000000000000000000007000700007000000070000d000000000000000d00000000000000d0000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000
0000000000000000000000000000000000000000000070000000000000000000000000000007000000000000000000000000000000000000000000d000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000d00000d0000000000000000d000000000000000000000000
00000000000000000000000000000000000000000000000000007000000000000000007000000000000000000000007000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000700000700000000000000000000000000000000000000007000000000000000070000
0000000000000000000000000000000000000000000000000000000000000000000000000000d000000000000700000000000000000000000000000000000000
00000000000000000000d0000000000000000000000000000000000000000000000000000000000000d000000000000000d00000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000d00000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000d0000000000000000000000000000000000000000000000000000007000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000d000000000000d0000007000000000000000d00000000000000000000000000
000000000000000000000000000000000000000000000000d00000000d00000000000000000000000000000000000000000000000000000000d0000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000d0000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d000000000700000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000070000000700000000000000000000000000000000d0000000
0000000000000000000000000000000000000000000000000000000000000000d000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000d000000000000000000000000000000000000000000d000000000070000000000000000000
000000000000000000000000d0000000000000000d00000000000000000000000000000070000000000000000000000000000000000000000000000000000070
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d00000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000700000000000000000000000000000000000007000000000000d00000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000700000000000000000000070000000000000000000d000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000d0000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000000000700000000000000d00000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000700000000000000000000000000000000000000000000000000000700000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000d000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000d000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000007000000000000000000000000000000000000000000000000000000000000000000d0000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000700000000000000000000000000000000000000d0000000000000000000000000000000000000000070000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000d00000000000007000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
4041424344454647484900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5051525354555657585900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
001000002e0001c3003e0003e00018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000180001800018000
0010000002305022050e3050e20502305022050e3050e20502305022050e3050e20502305022050e3050e20502305022050e3050e20502305022050e3050e20502305022050e3050e20502305022050e3050e205
001000000220034605346043460528603346053460534605022003460534604346052860334605346053460502200346053460434605286033460534605346050220034605346043460528603346053460534605
001000001d4021c4021a4041d4021c4021a4041c4021c4021f4021c404000001f4022d505000001d5052d505285051d5052b5051d505295052b50526505295052850526505295052850526505000002850511100
001000003200534005355053950532505345053550539505325053450535505395053250534505355053950532505345053550539505325053450535505395053250534505355053950532505345053550539505
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 01020304
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344

