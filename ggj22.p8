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

BLUE_KEY = 0x01
RED_KEY = 0x02
GREEN_KEY = 0x04
YELLOW_KEY = 0x08

have_keys = 0

function get_key(x, y, key_bit)
	have_keys |= key_bit
	mset(x, y, 35)
	sfx(1)
end

GRAB_BLACK = 0b01
GRAB_WHITE = 0b10
GRAB_BOTH = 0b11

TILE_PROPS = {
	default = {},
	[  5] = {grab = GRAB_WHITE},
	[  6] = {grab = GRAB_BLACK},
	[ 22] = {grab = GRAB_BOTH},
	[ 95] = {collide_mask = YELLOW_KEY},
	[108] = {collide_mask = GREEN_KEY},
	[109] = {collide_mask = RED_KEY},
	[110] = {collide_mask = BLUE_KEY},
	[111] = {action = function(x, y) get_key(x, y, YELLOW_KEY) end},
	[124] = {action = function(x, y) get_key(x, y, GREEN_KEY) end},
	[125] = {action = function(x, y) get_key(x, y, RED_KEY) end},
	[126] = {action = function(x, y) get_key(x, y, BLUE_KEY) end},
	[127] = {collide_mask = 0},
}

function get_props(x, y)
	local tile = mget(x/8, y/8)
	return TILE_PROPS[tile] or TILE_PROPS.default
end

function collide_mask(x, y)
	local mask = get_props(x, y).collide_mask
	return mask and mask & have_keys == 0
end

function handle_corner(dot, px, py, dx, dy)
	if collide_mask(px, py) then
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
	if collide_mask(edge, dot.y1) then dot.x1 += -edge & 0x7.FFFF end
	local edge = dot.x1 + 4
	if collide_mask(edge, dot.y1) then dot.x1 -=  edge & 0x7.FFFF end
	local edge = dot.y1 - 4
	if collide_mask(dot.x1, edge) then dot.y1 += -edge & 0x7.FFFF end
	local edge = dot.y1 + 4
	if collide_mask(dot.x1, edge) then dot.y1 -=  edge & 0x7.FFFF end

	-- handle_corner(dot, dot.x1 - 4, dot.y1 + 4,  dot.x1 + (-(dot.x1 - 4) & -8),  dot.y1 - ( (dot.y1 + 4) & -8))
	handle_corner(dot, dot.x1 - 4, dot.y1 - 4,  ( dot.x1 & 0x7.FFFF),   ( dot.y1 & 0x7.FFFF))
	handle_corner(dot, dot.x1 + 4, dot.y1 - 4, -(-dot.x1 & 0x7.FFFF),   ( dot.y1 & 0x7.FFFF))
	handle_corner(dot, dot.x1 - 4, dot.y1 + 4,  ( dot.x1 & 0x7.FFFF),  -(-dot.y1 & 0x7.FFFF))
	handle_corner(dot, dot.x1 + 4, dot.y1 + 4, -(-dot.x1 & 0x7.FFFF),  -(-dot.y1 & 0x7.FFFF))
end

START_X, START_Y = 28, 20
dots = {
	{x0=START_X, y0=START_Y, x1=START_X, y1=START_Y, m_inv=1, grab = GRAB_WHITE},
	{x0=START_X, y0=START_Y, x1=START_X, y1=START_Y, m_inv=1, grab = GRAB_BLACK},
}

