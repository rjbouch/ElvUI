local parent, ns = ...
local oUF = ns.oUF

local Update = function(self, event)
	if not self.unit then return; end
	
	local assistant = self.Assistant
	
	local unit = self.unit
	if(UnitInRaid(unit) and UnitIsRaidOfficer(unit) and not UnitIsPartyLeader(unit)) then
		assistant:Show()
	else
		assistant:Hide()
	end
end

local Enable = function(self)
	local assistant = self.Assistant
	if(assistant) then
		self:RegisterEvent("PARTY_MEMBERS_CHANGED", assistant.Update or Update)

		if(assistant:IsObjectType"Texture" and not assistant:GetTexture()) then
			assistant:SetTexture[[Interface\GroupFrame\UI-Group-AssistantIcon]]
		end

		return true
	end
end

local Disable = function(self)
	local assistant = self.Assistant
	if(assistant) then
		self:UnregisterEvent("PARTY_MEMBERS_CHANGED", assistant.Update or Update)
	end
end

oUF:AddElement('Assistant', Update, Enable, Disable)
