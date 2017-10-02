function is_rail(node)
    if node == nil then
        return false
    end
    local nn = node.name
    return minetest.get_item_group(nn, "rail") ~= 0
end

--set the minecart's direction
function set_direction(self)
    local pos       = self.object:getpos()
    local left      = minetest.get_node({x=pos.x,y=pos.y,z=pos.z + 1})
    local right     = minetest.get_node({x=pos.x,y=pos.y,z=pos.z - 1})
    local forward   = minetest.get_node({x=pos.x + 1,y=pos.y,z=pos.z})
    local backward  = minetest.get_node({x=pos.x - 1,y=pos.y,z=pos.z})
    self.traveling_forwards = true
    local direction = {x=0,y=0,z=0}
    if is_rail(left) then
        direction.z = 1
    elseif is_rail(right) then
        direction.z = -1
    elseif is_rail(forward) then
        direction.x = 1
    elseif is_rail(backward) then
        direction.x = -1
    end
    self.object:get_luaentity().direction = direction
end

-- Handles input from the player
function handle_input(self, direction, speed)
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
        if self.traveling_forwards == true then
            speed = increase_speed(0.01, speed, self)
        elseif self.traveling_forwards == false then
            -- Check speed to see if we should stop competely or not
            if 0 >= speed - 0.01 then
                speed = 0
            else
                speed = speed - 0.01
            end
        end
    elseif ctrl.down and self.fuel > 0 then
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
        if self.traveling_forwards == false then
            speed = increase_speed(0.01, speed, self)
        elseif self.traveling_forwards == true then
            -- Check speed to see if we should stop competely or not
            if 0 >= speed - 0.01 then
                speed = 0
            else
                speed = speed - 0.01
            end
        end
    elseif ctrl.jump and self.fuel > 0 then
        speed = decrease_speed(0.02, speed)
    end
    return speed, direction
end

function handle_rail_effects(self, fuel, speed, current_rail)
    if current_rail.name == "carts:brakerail" then
        speed = decrease_speed(0.005, speed)
    end
    return speed, fuel
end

--how the minecart moves on the tracks
-- "cart logic"
function roll(self)

    local pos       = self.object:getpos()
    local direction = self.object:get_luaentity().direction
    local speed     = self.object:get_luaentity().speed
    local leader    = self.object:get_luaentity().leader
    local fuel      = self.fuel
    -- The rail the cart is currently on
    local current_rail = minetest.get_node(pos)

    local x = math.floor(pos.x + 0.5)
    local y = math.floor(pos.y + 0.5) --the center of the node
    local z = math.floor(pos.z + 0.5)
    -----
    local speedx = pos.x + (direction.x * speed)
    local speedy = pos.y + (direction.y * speed) --the speed moveto uses to move the minecart
    local speedz = pos.z + (direction.z * speed)
    -----
    local movement  = {x=pos.x,y=pos.y,z=pos.z}

    -- --this is the prototype for carts to follow eachother
    -- for _,object in ipairs(minetest.env:get_objects_inside_radius(pos, 8)) do
    --     if object:is_player() == false then
    --         if leader ~= nil then
    --             if object:get_luaentity() == leader then
    --                 --print("test")
    --                 local pos2 = object:getpos()
    --                 local difx = pos.x - pos2.x
    --                 local difz = pos.z - pos2.z
    --                 local distance = vector.distance(pos,pos2)
    --                 --cancel the rest of the collision detection
    --                 if distance < 1 then
    --                     return
    --                 end
    --                 if direction.x > 0 then
    --                     --calculate distance into speed
    --                     if difx > 0 then
    --                         direction.x = -1
    --                     end
    --                 elseif direction.x < 0 then
    --                     --calculate distance into speed
    --                     if difx < 0 then
    --                         direction.x = 1
    --                     end
    --                 elseif direction.z > 0 then
    --                     --calculate distance into speed
    --                     if difz > 0 then
    --                         direction.z = -1
    --                     end
    --                 elseif direction.z < 0 then
    --                     --calculate distance into speed
    --                     if difz < 0 then
    --                         direction.z = 1
    --                     end
    --                 end
    --                 --try to correct for t junction
    --                 if math.abs(difx) < speed then
    --                     direction.x = 0
    --                     if difz > 0 then
    --                         direction.z = -1
    --                     elseif difz < 0 then
    --                         direction.z = 1
    --                     end
    --                 elseif math.abs(difz) < speed then
    --                     direction.z = 0
    --                     if difx > 0 then
    --                         direction.x  = -1
    --                     elseif difx < 0 then
    --                         direction.x = 1
    --                     end
    --                 end
    --             end
    --         end
    --     end
    -- end

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
        local noder = minetest.get_node({x=speedx,y=pos.y-0.5-(speed*2),z=speedz})
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
            local left  = minetest.get_node({x=pos.x,y=pos.y,z=pos.z + 1})
            local right = minetest.get_node({x=pos.x,y=pos.y,z=pos.z - 1})

            if is_rail(left) then
                direction.x = 0
                direction.z = 1
            elseif is_rail(right) then
                direction.x = 0
                direction.z = -1
            end
        elseif math.abs(direction.z) > 0 then
            local left  = minetest.get_node({x=pos.x + 1,y=pos.y,z=pos.z})
            local right = minetest.get_node({x=pos.x - 1,y=pos.y,z=pos.z})
            if is_rail(left) then
                direction.x = 1
                direction.z = 0
            elseif is_rail(right) then
                direction.x = -1
                direction.z = 0
            end
        end
    end

    -- If a player is currenting driving the train
    -- self.player is first set in on_rightclick
    if self.player then
        -- Handle any input from the player such as increase/decreasing speed
        speed, direction = handle_input(self, direction, speed)
    end

    if 0 >= self.fuel then
        -- If we have no fuel to burn start slowing down
        if speed > 0 then
            speed = decrease_speed(0.003, speed)
        end
    end

    -- Handle fuel usage
    if fuel > 0 then
        -- TODO Tweak fuel usage
        self.fuel = fuel - speed
    else
        if self.player then
            minetest.chat_send_player(self.player:get_player_name(), "[railtest] Cart is out of fuel!")
        end
        fuel = 0
    end

    -- Handles any effects the current rail might have on the cart (braking, refueling/charging, increasing speed ect)
    speed, fuel = handle_rail_effects(self, fuel, speed, current_rail)
    return speed, direction, movement, fuel
