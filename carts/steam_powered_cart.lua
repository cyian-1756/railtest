
local minecart   = {
    physical     = true,
    collisionbox = {-0.5,-0.5,-0.5, 0.5,0.5,0.5},
    visual = "mesh",
    mesh = "carts_cart.b3d",
    visual_size = {x=1, y=1},
    textures = {"carts_cart.png"},
    automatic_face_movement_dir = 0.0,
    direction    = {x=0,y=0,z=0},
    speed        = 0, --dpt (distance per tick, speed measurement)
    -- The max amount of fuel this minecart can hold
    max_fuel = 2000,
    -- The maxium about of coolant that the train can hold
    max_coolant = 2000,
    -- The max distance per tick the train can go
    max_speed = 0.48,
    item_name = "steam_powered_cart",
    description = "Steam powered cart",
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
    self = handle_punch(self, puncher, minecart)
end

--right click function
function minecart.on_rightclick(self, clicker)
    self = handle_rightclick(self, clicker, fuel_burn_time)
end

--when the minecart is created in world
function minecart.on_activate(self, staticdata, dtime_s)
    self.max_coolant = minecart.max_coolant
    self.max_speed = minecart.max_speed
    self.max_fuel = minecart.max_fuel
    self.fuel = 0
    self.speed = 0.0
    set_direction(self)
end

--what the minecart does in the world
function minecart.on_step(self, dtime)
    -- Remove the cart if it's HP hits 0
    if self.object:get_hp() == 0 then
        self.object:remove()
    end
    local speed, direction, movement, fuel = roll(self)
    self.object:get_luaentity().speed = speed
    self.object:get_luaentity().direction = direction
    self.object:moveto(movement)
end

add_spawn_item(minecart)

minetest.register_entity("railtest:" .. minecart.item_name .. "_entity", minecart)
