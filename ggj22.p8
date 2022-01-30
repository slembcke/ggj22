pico-8 cartridge // http://www.pico-8.com
version 35
__lua__

rest_len = 32
function rope_physics(dot0, dot1)
	local dx = dot0.x1 - dot1.x1
	local dy = dot0.y1 - dot1.y1
	local len = sqrt(dx*dx + dy*dy)
	if len > rest_len then
		local diff = (len - rest_len)/(len*(dot0.m_inv + dot1.m_inv))
		dot0.x1 -= dot0.m_inv*dx*diff
		dot0.y1 -= dot0.m_inv*dy*diff
		dot1.x1 += dot1.m_inv*dx*diff
		dot1.y1 += dot1.m_inv*dy*diff
	end
end

function dot_physics(dot)
	local gravity = 0.1
	local x, y = dot.x1, dot.y1
	dot.x1 += dot.x1 - dot.x0
	dot.y1 += dot.y1 - dot.y0 + gravity
	dot.x0, dot.y0 = x, y
end

GRAB_BLACK = 0b01
GRAB_WHITE = 0b10
GRAB_BOTH = 0b11

TILE_PROPS = {
	default = {grab = GRAB_BOTH},
	[127] = {collide = true}
}

function get_prop(x, y)
	local tile = mget(x/8, y/8)
	return TILE_PROPS[tile] or TILE_PROPS.default
end

function handle_corner(dot, px, py, dx, dy)
	if get_prop(px, py).collide then
		local dist = sqrt(dx*dx + dy*dy)
		if dist < 4 then
			local diff = (dist - 4)/dist
			dot.x1 -= dx*diff
			dot.y1 -= dy*diff
		end
	end
end

function dot_collide(dot)
	-- Collide with edges first
	local edge = dot.x1 - 4
	if get_prop(edge, dot.y1).collide then dot.x1 += -edge & 0x7.FFFF end
	local edge = dot.x1 + 4
	if get_prop(edge, dot.y1).collide then dot.x1 -=  edge & 0x7.FFFF end
	local edge = dot.y1 - 4
	if get_prop(dot.x1, edge).collide then dot.y1 += -edge & 0x7.FFFF end
	local edge = dot.y1 + 4
	if get_prop(dot.x1, edge).collide then dot.y1 -=  edge & 0x7.FFFF end

	-- handle_corner(dot, dot.x1 - 4, dot.y1 + 4,  dot.x1 + (-(dot.x1 - 4) & -8),  dot.y1 - ( (dot.y1 + 4) & -8))
	handle_corner(dot, dot.x1 - 4, dot.y1 - 4,  ( dot.x1 & 0x7.FFFF),   ( dot.y1 & 0x7.FFFF))
	handle_corner(dot, dot.x1 + 4, dot.y1 - 4, -(-dot.x1 & 0x7.FFFF),   ( dot.y1 & 0x7.FFFF))
	handle_corner(dot, dot.x1 - 4, dot.y1 + 4,  ( dot.x1 & 0x7.FFFF),  -(-dot.y1 & 0x7.FFFF))
	handle_corner(dot, dot.x1 + 4, dot.y1 + 4, -(-dot.x1 & 0x7.FFFF),  -(-dot.y1 & 0x7.FFFF))
end

dots = {
	{x0=32, y0=64, x1=32, y1=64, m_inv=1, grab = GRAB_BLACK},
	{x0=32, y0=64, x1=32, y1=64, m_inv=1, grab = GRAB_WHITE},
}

