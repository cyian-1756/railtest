--revision 2
--worry about speed, worry about direction
--if it hits a t then swap the z with x direction
--if it hits a point where there is no rail in direction, check for t, then check for turn,
--when past center point of end rail, turn how far it is past the center into the turn (z to x) or (x to z)
--eventually make it so you can push them
--eventually make it so you can connect them
--make this mod totally physical, no clicking to move, etc, push it, or use control panel
--then do furnace carts to push as a starter, try to make this super in depth,
--rewrite this to use voxel manip, and open up a 3x3 box to do logic

--let's start off
--[[
the goal is

make a stick spawn a basic prototype of a minecart which uses moveto interpolated to give the illusion of movement
without creating extreme scenarios which can cause minecarts to go flying clientside,
just stopping via clientside until catchup, which is much neater and more digestable mentally
]]--

--Minecart prototype
--MAKE IT BASIC

--direction == pos - lastpos vector
--randomize turning for single carts?
--stop moveto if no rail at pos,and cancel whole collision detection if not on rail

dofile(minetest.get_modpath("railtest").."/funcs.lua")
dofile(minetest.get_modpath("railtest").."/carts/steam_powered_cart.lua")
dofile(minetest.get_modpath("railtest").."/carts/steam_train.lua")

minetest.register_craftitem("railtest:steam_powered_cart", {
	description = "Drivable cart",
	inventory_image = minetest.inventorycube("cart_top.png", "cart_side.png", "cart_side.png"),
	wield_image = "cart_side.png",

	on_place = function(itemstack, placer, pointed_thing)
		if not pointed_thing.type == "node" then
			return
		end
		if cart_func:is_rail(pointed_thing.under) then
			minetest.env:add_entity(pointed_thing.under, "railtest:steam_powered_cart_entity")
			if not minetest.setting_getbool("creative_mode") then
				itemstack:take_item()
			end
			return itemstack
		end
	end,
})

minetest.register_craftitem("railtest:steam_train", {
	description = "Drivable cart",
	inventory_image = minetest.inventorycube("cart_top.png", "cart_side.png", "cart_side.png"),
	wield_image = "cart_side.png",

	on_place = function(itemstack, placer, pointed_thing)
		if not pointed_thing.type == "node" then
			return
		end
		if cart_func:is_rail(pointed_thing.under) then
			minetest.env:add_entity(pointed_thing.under, "railtest:steam_train_entity")
			if not minetest.setting_getbool("creative_mode") then
				itemstack:take_item()
			end
			return itemstack
		end
	end,
})


minetest.register_tool("railtest:crowbar", {
        description = "Crowbar",
        inventory_image = "default_stick.png",
        tool_capabilities = {
            max_drop_level=3,
            groupcaps= {
                cracky={times={[1]=4.00, [2]=1.50, [3]=1.00}, uses=70, maxlevel=1}
            }
        },
})
