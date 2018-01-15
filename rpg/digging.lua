--[[

This files takes care of the digging and EXP adding.

by Ryan Dang

--]]

-- checks for which exp to assign
minetest.register_on_dignode(function(pos, oldnode, digger)

	local tool = digger:get_wielded_item():get_name()
	
	-- checking for axe exp
	-- node must be tree
	if string.find(oldnode.name, "tree") then
		-- digger must be holding axe
		if minetest.get_item_group(tool, "axe") >= 1 then
			rpg.addXP(digger, "axe", 1)
		end
	end
	
	-- checking for mining exp
	-- digger must be holding pickaxe
	if minetest.get_item_group(tool, "pickaxe") >= 1 then
		local xp = 0
		if oldnode.name == "default:stone" then
			xp = 1
		elseif oldnode.name == "default:stone_with_coal" then
			xp = 2
		elseif oldnode.name == "default:stone_with_iron" then
			xp = 5
		elseif oldnode.name == "default:stone_with_copper" then
			xp = 4
		elseif oldnode.name == "default:stone_with_tin" then
			xp = 4
		elseif oldnode.name == "default:stone_with_gold" then
			xp = 10
		elseif oldnode.name == "default:stone_with_mese" then
			xp = 8
		elseif oldnode.name == "default:stone_with_diamond" then
			xp = 20
		end
			
		if(xp > 0 ) then
			rpg.addXP(digger, "mining", xp)
		end
	end
	
	-- checking for digging exp
	-- digger must be holding shovel
	if minetest.get_item_group(tool, "shovel") >= 1 then
		if rpg_tools.diggable(oldnode.name) then
			rpg.addXP(digger, "digging", 1)
		end
	end
end)