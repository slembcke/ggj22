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
	default = {},
	[  9] = {grab = GRAB_BOTH},
	[ 10] = {grab = GRAB_BOTH},
	[ 25] = {grab = GRAB_BOTH},
	[ 26] = {grab = GRAB_BOTH},
	[127] = {collide = true},
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

START_X, START_Y = 16, 16
dots = {
	{x0=START_X, y0=START_Y, x1=START_X, y1=START_Y, m_inv=1, grab = GRAB_BLACK},
	{x0=START_X, y0=START_Y, x1=START_X, y1=START_Y, m_inv=1, grab = GRAB_WHITE},
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
		sfx(0)
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
	local cx, cy = (dot0.x1 + dot1.x1)/2, (dot0.y1 + dot1.y1)/2
	camera(max(0, min(cx - 64, 128*7)), max(0, min(cy - 64, 128*3)))

	map(0, 0, 0, 0)
	line(dot0.x1, dot0.y1, dot1.x1, dot1.y1, 8)
	palt(0x0080) -- Red transparent
	spr(122, dot0.x1 - 4, dot0.y1 - 4)
	spr(123, dot1.x1 - 4, dot1.y1 - 4)

	camera()
	if dbg_msg then print(dbg_msg) end
end

__gfx__
000000006c6c6c6c6c6c6c6c33333b222b333332ee7777eeee7777ee3ff3ff3f553f3ff3eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeffffffff5555555500000000
00000000cccccccccccccccc2333b53235b33323f766667ff766667ff3ff3fff3ffff3ffffffffffefffffffffffffffefffffffffffffff5555555500000000
000000006ccccccccccccccc3533a35353a335337644446776aaaa673f35fffff3fffff3ffffffffefffffffffffffffefffffffffffffff5555555500000000
00000000cccccccccccccccc333b5332335b333344444444aaaaaaaaffff3f33ff3ff33ffffff677777ffffffffff7a7777fffffffffffff5555555500000000
000000006ccccccccccccccc333a3332333a333544444444aaaaaaaaff3ff5ff3f3f3fffeeee48667777eeeeeeeeaaaa7a77eeeeffffffff5555555500000000
00000000cccccccccccccccc53a533232335a35344444444aaaaaaaaf3f3fffff3f3ff33fff4444866677ffffffaaaaaa77a7fffffffffff5555555500000000
000000006ccccccccccccccc3a33323332333a33f244442ff9aaaa9f3fff3f335fffffffff444444486767ffffaaaaaaaaa7a7ffffffffff5555555500000000
00000000ccccccccccccccccb5335332335335b3f522225ff299992ff335fffffff3f3ffff444444444466ffffaaaaaaaaaaaaeeffffffff5555555500000000
000000006ccccccccccccccc2b33332323333b2bee1111eeee7777ee35fff3ffff3fff3fee444444444446eeee9aaaaaaaaaa7ff000000000000000000000000
00000000cccccccccccccccc3a33353335333a33f111111ff7a4a47fff3ff5f3f3fffff3ff444444444444ffff99aaaaaaaaaaff000000000000000000000000
000000006ccccccccccccccc33b333353333b333111111117a4a4a473fff3fff5ff3ff3fff244444444444ffff99aaaaaaaaaaff000000000000000000000000
00000000cccccccccccccccc33a333535333a33211111111a4a4a4a4ff3ff3f3f3ff33ffff622444444446ffff6999aaaaaaa6ff000000000000000000000000
000000006ccccccccccccccc335a3335333a5332111111114a4a4a4afff3ff5fff3ff53feeed22444444deeeeeed99999aaadeee000000000000000000000000
00000000cccccccccccccccc2335aa333aa5332311111111a4a4a4a4ff3f3fff3ff3fffff6f6d222244d6f6ff6f6d999999d6f6f000000000000000000000000
000000006ccccccccccccccc323322a3a2233233f111111ff949494f35fff3ff3ff53ff3ffff62111126ffffffff62111126ffff000000000000000000000000
00000000cccccccccccccccc3333332a23333333f211112ff594955ffff3fff3ff3fffffff6ff6d22d6ff6ffff6ff6d22d6ff6f6000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeeee222222222222222ee22222e0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000effffffffeffffffefed222222222defefed2def0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000effffffffeffffffeff6e66ddd66e6ffeff6e6ff0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000effffffffeffffffefffef66666fefffefffefff0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000fffffeffffffffffffffefffffffefffffffefff0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000fffffeffffffffffffffefffffffefffffffefff0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000fffffeffffffffffffffefffffffefffffffefff0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000efffffffffefffffefffffffffefffff000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000efffffffffefffffefffffffffefffff000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000efffffffffefffffefffffffffefffff000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000fffffeffffffffeffffffeffffffffef000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000fffffeffffffffeffffffeffffffffef000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000fffffeffffffffeffffffeffffffffef000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffb222222bffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000f7ffbbb22bbbff7f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007ab9bbb22bbb9ba700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aa999bbbbbb999aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000aaaa99fffa99aaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000f91a9bffffb9a19f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000f19aaa7f7aaaa91f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000001ffaa7fff7aaaff100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000885555888899998800000000000000000000000055555555
000000000000000000000000000000000000000000000000000000000000000000000000000000008544445889aaaa9800000000000000000000000055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000544444459aaaaaa900000000000000000000000055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000544444459aaaaaa900000000000000000000000055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000544444459aaaaaa900000000000000000000000055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000544444459aaaaaa900000000000000000000000055555555
000000000000000000000000000000000000000000000000000000000000000000000000000000008544445889aaaa9800000000000000000000000055555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000885555888899998800000000000000000000000055555555
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7
f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7
__map__
7f7f7f7f7f7f7f7f7f7f7f7f7f0e0e0e7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f
7f23242304030403040304030403040304030403040304030414131413140e7f7f7f7f7f030403040304030403040304030403040304030403040304232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f3316331413141314131413141314131404030414131413141842232324417f7f7f7f7f131413141314131413141314131413141314131413141314232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f23272424030403040313141314130304141314131413144233342324342323247f7f42232323070707072323230707070707072323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f333324071314131404420707071813147f7f7f7f7f7f7f7f23233305342333057f7f18232323230707422323234118180707232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f232424074113141314181834331818417f7f7f7f7f7f7f7f33332327342323277f7f7f7f2323232323232323232323180707232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f331633070807080718182323232323232526252623247f7f232433342324333423247f7f2323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f232723242324181834232323232323332323343316347f7f163424230634232306347f7f2323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f333423242324242323232423242333333316243327247f7f272434332724232327247f7f7f7f232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f232433233334342324333433340533332327343333347f7f3334232333342323333423247f7f232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f331623333416233334162323232733233334242323247f7f2324232323242323232305347f7f232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f23272323237f2323247f2323232423333433342333167f7f1634232333342323232327247f7f232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f333423233327233334272323243423232323232323277f7f2724232333232423242324342324232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f052323233536232335362333340523232323232333347f7f3334333433333433343334230634232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f272324232323232324232423232723232323232323247f7f2324232324232423242324232724232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f343334330623232424333423333423232323232316347f7f3316233334333433343334232324232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f343334332733333434232323232323232323232327247f7f2327233334333433343334333334232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f232423232423232323232423232405232323232333347f7f3334232324232423242324231623232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f333433052323242324232323242327232323233323247f7f2324233334333433343334333423232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f332324273333343334242333342323232323233323167f7f1624232323232423242324232423232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f3323242323232405333423232323232323232333232725262724231633333433343334333423232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f3433342333333427242323232323232323232323333435363334232723242323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2324052323232333342323242323232323232323232323232323232333342323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f3334272323230523242333342323232323232323232323232323230524232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2433333333332733342423242323242308080807171723232323232734232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2323232323232323333433343333080834333423232308232323232323232323232307232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f0707070707070707070707070707232323232323232323082323232323232323230723232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2323232323232323232323232323232323232323232323230808080808080808082323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
__sfx__
070100003e670296701a6700d67003670136000360003600006000260000600266002360022600256001a6001b6001f6002160022600226002260021600216002060000600206002060020600206002060020600
001000001f0521f0501f0501f0501f0501e1501e1501e1501e1501c2501c2501c2501d2501b3501b3501b3501c3501a4501a4501a450195501955019550195501665016650166501475014750147501475014750
__music__
01 41424344
01 01024344

