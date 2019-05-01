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

function UF:Construct_ManaBar(frame, bg, text, textPos)
	local mana = CreateFrame("StatusBar", nil, frame)
	UF["statusbars"][mana] = true

	mana.PostUpdate = self.PostUpdateMana

	if bg then
		mana.bg = mana:CreateTexture(nil, "BORDER")
		mana.bg:SetAllPoints()
		mana.bg:SetTexture(E["media"].blankTex)
		mana.bg.multiplier = 0.2
	end

	if text then
		mana.value = frame.RaisedElementParent:CreateFontString(nil, "OVERLAY")
		UF:Configure_FontString(mana.value)

		local x = -2
		if textPos == "LEFT" then
			x = 2
		end

		mana.value:Point(textPos, frame.Health, textPos, x, 0)
	end

	mana.colorDisconnected = false
	mana.colorTapping = false
	mana:CreateBackdrop("Default", nil, nil, self.thinBorders, true)

	return mana
end

function UF:Configure_Mana(frame)
	if not frame.VARIABLES_SET then return end
	local db = frame.db
	local mana = frame.Mana
	mana.origParent = frame

	if db.power.enableMana and frame.USE_POWERBAR then
		if not frame:IsElementEnabled("Power") then
			frame:EnableElement("Power")
			mana:Show()
		end

		mana.Smooth = self.db.smoothbars
		mana.SmoothSpeed = self.db.smoothSpeed * 10

		--Text
		local attachPoint = self:GetObjectAnchorPoint(frame, "Mana")
		mana.value:ClearAllPoints()
		mana.value:Point(db.power.position, attachPoint, db.power.position, db.power.xOffset, db.power.yOffset)
		frame:Tag(mana.value, db.power.text_format)

		mana.value:SetParent(mana)

		--Colors
		mana.colorPower = true

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
		mana:ClearAllPoints()
		if frame.POWERBAR_DETACHED then
			mana:Width(frame.POWERBAR_WIDTH - ((frame.BORDER + frame.SPACING)*2))
			mana:Height(frame.POWERBAR_HEIGHT - ((frame.BORDER + frame.SPACING)*2))
			if not mana.Holder or (mana.Holder and not mana.Holder.mover) then
				mana.Holder = CreateFrame("Frame", nil, mana)
				mana.Holder:Size(frame.POWERBAR_WIDTH, frame.POWERBAR_HEIGHT)
				mana.Holder:Point("BOTTOM", frame, "BOTTOM", 0, -20)
				mana:ClearAllPoints()
				mana:Point("BOTTOMLEFT", mana.Holder, "BOTTOMLEFT", frame.BORDER+frame.SPACING, frame.BORDER+frame.SPACING)
				--Currently only Player and Target can detach power bars, so doing it this way is okay for now
				if frame.unitframeType and frame.unitframeType == "player" then
					E:CreateMover(mana.Holder, "PlayerPowerBarMover", L["Player Powerbar"], nil, nil, nil, "ALL,SOLO")
				elseif frame.unitframeType and frame.unitframeType == "target" then
					E:CreateMover(mana.Holder, "TargetPowerBarMover", L["Target Powerbar"], nil, nil, nil, "ALL,SOLO")
				end
			else
				mana.Holder:Size(frame.POWERBAR_WIDTH, frame.POWERBAR_HEIGHT)
				mana:ClearAllPoints()
				mana:Point("BOTTOMLEFT", mana.Holder, "BOTTOMLEFT", frame.BORDER+frame.SPACING, frame.BORDER+frame.SPACING)
				mana.Holder.mover:SetScale(1)
				mana.Holder.mover:SetAlpha(1)
			end

			mana:SetFrameLevel(50) --RaisedElementParent uses 100, we want lower value to allow certain icons and texts to appear above power
		elseif frame.USE_POWERBAR_OFFSET then
			if frame.ORIENTATION == "LEFT" then
				mana:Point("TOPRIGHT", frame.Health, "TOPRIGHT", frame.POWERBAR_OFFSET, -frame.POWERBAR_OFFSET)
				mana:Point("BOTTOMLEFT", frame.Health, "BOTTOMLEFT", frame.POWERBAR_OFFSET, -frame.POWERBAR_OFFSET)
			elseif frame.ORIENTATION == "MIDDLE" then
				mana:Point("TOPLEFT", frame, "TOPLEFT", frame.BORDER + frame.SPACING, -frame.POWERBAR_OFFSET -frame.CLASSBAR_YOFFSET)
				mana:Point("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -frame.BORDER - frame.SPACING, frame.BORDER)
			else
				mana:Point("TOPLEFT", frame.Health, "TOPLEFT", -frame.POWERBAR_OFFSET, -frame.POWERBAR_OFFSET)
				mana:Point("BOTTOMRIGHT", frame.Health, "BOTTOMRIGHT", -frame.POWERBAR_OFFSET, -frame.POWERBAR_OFFSET)
			end
			mana:SetFrameLevel(frame.Health:GetFrameLevel() -5) --Health uses 10
		elseif frame.USE_INSET_POWERBAR then
			mana:Height(frame.POWERBAR_HEIGHT  - ((frame.BORDER + frame.SPACING)*2))
			mana:Point("BOTTOMLEFT", frame.Health, "BOTTOMLEFT", frame.BORDER + (frame.BORDER*2), frame.BORDER + (frame.BORDER*2))
			mana:Point("BOTTOMRIGHT", frame.Health, "BOTTOMRIGHT", -(frame.BORDER + (frame.BORDER*2)), frame.BORDER + (frame.BORDER*2))
			mana:SetFrameLevel(50)
		elseif frame.USE_MINI_POWERBAR then
			mana:Height(frame.POWERBAR_HEIGHT  - ((frame.BORDER + frame.SPACING)*2))

			if frame.ORIENTATION == "LEFT" then
				mana:Width(frame.POWERBAR_WIDTH - frame.BORDER*2)
				mana:Point("RIGHT", frame, "BOTTOMRIGHT", -(frame.BORDER*2 + 4), ((frame.POWERBAR_HEIGHT-frame.BORDER)/2))
			elseif frame.ORIENTATION == "RIGHT" then
				mana:Width(frame.POWERBAR_WIDTH - frame.BORDER*2)
				mana:Point("LEFT", frame, "BOTTOMLEFT", (frame.BORDER*2 + 4), ((frame.POWERBAR_HEIGHT-frame.BORDER)/2))
			else
				mana:Point("LEFT", frame, "BOTTOMLEFT", (frame.BORDER*2 + 4), ((frame.POWERBAR_HEIGHT-frame.BORDER)/2))
				mana:Point("RIGHT", frame, "BOTTOMRIGHT", -(frame.BORDER*2 + 4), ((frame.POWERBAR_HEIGHT-frame.BORDER)/2))
			end

			mana:SetFrameLevel(50)
		else
			local count = 0;
			
			if db.power.enableMana then count = count + 1 end
			if db.power.enableEnergy then count = count + 1 end
			if db.power.enableRage then count = count + 1 end

			local h = frame.POWERBAR_HEIGHT / count

			print("Mana height: " .. h)
			print("Mana offset: " .. (-frame.SPACING*3))

			mana:Point("TOPRIGHT", frame.Health.backdrop, "BOTTOMRIGHT", -frame.BORDER, -frame.SPACING*3)
			mana:Point("TOPLEFT", frame.Health.backdrop, "BOTTOMLEFT", frame.BORDER, -frame.SPACING*3)

			if count ~= 0  then
				mana:Height(h - ((frame.BORDER + frame.SPACING)*2))
			else
				mana:Height(frame.POWERBAR_HEIGHT - ((frame.BORDER + frame.SPACING)*2))
			end

			mana:SetFrameLevel(frame.Health:GetFrameLevel() - 5)
		end

		--Hide mover until we detach again
		if not frame.POWERBAR_DETACHED then
			if mana.Holder and mana.Holder.mover then
				mana.Holder.mover:SetScale(0.0001)
				mana.Holder.mover:SetAlpha(0)
			end
		end

		if db.power.strataAndLevel and db.power.strataAndLevel.useCustomStrata then
			mana:SetFrameStrata(db.power.strataAndLevel.frameStrata)
		else
			mana:SetFrameStrata("LOW")
		end
		if db.power.strataAndLevel and db.power.strataAndLevel.useCustomLevel then
			mana:SetFrameLevel(db.power.strataAndLevel.frameLevel)
			mana.backdrop:SetFrameLevel(mana:GetFrameLevel() - 1)
		end

		if frame.POWERBAR_DETACHED and db.power.parent == "UIPARENT" then
			mana:SetParent(E.UIParent)
		else
			mana:SetParent(frame)
		end

	elseif frame:IsElementEnabled("Mana") then
		frame:DisableElement("Mana")
		mana:Hide()
		frame:Tag(mana.value, "")
	end

	--Transparency Settings
	UF:ToggleTransparentStatusBar(UF.db.colors.transparentPower, frame.Mana, frame.Mana.bg)
end

local tokens = {[0] = "MANA", "RAGE", "FOCUS", "ENERGY", "RUNIC_POWER"}

function UF:PostUpdateMana(unit, _, max)
	local parent = self:GetParent()

	if parent.isForced then
		local color = ElvUF.colors.power.MANA
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