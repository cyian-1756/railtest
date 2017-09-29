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

cart_link = {}

local minecart   = {
	physical     = true,
	collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
	visual = "mesh",
	mesh = "cart.x",
	visual_size = {x=1, y=1},
	textures = {"cart.png"},
	automatic_face_movement_dir = 0.0,

	direction    = {x=0,y=0,z=0},
	speed        = 0, --dpt (distance per tick, speed measurement)
    -- The max amount of fuel this minecart can hold
    max_fuel = 2000,
}

-- A table containing each item that can be used as fuel and how much fuel it provides
local fuel_burn_time = {}
fuel_burn_time["default:coal_lump"] = 100
fuel_burn_time["default:coalblock"] = 900
fuel_burn_time["charcoal:charcoal_lump"] = 100
fuel_burn_time["charcoal:charcoal_block"] = 900


--punch function
function minecart.on_punch(self, puncher)
    if not puncher or not puncher:is_player() then
		return
	end

    if puncher:get_player_control().sneak then
		self.object:remove()
		local inv = puncher:get_inventory()
		if minetest.setting_getbool("creative_mode") then
			if not inv:contains_item("main", "railtest:cart") then
				inv:add_item("main", "railtest:cart")
			end
		else
			inv:add_item("main", "railtest:cart")
		end
		return
	end
end

--right click function
function minecart.on_rightclick(self, clicker)
	--sneak to link/fuel minecarts
	if clicker:get_player_control().sneak == true then
        local player_held_item = clicker:get_wielded_item():get_name()
        -- check if the item the player is holding is a fuel we can use
        if fuel_burn_time[player_held_item] ~= nil then
            if self.fuel + fuel_burn_time[player_held_item] <= minecart.max_fuel then
                self.fuel = self.fuel + fuel_burn_time[player_held_item]
                minetest.chat_send_player(clicker:get_player_name(), "[railtest] Train has " ..self.fuel.. " fuel")
                -- This work around is here because for some reason :take_item() doesn't work here
                local stack_total = clicker:get_wielded_item():get_count()
                clicker:set_wielded_item({name=player_held_item, count=stack_total - 1, wear=0, metadata=""})
                return
            else
                minetest.chat_send_player(clicker:get_player_name(), "[railtest] Adding this much fuel would go over the trains fuel limit")
                return
            end
        end
		if cart_link[clicker:get_player_name()] == nil then
			cart_link[clicker:get_player_name()] = self.object:get_luaentity()
		else
			self.leader = cart_link[clicker:get_player_name()]
			cart_link[clicker:get_player_name()] = nil
			self.speed     = 0.2
			minetest.chat_send_player(clicker:get_player_name(), "[railtest] Carts linked!")
		end
	else
		if self.player then
			self.player:set_detach()
            self.player = nil
		else
			self.speed = 0.0
            self.player = clicker
			clicker:set_attach(self.object, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
		end
	end
end

--when the minecart is created in world
function minecart.on_activate(self, staticdata, dtime_s)
	set_direction(self)
end

--what the minecart does in the world
function minecart.on_step(self, dtime)
	roll(self)
end

minetest.register_entity("railtest:minecart", minecart)



--how the minecart moves on the tracks
-- "cart logic"
function roll(self)
    -- Make sure fuel is never nil
    if self.fuel == nil then
        self.fuel = 0
    end

	local pos       = self.object:getpos()
	local direction = self.object:get_luaentity().direction
	local speed     = self.object:get_luaentity().speed
	local leader    = self.object:get_luaentity().leader
    local fuel      = self.fuel


	local x = math.floor(pos.x + 0.5)
	local y = math.floor(pos.y + 0.5) --the center of the node
	local z = math.floor(pos.z + 0.5)
	-----
	local speedx = pos.x + (direction.x * speed)
	local speedy = pos.y + (direction.y * speed) --the speed moveto uses to move the minecart
	local speedz = pos.z + (direction.z * speed)
	-----
	local movement  = {x=pos.x,y=pos.y,z=pos.z}

	--this is the prototype for carts to follow eachother
	for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 8)) do
		if object:is_player() == false then
			if leader ~= nil then
				if object:get_luaentity() == leader then
					--print("test")
					local pos2 = object:getpos()
					local difx = pos.x - pos2.x
					local difz = pos.z - pos2.z
					local distance = vector.distance(pos,pos2)
					--cancel the rest of the collision detection
					if distance < 1 then
						return
					end
					if direction.x > 0 then
						--calculate distance into speed
						if difx > 0 then
							direction.x = -1
						end
					elseif direction.x < 0 then
						--calculate distance into speed
						if difx < 0 then
							direction.x = 1
						end
					elseif direction.z > 0 then
						--calculate distance into speed
						if difz > 0 then
							direction.z = -1
						end
					elseif direction.z < 0 then
						--calculate distance into speed
						if difz < 0 then
							direction.z = 1
						end
					end
					--try to correct for t junction
					if math.abs(difx) < speed then
						direction.x = 0
						if difz > 0 then
							direction.z = -1
						elseif difz < 0 then
							direction.z = 1
						end
					elseif math.abs(difz) < speed then
						direction.z = 0
						if difx > 0 then
							direction.x  = -1
						elseif difx < 0 then
							direction.x = 1
						end
					end
				end
			end
		end
	end

    --local currentnode = minetest.get_node({x=x,y=y,z=z}).name
    local forwardnode = minetest.get_node({x=speedx,y=y,z=speedz}) --the node 1 space in front of it
    -- minetest.chat_send_player("singleplayer", forwardnode)
    local upnode      = minetest.get_node({x=speedx+(direction.x),y=speedy+1,z=speedz+(direction.z)})    --the node 1 space up + 1 space forwards
    local downnode    = minetest.get_node({x=pos.x+(direction.x/2),y=speedy-1,z=pos.z+(direction.z/2)})    --the node 1 space down + 1 space forwards
    local nodeahead   = minetest.get_node({x=pos.x+(direction.x/2),y=pos.y+(direction.y/2),z=pos.z+(direction.z/2)}) --1 rounded node ahead

	--move minecart down
	if is_rail(forwardnode) == false and is_rail(downnode) == true and direction.y == 0 then
		direction.y = -1
	elseif direction.y == -1 then
		movement = {x=speedx,y=speedy,z=speedz}
		--keep cart on center of rail
		if math.abs(direction.x) > 0 then
			movement.z = z
		elseif math.abs(direction.z) > 0 then
			movement.x = x
		end
		--when it gets to the bottom of the rail, stop moving down
		local noder = minetest.get_node({x=speedx,y=pos.y-0.5-(speed*2),z=speedz}).name
		if is_rail(noder) == false then
			direction.y = 0
		end
	--move minecart up