end

function handle_punch(self, puncher, minecart)
    if not puncher or not puncher:is_player() then
        return
    end
    if puncher:get_player_control().sneak then
        self.object:remove()
        local inv = puncher:get_inventory()
        if minetest.setting_getbool("creative_mode") then
            if not inv:contains_item("main", "railtest:" .. minecart.item_name) then
                inv:add_item("main", "railtest:" .. minecart.item_name)
            end
        else
            inv:add_item("main", "railtest:" .. minecart.item_name)
        end
    end
    if puncher:get_wielded_item():get_name() == "railtest:crowbar" then
        minetest.chat_send_player("singleplayer", "Speed")
        self.speed = increase_speed(0.05, speed, self)
        return self
    end
end

function decrease_speed(num, speed)
    if 0 > speed - num then
        return 0
    else
        return speed - num
    end
end

function increase_speed(num, speed, self)
    if speed + num > self.max_speed then
        return self.max_speed
    else
        return speed + num
    end
end

function handle_rightclick(self, clicker, fuel_burn_time)
    --sneak to link/fuel minecarts
    if clicker:get_player_control().sneak == true then
        local player_held_item = clicker:get_wielded_item():get_name()
        -- if fuel_burn_time[player_held_item] is nil then the player is right clicking when holding something that can't be used as fuel
        if fuel_burn_time[player_held_item] ~= nil then
            if self.fuel + fuel_burn_time[player_held_item] <= self.max_fuel then
                self.fuel = self.fuel + fuel_burn_time[player_held_item]
                minetest.chat_send_player(clicker:get_player_name(), "[railtest] Train has " ..self.fuel.. " fuel")
                -- This work around is here because for some reason :take_item() doesn't work here
                local stack_total = clicker:get_wielded_item():get_count()
                clicker:set_wielded_item({name=player_held_item, count=stack_total - 1, wear=0, metadata=""})
                return
            else
                minetest.chat_send_player(clicker:get_player_name(), "[railtest] Adding this much fuel would go over the trains max fuel")
                return
            end
        end
        if cart_link[clicker:get_player_name()] == nil then
            cart_link[clicker:get_player_name()] = self.object:get_luaentity()
        else
            self.leader = cart_link[clicker:get_player_name()]
            cart_link[clicker:get_player_name()] = nil
            -- TODO set the speed of linked carts to that of the leading cart
            self.speed     = 0.2
            minetest.chat_send_player(clicker:get_player_name(), "[railtest] Carts linked!")
        end
    elseif clicker:get_wielded_item():get_name() ~= "railtest:crowbar" then
        if self.player then
            self.player:set_detach()
            self.player = nil
        else
            self.player = clicker
            clicker:set_attach(self.object, "", {x=0,y=0,z=0}, {x=0,y=0,z=0})
        end
    elseif clicker:get_wielded_item():get_name() == "railtest:crowbar" then
        minetest.chat_send_player("singleplayer", "Speed")
        self.speed = decrease_speed(0.05, speed, self)
        return self
    end
    return self
end

function add_spawn_item(minecart)
    minetest.register_craftitem("railtest:" .. minecart.item_name, {
        description = minecart.description,
        inventory_image = minecart.inventory_image,
        wield_image =  minecart.wield_image,

        on_place = function(itemstack, placer, pointed_thing)
            if not pointed_thing.type == "node" then
                return
            end
            if cart_func:is_rail(pointed_thing.under) then
                minetest.env:add_entity(pointed_thing.under, "railtest:" .. minecart.item_name .. "_entity")
                if not minetest.setting_getbool("creative_mode") then
                    itemstack:take_item()
                end
                return itemstack
            end
        end,
    })
end
