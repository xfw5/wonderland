function Utils:EquipItemsWithName( hero, itemsKV)
	for itemName, _ in pairs(itemsKV) do
		local item = CreateItem(itemName, hero, hero)
		hero:AddItem(item)
	end
end