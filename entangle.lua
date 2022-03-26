-- title: Elden Martins
-- author: Scrum Monkeys
-- desc:   The adventures and puzzles of a young Joe Martins
-- script: lua


--------------- CONSTANTS ----------------
btiles = {
		empty = 0,
  map_player = 34,
  goal = 33, 
  wall = 32,
  rock_min = 1,
  rock_max = 15
}

ftiles = {
	player = {
		260, --up
		261, --down
		259, --left (flipped)
	 259  --right
	},

	pick = 258
}

screenw = 240
screenh = 136

----------------- MAIN --------------------

t=0
cur_lvl = 1

-- pick is a stack
lvls = {
	{ent = 2, pick = {5, 5, 5}}
}

p = {
	ent = 0,
	pick = {},
 x = 0,
 y = 0,
	dirx = 0,
 diry = 0,
 look = 0, -- up < down < left < right
 entang = false,
 curr_entang = nil
}

entangs = {}

function TIC()
				
				if (t == 0) then
					load_level(cur_lvl)
				end
				
				input();
				update();
				render();
    
    t=t+1
end

function input()
	p.diry = 0
 p.dirx = 0
 p.entang = false
 p.break_block = false
	
	if btnp(4) then p.entang = true end
	if btnp(5) then p.break_block = true end

	if btnp(0) then
		p.diry = -1
		p.look = 0 
		return --up
	end
	if btnp(1) then
		p.diry = 1 
		p.look = 1
		return --down
	end
	if btnp(2) then
		p.dirx = -1
		p.look = 2
		return --left
	end
	if btnp(3) then
		p.dirx = 1
		p.look = 3
		return --right
	end
	
end

------------------ UPDATE --------------

function update()

	local newx = p.x + p.dirx
	local newy = p.y + p.diry
	
	if newx ~= p.x or newy ~= p.y then
		
		local tile = mget(newx, newy)
		
		if (
			handleGoalTile(tile, newx, newy)
			or handleEmptyTile(tile, newx, newy)
		) then end
		
	else 
			local lookTile = getLookTile()
			
			tile = mget(lookTile[1], lookTile[2])
			
		if (handleEntang(tile, lookTile[1], lookTile[2])
			or handleRockTile(tile, lookTile[1], lookTile[2])
		)
			 then end 
	end

end