anchor, swing = dots[1], dots[2]
function _update60()
	local btn5 = btn(5)
	local btn5_down = btn5 and not _btn5
	local btn5_up = not btn5 and _btn5
	_btn5 = btn5

	if btn5_down then wants_to_grab = true end
	if btn5_up then wants_to_grab = false end

	local grabable = get_prop(swing.x1, swing.y1).grab
	local can_grab = band(grabable, swing.grab) != 0
	if wants_to_grab and can_grab then
		anchor, swing = swing, anchor
		wants_to_grab = false
	end

	anchor.x0 = anchor.x1
	anchor.y0 = anchor.y1
	anchor.m_inv = 0

	-- Apply movement.
	local x_inc = 0.02
	if btn(0) then swing.x1 -= x_inc end
	if btn(1) then swing.x1 += x_inc end

	local len_inc = 0.5;
	if btn(2) then rest_len -= len_inc end
	if btn(3) then rest_len += len_inc end
	rest_len = max(16, min(rest_len, 32))

	dot_physics(swing)
	dot_collide(swing)
	swing.m_inv = 1

	-- Apply spring
	if btn(4) then
		local dx = anchor.x1 - swing.x1
		local dy = anchor.y1 - swing.y1
		local len = sqrt(dx*dx + dy*dy)
		swing.x1 += dx*len/1000
		swing.y1 += dy*len/1000
	end

	rope_physics(dots[1], dots[2])
end

function _draw()
	cls(12)
	palt()

	local dot0, dot1 = dots[1], dots[2]
	camera(
		(dot0.x1 + dot1.x1)/2 - 64,
		(dot0.y1 + dot1.y1)/2 - 64
	)

	map(0, 0, 0, 0)
	line(dot0.x1, dot0.y1, dot1.x1, dot1.y1, 8)
	palt(0x0080) -- Red transparent
	spr(122, dot0.x1 - 4, dot0.y1 - 4)
	spr(123, dot1.x1 - 4, dot1.y1 - 4)

	camera()
	if dbg_msg then print(dbg_msg) end
end