anchor, swing = dots[1], dots[2]
function _update60()
	local btn5 = btn(5)
	local btn5_down = btn5 and not _btn5
	local btn5_up = not btn5 and _btn5
	_btn5 = btn5

	if btn5_down then wants_to_grab = true end
	if btn5_up then wants_to_grab = false end

	local props = get_props(swing.x1, swing.y1)

	local grabable = props.grab
	local can_grab = band(grabable, swing.grab) != 0
	if wants_to_grab and can_grab then
		anchor, swing = swing, anchor
		anchor.x1 = (anchor.x1 & -8) + 4
		anchor.y1 = (anchor.y1 & -8) + 4

		wants_to_grab = false
		sfx(0)
	end

	-- Apply tile action
	if props.action then props.action(swing.x1/8, swing.y1/8) end

	anchor.x0 = anchor.x1
	anchor.y0 = anchor.y1
	anchor.m_inv = 0

	-- Apply movement.
	local x_inc = 0.04
	if btn(0) then swing.x1 -= x_inc end
	if btn(1) then swing.x1 += x_inc end

	local len_inc = 0.5;
	if btn(2) then rest_len -= len_inc else rest_len += len_inc end
	rest_len = max(16, min(rest_len, 32))

	dot_physics(swing)
	dot_collide(swing)
	swing.m_inv = 1

	-- Apply spring
	local btn4 = btn(4)
	local btn4_down = btn4 and not _btn4
	local btn4_up = not btn4 and _btn4
	_btn4 = btn4

	if btn4_down then
		sfx(2)
		spring_timeout = 10
	end

	if btn4 and spring_timeout > 0 then
		local dx = anchor.x1 - swing.x1
		local dy = anchor.y1 - swing.y1
		local len = sqrt(dx*dx + dy*dy)
		swing.x1 += dx*len/1000
		swing.y1 += dy*len/1000
		spring_timeout -= 1
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

	poke(0x5F36, 0x40) -- disable scrolling

	cursor(48, 112, 0)
	print("Use keys to\nunlock barriers")

	cursor(330, 100, 0)
	print("Some holds are\ncolor sensitive")

	if anchor.x1 == 60 and anchor.y1 == 276 then
		cursor(48, 316, 0)
		print("The end")
	end

	line(dot0.x1, dot0.y1, dot1.x1, dot1.y1, 8)
	palt(0x0080) -- Red transparent
	spr(122, dot0.x1 - 4, dot0.y1 - 4)
	spr(123, dot1.x1 - 4, dot1.y1 - 4)

	camera()
	cursor()
	if dbg_msg then print(dbg_msg) end
	-- print("x: "..flr(anchor.x1).." y: "..flr(anchor.y1))
	-- print(have_keys)
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
00000000ffffffff00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaa
000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaa
000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaa
000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaa
000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaa
000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaa
000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaa
000000005555555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaaaaaa
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbb88888888cccccccceeeeeeee
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbb88888888ccccccccefffffaf
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbb88888888cccccccceffffaaa
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbb88888888ccccccccaaaaaa6a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbb88888888ccccccccaaaaaa6a
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbb88888888ccccccccafafaaaa
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbb88888888ccccccccfffffeaf
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bbbbbbbb88888888ccccccccfffffeff
000000000000000000000000000000000000000000000000000000000000000000000000000000008855558888999988eeeeeeeeeeeeeeeeeeeeeeee55555555
000000000000000000000000000000000000000000000000000000000000000000000000000000008544445889aaaa98efffffbfefffff8fefffffcf55555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000544444459aaaaaa9effffbbbeffff888effffccc55555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000544444459aaaaaa9bbbbbb6b88888868cccccc6c55555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000544444459aaaaaa9bbbbbb6b88888868cccccc6c55555555
00000000000000000000000000000000000000000000000000000000000000000000000000000000544444459aaaaaa9bfbfbbbb8f8f8888cfcfcccc55555555
000000000000000000000000000000000000000000000000000000000000000000000000000000008544445889aaaa98fffffebffffffe8ffffffecf55555555
000000000000000000000000000000000000000000000000000000000000000000000000000000008855558888999988fffffefffffffefffffffeff55555555
f7314131413141314132323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323040304014302432323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323141314131613232326132323261323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7304030403014722432327232323272323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7314131413141323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323040304030403232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232f7
f7323141314131413232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232
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
7f36363604030403040304030403040304030403040304030414131413140e7f7f7f7f7f030403040304030403040304030403040304030403040304232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f3636161413141314131413141314131404030414131413141842232324412323232323131413141314131413141314131413141314131413141314232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2336271303040304031314131413030414131413141314423334232334232323232342232323070707072323230707070707072323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f363636071314131404420707071813143434343434343434231623232316232323231823236d230707422323234118180707232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f363636074113141314181834331818413434343434343434332723243427232323232323236d232323232323232323180707232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f363616230807080718182323232323233434343423233434232333232324332316232323236d232323232323232323232323232323230523232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f363627242324181834232323232323333434232323232334232324233334232327232323236d232323232323232323232323230523232723232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f333423246e6e6e6e3616362336162333341623232323232323237d232324232323242316236d231623232305232323062323232723232323052323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f363633346e24242436273623362723332327232333232323232323233334232333342327236d232723232327232323272323232323062323272323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f363616236e24162436363623363633233323232316232323232323232324232316232323236d232323232323232323232323162323272323232316232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f232427236e24272436362323363623333433232327232323232323233334232327232323236d232323232323232323232323272323232306232327232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f333423236e6e6e6e36362323363623232323232323242316232323232316242324232434236d232323232323232323232323232305232327232323230623232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f3623232335362323353623233636232323232323332323272323232333273433343334232323232323232323232323232323232327232323230523232723232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f3623162323232323242324233636232323232323232323232323162324232423242324232324232323232323232323232323232323231623232723232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f3433273334343423243334233634232323232323232323232323273334333433343334232324232323232323232323232323232323232723232323162323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f3433343334343434342323232323232323232323232323232324233334333433343334333334232323232323232323232323232323232323232323272323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f23242323243434342323242323243423232323232323232333342323246c6c6c242324232423232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f33347e34233434232323232324235f23232323332323232323231633346c1633343334333423232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f34343434343434343423233334235f23232323332323232323232723236c27232423242324232323232323232323232323232323232323232323237c2323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f34232423232324343434232323235f2323232333232323162324232333343433341634333423232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f34343423333334342434232323235f2323232323332323273334232323242323232723232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f33343434343434341634232416235f2316232323162323232323232323342323232323231623232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f33343423232334342723333427235f2327232323272323232323232323232323232323232723232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f24333433333334342324232423235f2308080807171723232323232323232323232323232323231623232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f23232323232323233334333433335f0834333423232308232323232323232323232307232323232723232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f07070707070707071607070707075f2323232323232323082323232323232323230723232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2323232323232323272323232323232323232323232323230808080808080808082323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2323232323232323232323162323232323232323232323232323232323232323232323232323236f23232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2323232323232323232323272323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f2323232323232323232323232323162323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
7f0304030403040304232323232323272323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323232323237f
__sfx__
070100003e670296701a6700d67003670136000360003600006000260000600266002360022600256001a6001b6001f6002160022600226002260021600216002060000600206002060020600206002060020600
000400003005230050300503005034050340503405034000340003401034010340101d0001b0001b3001b3001c3001a4001a4001a400195001950019500195001660016600166001470014700147001470014700
00010000180501d050200502305025050270502b0502d050310503305037050390502d0002e0002f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 41424344
01 01024344

