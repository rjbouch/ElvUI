local E, L, V, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local UF = E:GetModule("UnitFrames")

--Cache global variables
--Lua functions
local random = random
--WoW API / Variables
local CreateFrame = CreateFrame

local _, ns = ...
local ElvUF = ns.oUF
assert(ElvUF, "ElvUI was unable to locate oUF.")

function UF:Construct_EnergyBar(frame, bg, text, textPos)
	local energy = CreateFrame("StatusBar", nil, frame)
	UF["statusbars"][energy] = true

	energy.PostUpdate = self.PostUpdateEnergy

	if bg then
		energy.bg = energy:CreateTexture(nil, "BORDER")
		energy.bg:SetAllPoints()
		energy.bg:SetTexture(E["media"].blankTex)
		energy.bg.multiplier = 0.2
	end

	if text then
		energy.value = frame.RaisedElementParent:CreateFontString(nil, "OVERLAY")
		UF:Configure_FontString(energy.value)

		local x = -2
		if textPos == "LEFT" then
			x = 2
		end

		energy.value:Point(textPos, frame.Health, textPos, x, 0)
	end

	energy.colorDisconnected = false
	energy.colorTapping = false
	energy:CreateBackdrop("Default", nil, nil, self.thinBorders, true)

	return energy
end

function UF:Configure_Energy(frame)
	if not frame.VARIABLES_SET then return end
	local db = frame.db
	local energy = frame.Energy
	energy.origParent = frame

	if db.power.enableEnergy and frame.USE_POWERBAR then
		energy:Show()
		energy.Smooth = self.db.smoothbars
		energy.SmoothSpeed = self.db.smoothSpeed * 10

		--Text
		local attachPoint = self:GetObjectAnchorPoint(frame, "Energy")
		energy.value:ClearAllPoints()
		energy.value:Point(db.power.position, attachPoint, db.power.position, db.power.xOffset, db.power.yOffset)
		frame:Tag(energy.value, "[energy:current]") -- TODO: Config

		energy.value:SetParent(energy)

		--Colors
		energy.colorPower = true

		--Fix height in case it is lower than the theme allows
		local heightChanged = false
		if (not self.thinBorders and not E.PixelMode) and frame.POWERBAR_HEIGHT < 7 then --A height of 7 means 6px for borders and just 1px for the actual power statusbar
			frame.POWERBAR_HEIGHT = 7
			if db.power then db.power.height = 7 end
			heightChanged = true
		elseif (self.thinBorders or E.PixelMode) and frame.POWERBAR_HEIGHT < 3 then --A height of 3 means 2px for borders and just 1px for the actual power statusbar
			frame.POWERBAR_HEIGHT = 3
			if db.power then db.power.height = 3 end
			heightChanged = true
		end
		if heightChanged then
			--Update health size
			frame.BOTTOM_OFFSET = UF:GetHealthBottomOffset(frame) + frame.POWERBAR_HEIGHT
			UF:Configure_HealthBar(frame)
		end

		--Position
		energy:ClearAllPoints()
		if frame.POWERBAR_DETACHED then
			energy:Width(frame.POWERBAR_WIDTH - ((frame.BORDER + frame.SPACING)*2))
			energy:Height(frame.POWERBAR_HEIGHT - ((frame.BORDER + frame.SPACING)*2))
			if not energy.Holder or (energy.Holder and not energy.Holder.mover) then
				energy.Holder = CreateFrame("Frame", nil, energy)
				energy.Holder:Size(frame.POWERBAR_WIDTH, frame.POWERBAR_HEIGHT)
				energy.Holder:Point("BOTTOM", frame, "BOTTOM", 0, -20)
				energy:ClearAllPoints()
				energy:Point("BOTTOMLEFT", energy.Holder, "BOTTOMLEFT", frame.BORDER+frame.SPACING, frame.BORDER+frame.SPACING)
				--Currently only Player and Target can detach power bars, so doing it this way is okay for now
				if frame.unitframeType and frame.unitframeType == "player" then
					E:CreateMover(energy.Holder, "PlayerPowerBarMover", L["Player Powerbar"], nil, nil, nil, "ALL,SOLO")
				elseif frame.unitframeType and frame.unitframeType == "target" then
					E:CreateMover(energy.Holder, "TargetPowerBarMover", L["Target Powerbar"], nil, nil, nil, "ALL,SOLO")
				end
			else
				energy.Holder:Size(frame.POWERBAR_WIDTH, frame.POWERBAR_HEIGHT)
				energy:ClearAllPoints()
				energy:Point("BOTTOMLEFT", energy.Holder, "BOTTOMLEFT", frame.BORDER+frame.SPACING, frame.BORDER+frame.SPACING)
				energy.Holder.mover:SetScale(1)
				energy.Holder.mover:SetAlpha(1)
			end

			energy:SetFrameLevel(50) --RaisedElementParent uses 100, we want lower value to allow certain icons and texts to appear above power
		elseif frame.USE_POWERBAR_OFFSET then
			if frame.ORIENTATION == "LEFT" then
				energy:Point("TOPRIGHT", frame.Health, "TOPRIGHT", frame.POWERBAR_OFFSET, -frame.POWERBAR_OFFSET)
				energy:Point("BOTTOMLEFT", frame.Health, "BOTTOMLEFT", frame.POWERBAR_OFFSET, -frame.POWERBAR_OFFSET)
			elseif frame.ORIENTATION == "MIDDLE" then
				energy:Point("TOPLEFT", frame, "TOPLEFT", frame.BORDER + frame.SPACING, -frame.POWERBAR_OFFSET -frame.CLASSBAR_YOFFSET)
				energy:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -frame.BORDER - frame.SPACING, frame.BORDER)
			else
				energy:Point("TOPLEFT", frame.Health, "TOPLEFT", -frame.POWERBAR_OFFSET, -frame.POWERBAR_OFFSET)
				energy:Point("BOTTOMRIGHT", frame.Health, "BOTTOMRIGHT", -frame.POWERBAR_OFFSET, -frame.POWERBAR_OFFSET)
			end
			energy:SetFrameLevel(frame.Health:GetFrameLevel() -5) --Health uses 10
		elseif frame.USE_INSET_POWERBAR then
			energy:Height(frame.POWERBAR_HEIGHT  - ((frame.BORDER + frame.SPACING)*2))
			energy:Point("BOTTOMLEFT", frame.Health, "BOTTOMLEFT", frame.BORDER + (frame.BORDER*2), frame.BORDER + (frame.BORDER*2))
			energy:Point("BOTTOMRIGHT", frame.Health, "BOTTOMRIGHT", -(frame.BORDER + (frame.BORDER*2)), frame.BORDER + (frame.BORDER*2))
			energy:SetFrameLevel(50)
		elseif frame.USE_MINI_POWERBAR then
			energy:Height(frame.POWERBAR_HEIGHT  - ((frame.BORDER + frame.SPACING)*2))

			if frame.ORIENTATION == "LEFT" then
				energy:Width(frame.POWERBAR_WIDTH - frame.BORDER*2)
				energy:Point("RIGHT", frame, "BOTTOMRIGHT", -(frame.BORDER*2 + 4), ((frame.POWERBAR_HEIGHT-frame.BORDER)/2))
			elseif frame.ORIENTATION == "RIGHT" then
				energy:Width(frame.POWERBAR_WIDTH - frame.BORDER*2)
				energy:Point("LEFT", frame, "BOTTOMLEFT", (frame.BORDER*2 + 4), ((frame.POWERBAR_HEIGHT-frame.BORDER)/2))
			else
				energy:Point("LEFT", frame, "BOTTOMLEFT", (frame.BORDER*2 + 4), ((frame.POWERBAR_HEIGHT-frame.BORDER)/2))
				energy:Point("RIGHT", frame, "BOTTOMRIGHT", -(frame.BORDER*2 + 4), ((frame.POWERBAR_HEIGHT-frame.BORDER)/2))
			end

			energy:SetFrameLevel(50)
		else
			local count = 0;
			local index = 0;
			
			if db.power.enableMana then count = count + 1; index = index + 1 end
			if db.power.enableEnergy then count = count + 1 end
			if db.power.enableRage then count = count + 1 end

			local h = frame.POWERBAR_HEIGHT / count

			print("Energy height: " .. h)
			print("Energy offset: " .. (-frame.SPACING*3 - (h * index)))

			energy:Point("TOPRIGHT", frame.Health.backdrop, "BOTTOMRIGHT", -frame.BORDER, -frame.SPACING*3 - (h * index))
			energy:Point("TOPLEFT", frame.Health.backdrop, "BOTTOMLEFT", frame.BORDER, -frame.SPACING*3 - (h * index))

			if count ~= 0  then
				energy:Height(h - ((frame.BORDER + frame.SPACING)*2))
			else
				energy:Height(frame.POWERBAR_HEIGHT - ((frame.BORDER + frame.SPACING)*2))
			end

			energy:SetFrameLevel(frame.Health:GetFrameLevel() - 5)
		end

		--Hide mover until we detach again
		if not frame.POWERBAR_DETACHED then
			if energy.Holder and energy.Holder.mover then
				energy.Holder.mover:SetScale(0.0001)
				energy.Holder.mover:SetAlpha(0)
			end
		end

		if db.power.strataAndLevel and db.power.strataAndLevel.useCustomStrata then
			energy:SetFrameStrata(db.power.strataAndLevel.frameStrata)
		else
			energy:SetFrameStrata("LOW")
		end
		if db.power.strataAndLevel and db.power.strataAndLevel.useCustomLevel then
			energy:SetFrameLevel(db.power.strataAndLevel.frameLevel)
			energy.backdrop:SetFrameLevel(energy:GetFrameLevel() - 1)
		end

		if frame.POWERBAR_DETACHED and db.power.parent == "UIPARENT" then
			energy:SetParent(E.UIParent)
		else
			energy:SetParent(frame)
		end

	elseif frame:IsElementEnabled("Energy") then
		frame:DisableElement("Energy")
		energy:Hide()
		frame:Tag(energy.value, "")
	end

	--Transparency Settings
	UF:ToggleTransparentStatusBar(UF.db.colors.transparentPower, frame.Energy, frame.Energy.bg)
end

local tokens = {[0] = "MANA", "RAGE", "FOCUS", "ENERGY", "RUNIC_POWER"}

function UF:PostUpdateEnergy(unit, _, max)
	local parent = self:GetParent()

	if parent.isForced then
		local color = ElvUF.colors.power.ENERGY
		local cur = random(1, max)
		self:SetValue(cur)

		if not self.colorClass then
			self:SetStatusBarColor(color[1], color[2], color[3])
			local mu = self.bg.multiplier or 1
			self.bg:SetVertexColor(color[1] * mu, color[2] * mu, color[3] * mu)
		end
	end

	local db = parent.db
	if db and db.power and db.power.hideonnpc then
		UF:PostNamePosition(parent, unit)
	end
end