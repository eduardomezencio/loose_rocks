-- Copyright 2015 Eduardo Mezêncio

-- Node Registration

local rocks_variants = 2

local function register_loose_rocks(index)
	local rocks_groups = {oddly_breakable_by_hand = 3, attached_node = 1}
	if index == 1 then
		rocks_groups.not_in_creative_inventory = 0
	else
		rocks_groups.not_in_creative_inventory = 1
	end
	minetest.register_node("loose_rocks:loose_rocks_"..index, {
		description = "Loose Rocks",
		drawtype = "mesh",
		drop = "loose_rocks:loose_rocks_1",
		groups = rocks_groups,
		inventory_image = "loose_rocks_inv.png",
		mesh = "loose_rocks_" .. index ..".obj",
		on_place = function(itemstack, placer, pointed_thing)
			local pointed_pos = minetest.get_pointed_thing_position(pointed_thing, true)
			local return_value = minetest.item_place(itemstack, placer, pointed_thing, math.random(0,3))
			if minetest.get_node(pointed_pos).name == "loose_rocks:loose_rocks_1" then
				minetest.set_node(pointed_pos, {name = "loose_rocks:loose_rocks_"..math.random(1,rocks_variants),
				                                param2 = math.random(0,3)})
			end
			return return_value
		end,
		paramtype = "light",
		paramtype2 = "facedir",
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, -0.3125, 0.5},
		},
		sunlight_propagates = true,
		tiles = {"default_stone.png"},
		walkable = false,
	})
end

for i=1, rocks_variants do
	register_loose_rocks(i)
end

-- Crafts

minetest.register_craft({
	output = "default:cobble",
	recipe = {
		{"loose_rocks:loose_rocks_1", "loose_rocks:loose_rocks_1", ""},
		{"loose_rocks:loose_rocks_1", "loose_rocks:loose_rocks_1", ""},
		{"", "", ""},
	}
})

minetest.register_craft({
	output = "loose_rocks:loose_rocks_1 4",
	recipe = {
		{"default:cobble", "", ""},
		{"", "", ""},
		{"", "", ""},
	}
})

-- Map Generation

minetest.register_on_generated(function(minp, maxp, seed)
	if maxp.y >= 0 and maxp.y < 200 then
		math.randomseed(seed)
		-- Generate rocks
		local perlin1 = minetest.get_perlin(666, 3, 0.6, 100)
		-- Assume X and Z lengths are equal
		local divlen = 32
		local divs = (maxp.x-minp.x)/divlen;
		for divx=0,divs do
		for divz=0,divs do
			local x0 = minp.x + math.floor((divx+0)*divlen)
			local z0 = minp.z + math.floor((divz+0)*divlen)
			local x1 = minp.x + math.floor((divx+1)*divlen)
			local z1 = minp.z + math.floor((divz+1)*divlen)

			-- Determine amount of rocks from perlin noise
			local amount = math.floor((perlin1:get2d({x=x0, y=z0}) + 1) ^ 3)

			-- Find random positions for rocks
			for i=1,amount do
				local x = math.random(x0, x1)
				local z = math.random(z0, z1)

				-- Find ground level
				local ground_y = nil
				local start_y=120
				if maxp.y < 120 then start_y = maxp.y end
				if minetest.get_node({x=x,y=start_y,z=z}).name ~= "air" then break end
				for y=start_y, minp.y, -1 do
					local name = minetest.get_node({x=x,y=y,z=z}).name
					if name ~= "air" then
						if (minetest.get_item_group(name, "crumbly") ~= 0) or
						   (minetest.get_item_group(name, "cracky") ~= 0) then
							ground_y = y
							break
						end
					end
				end

				if ground_y then
					local target_coord = {x=x,y=ground_y+1,z=z}
					local target_name = minetest.get_node(target_coord).name

					-- Check if the node can be replaced
					if minetest.registered_nodes[target_name] and
					   minetest.registered_nodes[target_name].buildable_to and
					   (minetest.get_item_group(target_name, "liquid") == 0) then
						minetest.set_node(target_coord,{name = "loose_rocks:loose_rocks_"..math.random(1,rocks_variants),
						                                param2 = math.random(0,3)})
					end
				end

			end
		end
		end
	end
end)