__gfx__
000000006c6c6c6c6c6c6c6c33333b555b333333ff4444ffffaaaaff3ff3ff3f553f3ff3ffffffffffffffffffffffffffffffffffffffff5555555500000000
00000000cccccccccccccccc3333b53535b33333f444444ffaaaaaaff3ff3fff3ffff3ffffffffffffffffffffffffffffffffffffffffff5555555500000000
000000006ccccccccccccccc3333b35353b3333344444444aaaaaaaa3f35fffff3fffff3ffffffffffffffffffffffffffffffffffffffff5555555500000000
00000000cccccccccccccccc333b5333335b333344444444aaaaaaaaffff3f33ff3ff33ffffff677777ffffffffff7a7777fffffffffffff5555555500000000
000000006ccccccccccccccc333b3333333b333344444444aaaaaaaaff3ff5ff3f3f3fffffff48667777ffffffffaaaa7a77ffffffffffff5555555500000000
00000000cccccccccccccccc33b533333335b33344444444aaaaaaaaf3f3fffff3f3ff33fff4444866677ffffffaaaaaa77a7fffffffffff5555555500000000
000000006ccccccccccccccc3b33333333333b33f444444ffaaaaaaf3fff3f335fffffffff444444486767ffffaaaaaaaaa7a7ffffffffff5555555500000000
00000000ccccccccccccccccb5333333333335b3ff4444ffffaaaafff335fffffff3f3ffff444444444866ffffaaaaaaaaaaaaffffffffff5555555500000000
000000006ccccccccccccccc5b33333333333b5bff1111ffffddddff35fff3ffff3fff3fff444444444446ffff9aaaaaaaaaa7ff000000000000000000000000
00000000cccccccccccccccc3b33333333333b35f111111ffddddddfff3ff5f3f3fffff3ff444444444444ffff99aaaaaaaaaaff000000000000000000000000
000000006ccccccccccccccc53b333333333b35311111111dddddddd3fff3fff5ff3ff3fff244444444444ffff99aaaaaaaaaaff000000000000000000000000
00000000cccccccccccccccc33b333333333b33311111111ddddddddff3ff3f3f3ff33fffff2244444444ffffff999aaaaaaafff000000000000000000000000
000000006ccccccccccccccc335b3333333b533311111111ddddddddfff3ff5fff3ff53fffff22444444ffffffff99999aaaffff000000000000000000000000
00000000cccccccccccccccc3335bb333bb5333311111111ddddddddff3f3fff3ff3fffffffff222244ffffffffff999999fffff000000000000000000000000
000000006ccccccccccccccc333355b3b5533333f111111ffddddddf35fff3ff3ff53ff3ffffffffffffffffffffffffffffffff000000000000000000000000
00000000cccccccccccccccc3333335b53333333ff1111ffffddddfffff3fff3ff3fffffffffffffffffffffffffffffffffffff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000fffff777777ffffffffff777777fffff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000ffff77777777ffffffff77777777ffff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000fff7666666677ffffff7a777a7777fff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000ff748488886767ffffaaaaaaaaa7a7ff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000ff444444444866ffffaaaaaaaaaaa7ff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000ff444444444488ffff9aaaaaaaaaaaff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000ff444444444444ffff99aaaaaaaaaaff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000ff244444444444ffff99aaaaaaaaaaff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000fff2244444444ffffff999aaaaaaafff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000ffff22444444ffffffff99999aaaffff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000fffff222244ffffffffff999999fffff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000ffffffffffffffffffffffffffffffff000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000088888111111888888888877777788888
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000888111111110088888877777777ff888
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008811111111110088887777777777ff88
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000081111111111110088777777777777ff8
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000081111111111110088777777777777ff8
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111110077777777777777ff
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111110077777777777777ff
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111110077777777777777ff
000000000000000000000000000000000000000000000000000000000000000000000000000000008811118888777788111111111111110077777777777777ff
0000000000000000000000000000000000000000000000000000000000000000000000000000000081111108877777f8111111111111110077777777777777ff
00000000000000000000000000000000000000000000000000000000000000000000000000000000111111107777777f11111111111110007777777777777fff
00000000000000000000000000000000000000000000000000000000000000000000000000000000111111107777777f80111111111110088f77777777777ff8
00000000000000000000000000000000000000000000000000000000000000000000000000000000111111107777777f80011111111100088ff777777777fff8
0000000000000000000000000000000000000000000000000000000000000000000000000000000011111100777777ff880001111100008888fff77777ffff88
00000000000000000000000000000000000000000000000000000000000000000000000000000000801110088f777ff88880000000000888888ffffffffff888
000000000000000000000000000000000000000000000000000000000000000000000000000000008800008888ffff88888880000008888888888ffffff88888
__map__
0304030403040304030403040304030403040304030403040304030403040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1314131413141314131413141314131413141314131413141314131413140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0304030403040304030403040304030403040304030403040304030403040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1314131413141314131413141314131413141314131413141314131413140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0304030403040304030403040304030403040304030403040304030403040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1314131413141314131413141314131413141314131413141314131413140000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070807080708070807080d0d0d0d0d0d01020101090a01010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
171817181718171817180d0d0d0d0d0d11120101191a01010101010115010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07080708070807080d0d0d0d0d0d090a02010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17181718171817180d150d0d0d0d191a1201010101010101010b0c0101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1112090a010101020d021112010201020101020101010101011b1c0101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101191a01021101020102011101020102111201010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101111201110111120101090a1112010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01160101010201011101020111191a0101010102010601010101010501010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1112010111120102011112010211120101011112010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010b0c010101111201010201110102010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101011b1c010101010101110102011112010201010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010512010101111201010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101071818070101020101010101010b0c01010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0116010101010108090a070111120101010101011b1c01010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010107191a07010101010101010101010101010101010115010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010107070707010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101090a01010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101191a010101292a01012b01010101010101010101010101010101090a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01010101010101393a01012b01010101010101010101010101010101191a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
070100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000001f0521f0501f0501f0501f0501e1501e1501e1501e1501c2501c2501c2501d2501b3501b3501b3501c3501a4501a4501a450195501955019550195501665016650166501475014750147501475014750
__music__
01 41424344
01 01024344

