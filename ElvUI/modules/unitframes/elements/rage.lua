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

function UF:Construct_RageBar(frame, bg, text, textPos)
	local rage = CreateFrame("StatusBar", nil, frame)
	UF["statusbars"][rage] = true

	rage.PostUpdate = self.PostUpdateRage

	if bg then
		rage.bg = rage:CreateTexture(nil, "BORDER")
		rage.bg:SetAllPoints()
		rage.bg:SetTexture(E["media"].blankTex)
		rage.bg.multiplier = 0.2
	end

	if text then
		rage.value = frame.RaisedElementParent:CreateFontString(nil, "OVERLAY")
		UF:Configure_FontString(rage.value)

		local x = -2
		if textPos == "LEFT" then
			x = 2
		end

		rage.value:Point(textPos, frame.Health, textPos, x, 0)
	end

	rage.colorDisconnected = false
	rage.colorTapping = false
	rage:CreateBackdrop("Default", nil, nil, self.thinBorders, true)

	return rage
end

function UF:Configure_Rage(frame)
	if not frame.VARIABLES_SET then return end
	local db = frame.db
	local rage = frame.Rage
	rage.origParent = frame

	if db.power.enableRage and frame.USE_POWERBAR then
		rage:Show()
		rage.Smooth = self.db.smoothbars
		rage.SmoothSpeed = self.db.smoothSpeed * 10

		--Text
		local attachPoint = self:GetObjectAnchorPoint(frame, "Rage")
		rage.value:ClearAllPoints()
		rage.value:Point(db.power.position, attachPoint, db.power.position, db.power.xOffset, db.power.yOffset)
		frame:Tag(rage.value, "[rage:current]")

		rage.value:SetParent(rage)

		--Colors
		rage.colorPower = true

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
		rage:ClearAllPoints()
		if frame.POWERBAR_DETACHED then
			rage:Width(frame.POWERBAR_WIDTH - ((frame.BORDER + frame.SPACING)*2))
			rage:Height(frame.POWERBAR_HEIGHT - ((frame.BORDER + frame.SPACING)*2))
			if not rage.Holder or (rage.Holder and not rage.Holder.mover) then
				rage.Holder = CreateFrame("Frame", nil, rage)
				rage.Holder:Size(frame.POWERBAR_WIDTH, frame.POWERBAR_HEIGHT)
				rage.Holder:Point("BOTTOM", frame, "BOTTOM", 0, -20)
				rage:ClearAllPoints()
				rage:Point("BOTTOMLEFT", rage.Holder, "BOTTOMLEFT", frame.BORDER+frame.SPACING, frame.BORDER+frame.SPACING)
				--Currently only Player and Target can detach power bars, so doing it this way is okay for now
				if frame.unitframeType and frame.unitframeType == "player" then
					E:CreateMover(rage.Holder, "PlayerPowerBarMover", L["Player Powerbar"], nil, nil, nil, "ALL,SOLO")
				elseif frame.unitframeType and frame.unitframeType == "target" then
					E:CreateMover(rage.Holder, "TargetPowerBarMover", L["Target Powerbar"], nil, nil, nil, "ALL,SOLO")
				end
			else
				rage.Holder:Size(frame.POWERBAR_WIDTH, frame.POWERBAR_HEIGHT)
				rage:ClearAllPoints()
				rage:Point("BOTTOMLEFT", rage.Holder, "BOTTOMLEFT", frame.BORDER+frame.SPACING, frame.BORDER+frame.SPACING)
				rage.Holder.mover:SetScale(1)
				rage.Holder.mover:SetAlpha(1)
			end

			rage:SetFrameLevel(50) --RaisedElementParent uses 100, we want lower value to allow certain icons and texts to appear above power
		elseif frame.USE_POWERBAR_OFFSET then
			if frame.ORIENTATION == "LEFT" then
				rage:Point("TOPRIGHT", frame.Health, "TOPRIGHT", frame.POWERBAR_OFFSET, -frame.POWERBAR_OFFSET)
				rage:Point("BOTTOMLEFT", frame.Health, "BOTTOMLEFT", frame.POWERBAR_OFFSET, -frame.POWERBAR_OFFSET)
			elseif frame.ORIENTATION == "MIDDLE" then
				rage:Point("TOPLEFT", frame, "TOPLEFT", frame.BORDER + frame.SPACING, -frame.POWERBAR_OFFSET -frame.CLASSBAR_YOFFSET)
				rage:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -frame.BORDER - frame.SPACING, frame.BORDER)
			else
				rage:Point("TOPLEFT", frame.Health, "TOPLEFT", -frame.POWERBAR_OFFSET, -frame.POWERBAR_OFFSET)
				rage:Point("BOTTOMRIGHT", frame.Health, "BOTTOMRIGHT", -frame.POWERBAR_OFFSET, -frame.POWERBAR_OFFSET)
			end
			rage:SetFrameLevel(frame.Health:GetFrameLevel() -5) --Health uses 10
		elseif frame.USE_INSET_POWERBAR then
			rage:Height(frame.POWERBAR_HEIGHT  - ((frame.BORDER + frame.SPACING)*2))
			rage:Point("BOTTOMLEFT", frame.Health, "BOTTOMLEFT", frame.BORDER + (frame.BORDER*2), frame.BORDER + (frame.BORDER*2))
			rage:Point("BOTTOMRIGHT", frame.Health, "BOTTOMRIGHT", -(frame.BORDER + (frame.BORDER*2)), frame.BORDER + (frame.BORDER*2))
			rage:SetFrameLevel(50)
		elseif frame.USE_MINI_POWERBAR then
			rage:Height(frame.POWERBAR_HEIGHT  - ((frame.BORDER + frame.SPACING)*2))

			if frame.ORIENTATION == "LEFT" then
				rage:Width(frame.POWERBAR_WIDTH - frame.BORDER*2)
				rage:Point("RIGHT", frame, "BOTTOMRIGHT", -(frame.BORDER*2 + 4), ((frame.POWERBAR_HEIGHT-frame.BORDER)/2))
			elseif frame.ORIENTATION == "RIGHT" then
				rage:Width(frame.POWERBAR_WIDTH - frame.BORDER*2)
				rage:Point("LEFT", frame, "BOTTOMLEFT", (frame.BORDER*2 + 4), ((frame.POWERBAR_HEIGHT-frame.BORDER)/2))
			else
				rage:Point("LEFT", frame, "BOTTOMLEFT", (frame.BORDER*2 + 4), ((frame.POWERBAR_HEIGHT-frame.BORDER)/2))
				rage:Point("RIGHT", frame, "BOTTOMRIGHT", -(frame.BORDER*2 + 4), ((frame.POWERBAR_HEIGHT-frame.BORDER)/2))
			end

			rage:SetFrameLevel(50)
		else
            local count = 0;
            local index = 0;
			
			if db.power.enableMana then count = count + 1; index = index + 1 end
			if db.power.enableEnergy then count = count + 1; index = index + 1 end
            if db.power.enableRage then count = count + 1 end

            local h = frame.POWERBAR_HEIGHT / count
            
            print("Rage height: " .. h)
            print("Rage offset: " .. (-frame.SPACING*3 - (h * index)))

			rage:Point("TOPRIGHT", frame.Health.backdrop, "BOTTOMRIGHT", -frame.BORDER, -frame.SPACING*3 - (h * index))
			rage:Point("TOPLEFT", frame.Health.backdrop, "BOTTOMLEFT", frame.BORDER, -frame.SPACING*3 - (h * index))

			if count ~= 0  then
				rage:Height(h - ((frame.BORDER + frame.SPACING)*2))
			else
				rage:Height(frame.POWERBAR_HEIGHT - ((frame.BORDER + frame.SPACING)*2))
			end

			rage:SetFrameLevel(frame.Health:GetFrameLevel() - 5)
		end

		--Hide mover until we detach again
		if not frame.POWERBAR_DETACHED then
			if rage.Holder and rage.Holder.mover then
				rage.Holder.mover:SetScale(0.0001)
				rage.Holder.mover:SetAlpha(0)
			end
		end

		if db.power.strataAndLevel and db.power.strataAndLevel.useCustomStrata then
			rage:SetFrameStrata(db.power.strataAndLevel.frameStrata)
		else
			rage:SetFrameStrata("LOW")
		end
		if db.power.strataAndLevel and db.power.strataAndLevel.useCustomLevel then
			rage:SetFrameLevel(db.power.strataAndLevel.frameLevel)
			rage.backdrop:SetFrameLevel(rage:GetFrameLevel() - 1)
		end

		if frame.POWERBAR_DETACHED and db.power.parent == "UIPARENT" then
			rage:SetParent(E.UIParent)
		else
			rage:SetParent(frame)
		end

	elseif frame:IsElementEnabled("Rage") then
		frame:DisableElement("Rage")
		rage:Hide()
		frame:Tag(rage.value, "")
	end

	--Transparency Settings
	UF:ToggleTransparentStatusBar(UF.db.colors.transparentPower, frame.Rage, frame.Rage.bg)
end

local tokens = {[0] = "MANA", "RAGE", "FOCUS", "ENERGY", "RUNIC_POWER"}

function UF:PostUpdateRage(unit, _, max)
	local parent = self:GetParent()

	if parent.isForced then
		local color = ElvUF.colors.power.RAGE
		local cur = random(1, max)
        self:SetValue(cur)
        
        print("Update rage")

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