elseif is_rail(nodeahead) == true and is_rail(upnode) == true and direction.y == 0 then
		direction.y = 1
	elseif direction.y == 1 then
		movement = {x=speedx,y=speedy,z=speedz}
		--keep cart on center of rail
		if math.abs(direction.x) > 0 then
			movement.z = z
		elseif math.abs(direction.z) > 0 then
			movement.x = x
		end
		--when it gets to the top of the rail, stop moving up
        if is_rail(minetest.get_node({x=speedx+(direction.x),y=speedy+0.5,z=speedz+(direction.z)})) == false then
			direction.y = 0
		end
	--move the cart forwards
elseif is_rail(nodeahead) == true and is_rail(upnode) == false and direction.y == 0 or (is_rail(nodeahead) == false and is_rail(downnode) == true) then --and upnode ~= "default:rail" and is_rail(downnode) == false and direction.y == 0 then
		if math.abs(speedx) ~= 0 or math.abs(speedz) ~= 0 then
			movement = {x=speedx,y=speedy,z=speedz}
			--keep cart on center of rail
			if math.abs(direction.x) > 0 then
				movement.z = z
			elseif math.abs(direction.z) > 0 then
				movement.x = x
			end
		end
	--turn and handle T junctions
elseif is_rail(nodeahead) == false and is_rail(upnode) == false and is_rail(downnode) == false then
		if math.abs(direction.x) > 0 then
			local left  = minetest.get_node({x=pos.x,y=pos.y,z=pos.z + 1}).name
			local right = minetest.get_node({x=pos.x,y=pos.y,z=pos.z - 1}).name

			if left == "default:rail" then
				direction.x = 0
				direction.z = 1
			elseif right == "default:rail" then
				direction.x = 0
				direction.z = -1
			end
		elseif math.abs(direction.z) > 0 then
			local left  = minetest.get_node({x=pos.x + 1,y=pos.y,z=pos.z}).name
			local right = minetest.get_node({x=pos.x - 1,y=pos.y,z=pos.z}).name
			if left == "default:rail" then
				direction.x = 1
				direction.z = 0
			elseif right == "default:rail" then
				direction.x = -1
				direction.z = 0
			end
		end
	end

    -- If a player is currenting driving the train
    -- self.player is first set in on_rightclick
    if self.player then
        local ctrl = self.player:get_player_control()
        if ctrl.up and self.fuel > 0 then
            if speed == 0 then
                if self.traveling_forwards == false then
                    if direction.x == 1 then
                        direction.x = -1
                    elseif direction.x == -1 then
                        direction.x = 1
                    elseif direction.z == 1 then
                        direction.z = -1
                    elseif direction.z == -1 then
                        direction.z = 1
                    end
                    self.traveling_forwards = true
                end
            end
            -- The cart can only go 0.48 before it can no longer follow the tracks
            -- which is why 0.49 is the hardcoded max speed
            -- TODO make this a config option
            if speed + 0.01 < 0.49 and self.traveling_forwards == true and self.fuel > 0 then
                speed = speed + 0.01
            elseif self.traveling_forwards == false and self.fuel > 0 then
                -- Check speed to see if we should stop competely or not
                if 0 >= speed - 0.01 then
                    speed = 0
                else
                    speed = speed - 0.01
                end
            end
        elseif ctrl.down then
            -- Only change the direction if we're stopped
            if speed == 0 then
                if self.traveling_forwards == true then
                    if direction.x == 1 then
                        direction.x = -1
                    elseif direction.x == -1 then
                        direction.x = 1
                    elseif direction.z == 1 then
                        direction.z = -1
                    elseif direction.z == -1 then
                        direction.z = 1
                    end
                    self.traveling_forwards = false
                end
            end
            if speed + 0.01 < 0.49 and self.traveling_forwards == false and self.fuel > 0 then
                speed = speed + 0.01
            elseif self.traveling_forwards == true and self.fuel > 0 then
                -- Check speed to see if we should stop competely or not
                if 0 >= speed - 0.01 then
                    speed = 0
                else
                    speed = speed - 0.01
                end
            end
        end
    end
    if 0 >= self.fuel then
        -- If we have no fuel to burn start slowing down
        if speed > 0 then
            -- a check to see if we need to stop competely
            if 0 > speed - 0.003 then
                speed = 0
            else
                speed = speed - 0.003
            end
        end
    end
    if fuel > 0 then
        -- TODO Tweak fuel usage
        self.fuel = fuel - speed
    else
        if self.player then
            minetest.chat_send_player(self.player:get_player_name(), "[railtest] Cart is out of fuel!")
        end
        fuel = 0
    end
	self.object:get_luaentity().speed = speed
    self.object:get_luaentity().direction = direction
    self.object:moveto(movement)

