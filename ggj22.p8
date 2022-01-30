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
000000000000000000000000eeeeeeeeeeeeeeee0000000000000000eeeeeeee00000000ffffffffffffffffffffffffffffffff000000000000000000000000
000000000000000000000000effffffffeffffff0000000000000000e1f1f1f100000000ffffffffffffffffffffffffffffffff000000000000000000000000
000000000000000000000000effffffffeffffff0000000000000000ef1f1f1f00000000ffffffffffffffffffffffffffffffff000000000000000000000000
000000000000000000000000effffffffeffffff0000000000000000eff2f2ff00000000fffff777777ffffffffff777777fffff000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeee0000000000000000eeeeeeee00000000ffff77777777ffffffff77777777ffff000000000000000000000000
000000000000000000000000fffffeffffffffff0000000000000000ffffefff00000000fff7666666677ffffff7a777a7777fff000000000000000000000000
000000000000000000000000fffffeffffffffff0000000000000000ffffefff00000000ff748488886767ffffaaaaaaaaa7a7ff000000000000000000000000
000000000000000000000000fffffeffffffffff0000000000000000ffffefff00000000ff444444444866ffffaaaaaaaaaaa7ff000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeee00000000000000000000000000000000ff444444444488ffff9aaaaaaaaaaaff000000000000000000000000
000000000000000000000000efffffffffefffff00000000000000000000000000000000ff444444444444ffff99aaaaaaaaaaff000000000000000000000000
000000000000000000000000efffffffffefffff00000000000000000000000000000000ff244444444444ffff99aaaaaaaaaaff000000000000000000000000
000000000000000000000000efffffffffefffff00000000000000000000000000000000fff2244444444ffffff999aaaaaaafff000000000000000000000000
000000000000000000000000eeeeeeeeeeeeeeee00000000000000000000000000000000ffff22444444ffffffff99999aaaffff000000000000000000000000
000000000000000000000000fffffeffffffffef00000000000000000000000000000000fffff222244ffffffffff999999fffff000000000000000000000000
000000000000000000000000fffffeffffffffef00000000000000000000000000000000ffffffffffffffffffffffffffffffff000000000000000000000000
000000000000000000000000fffffeffffffffef00000000000000000000000000000000ffffffffffffffffffffffffffffffff000000000000000000000000
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
7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f
7f090a141314131413141314131413141314131413141314131413141314237f7f7f7f7f232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f191a040304030403040304030403040304030403040323242324232324237f7f7f7f7f232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f0808141314131413141314131413141314131413141333343334090a3423090a7f7f23232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f040304030403040323242324232423247f7f7f7f7f7f7f7f2323191a3423191a7f7f23232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f090a14070713071333343334333433347f7f7f7f7f7f7f7f33330808342308087f7f7f7f2323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f191a080708070823242323232323232327272727090a7f7f090a240707232323090a7f7f2323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f08081817181718333423232323232333090a3433191a7f7f191a241507232323191a7f7f2323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f080808070823242323232323090a3333191a243308087f7f080834270723232308087f7f7f7f232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f090a1817090a3423090a2323191a33330808343334237f7f23232323072323232323090a7f7f232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f191a2323191a2323191a23230808332324232423090a7f7f090a2323072323232323191a7f7f232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f080823237f7f23237f7f23232323233334333423191a7f7f191a232307232323232308087f7f232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f232323232727232327272323090a23232323232308087f7f080823230723232323232323090a232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f162323232323232323232323191a23232323232333237f7f232305230723232323232323191a232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2723242323232323242324230808232323232323090a7f7f090a272307232323232323230808232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f34333433340b0c23243334232323232323232323191a7f7f191a232307232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f34333433341b1c3334232323232323232323232308087f7f0808232307232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f232423242408082423232423232405232323232323237f7f2323232307232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f3334333423232323232323232423272323232333090a7f7f090a232307232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f16232423332308090a2323333423232323232333191a7f7f191a232307232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f27232423232307191a2323232323232323232333080827270808231517232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f3433342333231717232323232323232323232323232323232323232717232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f24090a2323232323232323232323232323232323232323232323232317232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f17191a232323292a23230707232323232323232323232323232323090a232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f070707070707393a07070707070707070707070717171717171717191a232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
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

