local minecart   = {
    physical     = true,
    collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
    visual = "mesh",
    mesh = "railtest_steam_train.b3d",
    visual_size = {x=1, y=1},
    textures = {"railtest_steam_train.png"},
    automatic_face_movement_dir = 0.0,
    direction    = {x=0,y=0,z=0},
    speed        = 0, --dpt (distance per tick, speed measurement)
    -- The max amount of fuel this minecart can hold
    max_fuel = 10000,
    -- The maxium about of coolant that the train can hold
    max_coolant = 2000,
    -- The max distance per tick the train can go
    max_speed = 0.01,
    item_name = "steam_mining_drill",
    description = "Steam powered mining drill",
    inventory_image = "railtest_cart_item_image.png",
    wield_image = "railtest_cart_item_image.png"
}
cart_link = {}

-- A table containing each item that can be used as fuel and how much fuel it provides
local fuel_burn_time = {}
fuel_burn_time["default:coal_lump"] = 100
fuel_burn_time["default:coalblock"] = 900
fuel_burn_time["charcoal:charcoal_lump"] = 100
fuel_burn_time["charcoal:charcoal_block"] = 900


--punch function
function minecart.on_punch(self, puncher)
    handle_punch(self, puncher, minecart)
end

--right click function
function minecart.on_rightclick(self, clicker)
    if clicker:get_wielded_item():get_name() == "default:rail" then
        local player_held_item = clicker:get_wielded_item():get_name()
        local stack_total = clicker:get_wielded_item():get_count()
        self.rails = self.rails + stack_total
        clicker:set_wielded_item({name=player_held_item, count=0, wear=0, metadata=""})
    else
        self = handle_rightclick(self, clicker, fuel_burn_time)
    end
end

--when the minecart is created in world
function minecart.on_activate(self, staticdata, dtime_s)
    self.max_coolant = minecart.max_coolant
    self.max_speed = minecart.max_speed
    self.max_fuel = minecart.max_fuel
    self.fuel = 0
    self.rails = 0
    set_direction(self)
end

--what the minecart does in the world
function minecart.on_step(self, dtime)
    -- Remove the cart if it's HP hits 0
    if self.object:get_hp() == 0 then
        self.object:remove()
    end
    speed, direction, movement, fuel = drill(self)
    self.object:get_luaentity().speed = speed
    self.object:get_luaentity().direction = direction
    self.object:moveto(movement)
end

function drill(self)

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

    --local currentnode = minetest.get_node({x=x,y=y,z=z}).name
    local forwardnode = minetest.get_node({x=speedx,y=y,z=speedz}) --the node 1 space in front of it
    -- minetest.chat_send_player("singleplayer", forwardnode)
    local upnode      = minetest.get_node({x=speedx+(direction.x),y=speedy+1,z=speedz+(direction.z)})    --the node 1 space up + 1 space forwards
    local downnode    = minetest.get_node({x=pos.x+(direction.x/2),y=speedy-1,z=pos.z+(direction.z/2)})    --the node 1 space down + 1 space forwards
    local nodeahead   = minetest.get_node({x=pos.x+(direction.x/2),y=pos.y+(direction.y/2),z=pos.z+(direction.z/2)}) --1 rounded node ahead

    --move minecart down
    --move the cart forwards
    if is_rail(nodeahead) == true and direction.y == 0 then
        if math.abs(speedx) ~= 0 or math.abs(speedz) ~= 0 then
            movement = {x=speedx,y=speedy,z=speedz}
            --keep cart on center of rail
            if math.abs(direction.x) > 0 then
                movement.z = z
            elseif math.abs(direction.z) > 0 then
                movement.x = x
            end
        end
    elseif is_rail(nodeahead) == false and direction.y == 0 then
        if nodeahead.name == "air" and downnode ~= "air" then
            if self.rails > 0 then
                minetest.set_node({x=pos.x+(direction.x/2),y=pos.y+(direction.y/2),z=pos.z+(direction.z/2)}, {name="default:rail"})
                self.rails = self.rails - 1
            end
        else
            if self.rails > 0 then
                for height=0,2 do
                    for width=-1,1 do
                        if direction.z ~= 0 then
                            if self.player then
                                minetest.node_dig({x=pos.x+(direction.x/2) + width,y=pos.y + height,z=pos.z+(direction.z/2)}, minetest.get_node({x=pos.x+(direction.x/2) + width,y=pos.y + height,z=pos.z+(direction.z/2)}), self.player)
                            else
                                local target_node_drop = minetest.get_node_drops(minetest.get_node({x=pos.x + (direction.x/2) + width,y=pos.y + height,z=pos.z + (direction.z/2)}).name, "default:pick_diamond")
                                -- for every item the node would drop
                                -- add it to the game in the target node position
                                for _, dropname in ipairs(target_node_drop) do
                                        minetest.add_item(pos, dropname)
                                end
                                minetest.dig_node({x=pos.x+(direction.x/2) + width,y=pos.y + height,z=pos.z+(direction.z/2)})
                            end
                        elseif direction.x ~= 0 then
                            if self.player then
                                minetest.node_dig({x=pos.x+(direction.x/2),y=pos.y + height,z=pos.z+(direction.z/2) + width}, minetest.get_node({x=pos.x+(direction.x/2),y=pos.y + height,z=pos.z+(direction.z/2) + width}), self.player)
                            else
                                local target_node_drop = minetest.get_node_drops(minetest.get_node({x=pos.x + (direction.x/2),y=pos.y + height,z=pos.z + (direction.z/2) + width}).name, "default:pick_diamond")
                                -- for every item the node would drop
                                -- add it to the game in the target node position
                                for _, dropname in ipairs(target_node_drop) do
                                        minetest.add_item(pos, dropname)
                                end
                                minetest.dig_node({x=pos.x+(direction.x/2),y=pos.y + height,z=pos.z+(direction.z/2) + width})
                            end
                        end
                    end
                end
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
        local fuel_to_use = speed * 10
        self.fuel = fuel - fuel_to_use
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

add_spawn_item(minecart)

minetest.register_entity("railtest:" .. minecart.item_name .. "_entity", minecart)
