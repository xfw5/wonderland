ent_swallow_tree_lua = class ({})

function ent_swallow_tree_lua:OnSpellStart()
	local target = self:GetCursorTarget()

	target:CutDown(self:GetCaster():GetTeamNumber())
end

function ent_swallow_tree_lua:GetCastRange(vLocation, hTarget)
	return 150;
end