end

--set the minecart's direction
function set_direction(self)
	local pos       = self.object:getpos()
	local left      = minetest.get_node({x=pos.x,y=pos.y,z=pos.z + 1}).name
	local right     = minetest.get_node({x=pos.x,y=pos.y,z=pos.z - 1}).name
	local forward   = minetest.get_node({x=pos.x + 1,y=pos.y,z=pos.z}).name
	local backward  = minetest.get_node({x=pos.x - 1,y=pos.y,z=pos.z}).name
    self.traveling_forwards = true
	local direction = {x=0,y=0,z=0}
	if is_rail(left) then
		direction.z = 1
	elseif right == "default:rail" then
		direction.z = -1
	elseif forward == "default:rail" then
		direction.x = 1
	elseif backward == "default:rail" then
		direction.x = -1
	end
	self.object:get_luaentity().direction = direction
end

minetest.register_craftitem("railtest:cart", {
	description = "Cart",
	inventory_image = minetest.inventorycube("cart_top.png", "cart_side.png", "cart_side.png"),
	wield_image = "cart_side.png",

	on_place = function(itemstack, placer, pointed_thing)
		if not pointed_thing.type == "node" then
			return
		end
		if cart_func:is_rail(pointed_thing.under) then
			minetest.env:add_entity(pointed_thing.under, "railtest:minecart")
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
        on_use = function(itemstack, player, pointed_thing)
            local nodename = minetest.get_node(pointed_thing.under).name
            if nodename == "default:rail" then
                minetest.add_entity(pointed_thing.under, "railtest:minecart")
            end
                end
})