function handleRockTile(tile, newx, newy)
	if not p.break_block then return false end
	
	if tile >= btiles.rock_min and tile <= btiles.rock_max then

			if #p.pick > 0 then
				local cur_pick = p.pick[#p.pick]
				
				if cur_pick >= tile then
					p.pick[#p.pick] = nil
					mset(newx, newy, btiles.empty)
					
					if p.curr_entang ~= nil and isTablesEqual(p.curr_entang, {newx, newy}) then
						p.curr_entang = nil
					end
					
					local broke = false
					
					for i = 1, #entangs do
						for j = 1, #(entangs[i]) do
							if isTablesEqual(entangs[i][j], {newx, newy}) then
								-- remove all tiles in the entanglement that contains this tile
								for k = 1, #entangs[i] do
									mset(entangs[i][k][1], entangs[i][k][2], btiles.empty)			
								end
								
								table.remove(entangs, i)
								
								broke = true
								break	
							end
						end
						if broke then break end
					end
					
				end
			end
			
			return true
		end
		
		return false
end

function handleGoalTile(tile, newx, newy)
	if tile == btiles.goal then
		p.x = newx
		p.y = newy
		
		mset(newx, newy, btiles.empty)
		
		-- do win
		
		return true
	end
			
	return false
end

function handleEmptyTile(tile, newx, newy)

	if tile == btiles.empty then
		p.x = newx
		p.y = newy
		
		return true
	end
			
	return false
end


function handleEntang(tile, x, y)
  if not (p.entang == true and p.ent > 0) then return false end
		if tile >= btiles.rock_min and tile <= btiles.rock_max then
			if p.curr_entang == nil then
				p.curr_entang = {x,y}
			else 
				if	not isTablesEqual(p.curr_entang, {x,y}) then
					if not isInEntang({x,y}) then
						entangs[#entangs + 1] = {p.curr_entang,{x,y}}
						p.curr_entang = nil
						p.ent = p.ent - 1
					end
				else
					p.curr_entang = nil
				end
			end
		end
end

function isInEntang(tileCoords)
	for i = 1, #entangs do
		for j = 1, #entangs[i] do
			if isTablesEqual(entangs[i][j], tileCoords) then
				return true
			end
		end
	end
	return false
end

function getLookTile()
	if p.look == 0 then return {p.x, p.y - 1} end
	if p.look == 1 then return {p.x, p.y + 1} end
	if p.look == 2 then return {p.x - 1, p.y} end
	if p.look == 3 then return {p.x + 1, p.y} end
end

--------------- RENDERING ---------------------
 
function render()

 map(0, 0, 30, 17)
	drawPlayer()
	drawEntangs()
	hud()

end

function drawPlayer()
	 
	local flip = 0
	if p.look == 2 then flip = 1 end
	spr(ftiles.player[p.look + 1], p.x * 8, p.y * 8, 0, 1, flip)
end

function drawEntangs()
	if p.curr_entang ~= nil then
		rectb(p.curr_entang[1] * 8, p.curr_entang[2] * 8, 8, 8, 1)
	end
	
	for i = 1, #entangs do
		rectb(entangs[i][1][1] * 8, entangs[i][1][2] * 8, 8, 8, (i + 1)%15)
		rectb(entangs[i][2][1] * 8, entangs[i][2][2] * 8, 8, 8, (i + 1)%15)
	end
end
 
function hud()

	rect(0, 0, screenw, 8, 6)
	print("Level " .. tostring(cur_lvl), 2, 2)

	spr(ftiles.pick, 80, 0, 0)
	
	local	pick_values

	if #p.pick > 0 then
		pick_values = "[ "
	else
	 pick_values = ""
	end
		
	for k, v in pairs(p.pick) do
		pick_values = pick_values .. tostring(v) .. " "
		if k == 1 then
			pick_values = pick_values .. "] "
		end
	end
	print(pick_values, 90, 2)
	
	-- TODO: replace text with icon
	reversePrint("Entanglements: " .. p.ent, 0, 2)
	
end


----------- LEVELS ----------------

function load_level(lvl)
	-- Load lvl properties
	local lvl_data = lvls[lvl]
	p.ent = lvl_data.ent
	p.pick = table.copy(lvl_data.pick)


	-- Copy map
	local mapx = 30 * (lvl % 8)
	local mapy = 17 * (lvl // 8)
	
	for i = mapx, mapx + 30 do
		for j = mapy, mapy + 17 do
			tile = mget(i, j)
			worldx = i % 30
			worldy = j % 17
			mset(worldx, worldy, tile)
			
			if tile == btiles.map_player then
				p.x = worldx
				p.y = worldy
				
				mset(worldx, worldy, btiles.empty)
			end
		end
	end

end










---------------- UTILS ---------------
function table.copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end


-- !!!Does not work with nested lists!!!
function isTablesEqual(list1, list2)
	if #list1 ~= #list2 then return false end
	
	for i = 1, #list1 do
		if list1[i] ~= list2[i] then
			return false
		end	
	end
	
	return true
end

function reversePrint(text, x, y, color, fixed, scale, smallfont) 
 color = color or 15
 fixed = fixed or false
 scale = scale or 1
 smallfont = smallfont or false
 local width = print(text, 0, -30, color, fixed, scale, smallfont)
 print(text, (240 - width - x), y, color, fixed, scale, smallfont)
end
-- <TILES>
-- 001:eecddcccee2221cdc21121dddccc21ccddcd21cccccc21edc222221cecddcccc
-- 002:eecddcccee22221dc21cc21ddccc221cddc221ccc22cdeedc222221cecddcccc
-- 003:eecddcccee2222cdc2cce21ddcc221ccddcdd21cc2ccd21dcd2221ccecddcccc
-- 004:eecddcccee22decdcc2ceeddd21c2cccd222221ccccc21edcdc221ccecddcccc
-- 005:eecddccce222221dc221eeddd2221cccddcd221cccccd22dc22221ccecddcccc
-- 006:eecddcccee2221cdc221eeddd22221ccd2cdd21cc2ccde2dc222222cecddcccc
-- 007:eecddccce222222dc222222ddccc221cddcd22ccccc221edcdc221ccecddcccc
-- 008:eecddcccee22221dc2cce21ddc2222ccd2cdd21cc2ccd21dcd2221ccecddcccc
-- 009:eecddccce222221dc2cce21dd222221cddcdd21ccccc21edcdc21eccecddcccc
-- 010:eecddcccee2222cdcc21e2dddc21c2ccd222221cc2ccd21dc2cce21cecddcccc
-- 011:eecddccce22221cdc2cc21ddd22221ccd2cdd21cc2ccd21dc222221cecddcccc
-- 012:eecddcccee22221dc21ceeddd21cccccd21ddeccc21cdeedcd22221cecddcccc
-- 013:eecddccce22221cdc21ce21dd21cc21cd21dd21cc21cd21dc22221ccecddcccc
-- 014:eecddccce222221dc21ceeddd2221cccd22221ccc21cdeedc222221cecddcccc
-- 015:eecddccce222221dc21ceeddd21cccccd2221eccc21cdeedc21ceeccecddcccc
-- 032:eecddccceeccdecdcccceedddcccccccddcddeccccccdeedcdcceeccecddcccc
-- 033:00000000444444440777bbb007a77ab000a77a0000aa7a0000777b0000000000
-- 034:07555570055ab55005abaa5005baaa5005555550055775500550055005500550
-- 035:d0000dc0cc000c0000000000cdc00ddcdd0000dd0000000c00c0dc000d00dcc0
-- 048:07555570055ab55005abaa5005baaa5005555550055775500550055005500550
-- 049:0055550000aa550000aa55000055550000555500007755000077550000775500
-- 090:04bbb0000bc4c0000bbcc000044c990000aaa9900009a00000099aa000000099
-- 128:dddddddddcccccccdcccccccdcccccccdcccccccdcccccccdcccccccdddddddd
-- 129:ddddddddccccccccccccccccccccccccccccccccccccccccccccccccdddddddd
-- 136:eecddccce222222dc22ce22dd22cc22cd22dd22cc22cd22dc222222cecddcccc
-- 137:eecddcccee2222cdc22222dddccc22ccddcd22cccccc22edc222222cecddcccc
-- 138:eecddcccee22222dc22cc22ddcccc22cddc222ccc22cdeedc222222cecddcccc
-- 139:eecddcccee2222cdc2cce22ddcc222ccddcdd22cc2ccd22dcd2222ccecddcccc
-- 140:eecddccce666666dc66ce66dd66cc66cd66dd66cc66cd66dc666666cecddcccc
-- 141:eecddcccee6666cdc66666dddccc66ccddcd66cccccc66edc666666cecddcccc
-- 142:eecddcccee66666dc66cc66ddcccc66cddc666ccc66cdeedc666666cecddcccc
-- 143:eecddcccee6666cdc6cce66ddcc666ccddcdd66cc6ccd66dcd6666ccecddcccc
-- 144:0000000000111000011100001122100012321100124311101124211001111100
-- 145:0001100000001000001100000111110011231110112331101124211001111110
-- 146:0000000000001100000001100000121000112310011223100112441001111110
-- 147:0055660006555660556666555556655606666660000cc0000dedddc00dedddc0
-- 152:eecddcccee22decdcc2ceeddd22c2cccd222222ccccc2eedcdc22eccecddcccc
-- 153:eecddccce222222dc22ceeddd222ccccddcd22ccccccd22dc22222ccecddcccc
-- 154:eecddcccee222ecdc22ceeddd2222cccd2cdd22cc2ccde2dc222222cecddcccc
-- 155:eecddccce222222dc222222ddccc22ccddcd22ccccc22eedcdc22eccecddcccc
-- 156:eecddcccee66decdcc6ceeddd66c6cccd666666ccccc6eedcdc66eccecddcccc
-- 157:eecddccce666666dc66ceeddd666ccccddcd66ccccccd66dc66666ccecddcccc
-- 158:eecddcccee666ecdc66ceeddd6666cccd6cdd66cc6ccde6dc666666cecddcccc
-- 159:eecddccce666666dc666666ddccc66ccddcd66ccccc66eedcdc66eccecddcccc
-- 168:eecddcccee2222cdc2ccee2ddc2222ccd2cdde2cc2ccde2dcd2222ccecddcccc
-- 169:eecddccce222222dc2ccee2dd222222cddcdd22ccccc22edcdc22eccecddcccc
-- 170:eecddcccee2222cdcc2ce2dddc2cc2ccd222222cc2ccde2dc2ccee2cecddcccc
-- 171:eecddccce2222ecdc2cce2ddd22222ccd2cdde2cc2ccde2dc22222ccecddcccc
-- 172:eecddcccee6666cdc6ccee6ddc6666ccd6cdde6cc6ccde6dcd6666ccecddcccc
-- 173:eecddccce666666dc6ccee6dd666666cddcdd66ccccc66edcdc66eccecddcccc
-- 174:eecddcccee6666cdcc6ce6dddc6cc6ccd666666cc6ccde6dc6ccee6cecddcccc
-- 175:eecddccce6666ecdc6cce6ddd66666ccd6cdde6cc6ccde6dc66666ccecddcccc
-- 184:eecddcccee22222dc2cceeddd2ccccccd2cddeccc2ccdeedcd22222cecddcccc
-- 185:eecddccce22222cdc2ccee2dd2cccc2cd2cdde2cc2ccde2dc22222ccecddcccc
-- 186:eecddccce222222dc2cceeddd222ccccd2222eccc2ccdeedc222222cecddcccc
-- 187:eecddccce222222dc22ceeddd22cccccd2222eccc22cdeedc22ceeccecddcccc
-- 188:eecddcccee66666dc6cceeddd6ccccccd6cddeccc6ccdeedcd66666cecddcccc
-- 189:eecddccce66666cdc6ccee6dd6cccc6cd6cdde6cc6ccde6dc66666ccecddcccc
-- 190:eecddccce666666dc6cceeddd666ccccd6666eccc6ccdeedc666666cecddcccc
-- 191:eecddccce666666dc66ceeddd66cccccd6666eccc66cdeedc66ceeccecddcccc
-- 204:eecddccce666667dc67ce67dd67cc67cd67dd67cc67cd67dc666667cecddcccc
-- 205:eecddcccee6667cdc67767dddccc67ccddcd67cccccc67edc666667cecddcccc
-- 206:eecddcccee66667dc67cc67ddccc667cddc667ccc66cdeedc666667cecddcccc
-- 207:eecddcccee6666cdc6cce67ddcc667ccddcdd67cc6ccd67dcd6667ccecddcccc
-- 208:0444ffdd000ff4fc00004f98000dc98800dcc0890dcc0009dcc00008dc000000
-- 220:eecddcccee66decdcc6ceeddd67c6cccd666667ccccc67edcdc667ccecddcccc
-- 221:eecddccce666667dc667eeddd6667cccddcd667cccccd66dc66667ccecddcccc
-- 222:eecddcccee6667cdc667eeddd66667ccd6cdd67cc6ccde6dc666666cecddcccc
-- 223:eecddccce666666dc666666ddccc667cddcd66ccccc667edcdc667ccecddcccc
-- 224:000fff4400f44444000008ff0000000900000000000000000000000d000000cd
-- 225:44ff0dddffff4ddcff44f8c0844ff8809fff8988ddf8988fddc988ffccc99fff
-- 236:eecddcccee66667dc6cce67ddc6666ccd6cdd67cc6ccd67dcd6667ccecddcccc
-- 237:eecddccce666667dc6cce67dd666667cddcdd67ccccc67edcdc67eccecddcccc
-- 238:eecddcccee6666cdcc67e6dddc67c6ccd666667cc6ccd67dc6cce67cecddcccc
-- 239:eecddccce66667cdc6cc67ddd66667ccd6cdd67cc6ccd67dc666667cecddcccc
-- 240:00000ddc0000ddcc000cdccc00ddccc0dddccc00dddcc000dccc0000cccc0000
-- 241:cc009ff8c00009f8000009890000008900000099000000900000000000000000
-- 242:eecddccce222221dc21ce21dd21cc21cd21dd21cc21cd21dc222221cecddcccc
-- 252:eecddcccee66667dc67ceeddd67cccccd67ddeccc67cdeedcd66667cecddcccc
-- 253:eecddccce66667cdc67ce67dd67cc67cd67dd67cc67cd67dc66667ccecddcccc
-- 254:eecddccce666667dc67ceeddd6667cccd66667ccc67cdeedc666667cecddcccc
-- 255:eecddccce666667dc67ceeddd67cccccd6667eccc67cdeedc67ceeccecddcccc
-- </TILES>

-- <SPRITES>
-- 000:0422000004444117057700113322267b3322270a322223000eedd0000e00d000
-- 001:042211170444461b0577076a0222233a0332220003322ddd03ee00000e000000
-- 002:0444ffdd000ff4fc00004f98000dc98800dcc0890dcc0009dcc00008dc000000
-- 003:00ee30000dea70000dd770000555550007555700077557000772170000201000
-- 004:00eee00000eee0000ddddd000555550007555700075557000722170000201000
-- 005:00e3e00000a7a0000d777d000555550007555700075557000722170000201000
-- 016:04220117044440113377067b3322270a322223000eedd0000e00d00000000000
-- 032:04444117046606113322277b3222230a3eed23000e0dd000e00d000000000000
-- 064:0443333001311310013333100023320000011000000110000033220004333330
-- 065:00000000444444440777bbb007a77ab000a77a0000aa7a0000777b0000000000
-- 066:000000000ffffff00fbbbbf00ffffff00fbbbbf00f0000f00ffffff000000000
-- </SPRITES>

-- <MAP>
-- 005:000000000000000000000000000000000000000000000000000000000000000000000000000000000000020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:000000000000000000000000000000000000000000000000000000000000000000000000000000000002021202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:000000000000000000000000000000000000000000000000000000000000000000000000000000000002405070020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000000000000000000000000000000000000000000000000000000000000000000000000000000000002206080020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:000000000000000000000000000000000000000000000000000000000000000000000000000000000002002200020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:000000000000000000000000000000000000000000000000000000000000000000000000000000000002020202020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <PALETTE>
-- 000:000014b31909c55510e4c719e9dbc065a65f448244c5a4868b9c9d6475862f1559745765430e276b273b862639c5b5b5
-- </PALETTE>

