pico-8 cartridge // http://www.pico-8.com
version 35
__lua__

function rope_physics(dot0, dot1)
	local rest_len = 32
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

dots = {
	{x0=32, y0=64, x1=32, y1=64, m_inv=1},
	{x0=96, y0=64, x1=96, y1=64, m_inv=1},
}

anchored = 0

function _update60()
	local anchor = dots[1]
	anchor.x0 = anchor.x1
	anchor.y0 = anchor.y1
	anchor.m_inv = 0

	local swing = dots[2]
	dot_physics(swing)
	swing.m_inv = 1

	local inc = 0.02
	if btn(0) then swing.x1 -= inc end
	if btn(1) then swing.x1 += inc end
	if btn(2) then swing.y1 -= inc end
	if btn(3) then swing.y1 += inc end

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

	local dot0, dot1 = dots[1], dots[2]
	camera(
		(dot0.x1 + dot1.x1)/2 - 64,
		(dot0.y1 + dot1.y1)/2 - 64
	)

	map(0, 0, 0, 0)
	line(dot0.x1, dot0.y1, dot1.x1, dot1.y1, 5)
	circfill(dot0.x1, dot0.y1, 4, 0)
	circfill(dot1.x1, dot1.y1, 4, 7)
end

__gfx__
000000006c6c6c6c6c6c6c6c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000006ccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000006ccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000006ccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000006ccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000006ccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000006ccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000006ccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cccccccccccccccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
1112010201010201010101010201010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102111201111201010201111201010201020101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1112010101010201111201020102111211120101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010201111201020111121101020101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101111201020111120101020111120101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102010111120101010211120102010201010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1112010101020101111201011112111201020101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020111120101020102010102010111120101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0111120102010211121112011112010102010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102011112111201010101020101011112010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1112010201010102010211120102010201010201010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101111201021101020102011101020102111201010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010111120111011112010111121112010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101020101110102011101020101010102010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010111120102011112010211120101011112010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101011112010101111201010201110102010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101110102011112010201010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101011112010101111201010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010102010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101011112010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
