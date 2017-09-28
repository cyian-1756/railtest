function is_rail(node)
	local nn = node.name
	return minetest.get_item_group(nn, "rail") ~= 0
end
