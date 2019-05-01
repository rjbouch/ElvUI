local _, ns = ...
local oUF = ns.oUF

local unpack = unpack

local GetPetHappiness = GetPetHappiness
local UnitClass = UnitClass
local UnitIsConnected = UnitIsConnected
local UnitIsPlayer = UnitIsPlayer
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitIsUnit = UnitIsUnit
local UnitPlayerControlled = UnitPlayerControlled
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnitReaction = UnitReaction

local updateFrequentUpdates

local function UpdateColor(element, unit, cur, min, max)
	local parent = element.__owner

	if element.frequentUpdates ~= element.__frequentUpdates then
		element.__frequentUpdates = element.frequentUpdates
		updateFrequentUpdates(self, unit)
	end

	local r, g, b, t
	if(element.colorTapping and element.tapped) then
		t = parent.colors.tapped
	elseif(element.colorDisconnected and element.disconnected) then
		t = parent.colors.disconnected
	elseif(element.colorHappiness and UnitIsUnit(unit, 'pet') and GetPetHappiness()) then
		t = parent.colors.happiness[GetPetHappiness()]
	elseif(element.colorPower) then
		t = parent.colors.power["ENERGY"]
	elseif(element.colorClass and UnitIsPlayer(unit)) or
		(element.colorClassNPC and not UnitIsPlayer(unit)) or
		(element.colorClassPet and UnitPlayerControlled(unit) and not UnitIsPlayer(unit)) then
		local _, class = UnitClass(unit)
		t = parent.colors.class[class]
	elseif(element.colorReaction and UnitReaction(unit, 'player')) then
		t = parent.colors.reaction[UnitReaction(unit, 'player')]
	elseif(element.colorSmooth) then
		local adjust = 0 - (min or 0)
		r, g, b = parent.ColorGradient(cur + adjust, max + adjust, unpack(element.smoothGradient or parent.colors.smooth))
	end

	if(t) then
		r, g, b = t[1], t[2], t[3]
	end

	t = parent.colors.power["ENERGY"]

	element:SetStatusBarTexture(element.texture)

	if(r or g or b) then
		element:SetStatusBarColor(r, g, b)
	end

	local bg = element.bg
	if(bg and b) then
		local mu = bg.multiplier or 1
		bg:SetVertexColor(r * mu, g * mu, b * mu)
	end
end

local function Update(self, event, unit)
	if (self.unit ~= unit) then return end
	local element = self.Energy

	--[[ Callback: Power:PreUpdate(unit)
	Called before the element has been updated.

	* self - the Power element
	* unit - the unit for which the update has been triggered (string)
	--]]
	if (element.PreUpdate) then
		element:PreUpdate(unit)
	end

	local cur, max = UnitPower(unit, 3), UnitPowerMax(unit, 3)
	local disconnected = not UnitIsConnected(unit)
	local tapped = not UnitPlayerControlled(unit) and (UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) and not UnitIsTappedByAllThreatList(unit))
	element:SetMinMaxValues(0, max)

	if(disconnected) then
		element:SetValue(max)
	else
		element:SetValue(cur)
	end

	element.disconnected = disconnected
	element.tapped = tapped

	--[[ Override: Power:UpdateColor(unit, cur, max)
	Used to completely override the internal function for updating the widget's colors.

	* self        - the Power element
	* unit        - the unit for which the update has been triggered (string)
	* cur         - the unit's current power value (number)
	* max         - the unit's maximum possible power value (number)
	--]]
	element:UpdateColor(unit, cur, max)

	--[[ Callback: Power:PostUpdate(unit, cur, max)
	Called after the element has been updated.

	* self       - the Power element
	* unit       - the unit for which the update has been triggered (string)
	* cur        - the unit's current power value (number)
	* max        - the unit's maximum possible power value (number)
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(unit, cur, max)
	end
end

local function Path(self, ...)
	--[[ Override: Power.Override(self, event, unit, ...)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event (string)
	* ...   - the arguments accompanying the event
	--]]
	return (self.Energy.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function onPowerUpdate(self)
	if(self.disconnected) then return end

	local unit = self.__owner.unit
	local power = UnitPower(unit, 3) -- SPELL_POWER_ENERGY

	if(power ~= self.min) then
		self.min = power

		return Path(self.__owner, 'OnEnergyUpdate', unit)
	end
end

function updateFrequentUpdates(self, unit)
	if(not unit or (unit ~= 'player' and unit ~= 'pet')) then return end

	local element = self.Energy
	if(element.frequentUpdates and not element:GetScript('OnUpdate')) then
		element:SetScript('OnUpdate', onPowerUpdate)

		self:UnregisterEvent('UNIT_ENERGY', Path)
	elseif(not element.frequentUpdates and element:GetScript('OnUpdate')) then
		element:SetScript('OnUpdate', nil)

		self:RegisterEvent('UNIT_ENERGY', Path)
	end
end

local function Enable(self, unit)
	local element = self.Energy
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate
		element.__frequentUpdates = element.frequentUpdates
		updateFrequentUpdates(self, unit)

		if(element.frequentUpdates and (unit == 'player' or unit == 'pet')) then
			element:SetScript('OnUpdate', onPowerUpdate)
		else
			self:RegisterEvent('UNIT_ENERGY', Path)
		end

		self:RegisterEvent('UNIT_MAXENERGY', Path)

		if(element:IsObjectType('StatusBar')) then
			element.texture = element:GetStatusBarTexture() and element:GetStatusBarTexture():GetTexture() or [[Interface\TargetingFrame\UI-StatusBar]]
			element:SetStatusBarTexture(element.texture)
		end

		if(not element.UpdateColor) then
			element.UpdateColor = UpdateColor
		end

		element:Show()

		return true
	end
end

local function Disable(self)
	local element = self.Energy
	if(element) then
		element:Hide()

		if(element:GetScript('OnUpdate')) then
			element:SetScript('OnUpdate', nil)
		else
			self:UnregisterEvent('UNIT_ENERGY', Path)
		end

		self:UnregisterEvent('UNIT_MAXENERGY', Path)
	end
end

oUF:AddElement('Energy', Path, Enable, Disable)