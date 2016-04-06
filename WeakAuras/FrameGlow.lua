local unusedOverlayGlows = {};
local numOverlays = 0;
function ActionButton_GetOverlayGlow()
	local overlay = tremove(unusedOverlayGlows);
	if ( not overlay ) then
		numOverlays = numOverlays + 1;
		overlay = CreateFrame("Frame", "ActionButtonOverlay"..numOverlays, UIParent, "ActionBarButtonSpellActivationAlert");
	end
	return overlay;
end

function ActionButton_UpdateOverlayGlow(self)
	local spellType, id, subType  = GetActionInfo(self.action);
	if ( spellType == "spell" and IsSpellOverlayed(id) ) then
		ActionButton_ShowOverlayGlow(self);
	elseif ( spellType == "macro" ) then
		local _, _, spellId = GetMacroSpell(id);
		if ( spellId and IsSpellOverlayed(spellId) ) then
			ActionButton_ShowOverlayGlow(self);
		else
			ActionButton_HideOverlayGlow(self);
		end
	else
		ActionButton_HideOverlayGlow(self);
	end
end

function ActionButton_ShowOverlayGlow(self)
	if ( self.overlay ) then
		if ( self.fadeOutTime ~= nil ) then
			self.fadeOutTime = nil;
			ActionButton_OverlayGlowStartFadeIn(self.overlay);
		end
	else
		self.overlay = ActionButton_GetOverlayGlow();
		local frameWidth, frameHeight = self:GetSize();
		self.overlay:SetParent(self);
		self.overlay:ClearAllPoints();
		--Make the height/width available before the next frame:
		self.overlay:SetSize(frameWidth * 1.4, frameHeight * 1.4);
		self.overlay:SetPoint("TOPLEFT", self, "TOPLEFT", -frameWidth * 0.2, frameHeight * 0.2);
		self.overlay:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", frameWidth * 0.2, -frameHeight * 0.2);
		ActionButton_OverlayGlowStartFadeIn(self.overlay);
	end
end

function ActionButton_HideOverlayGlow(self)
	if ( self.overlay ) then
		if ( self.fadeInTime ~= nil ) then
			self.fadeInTime = nil;
		end
		if ( self:IsVisible() ) then
			ActionButton_OverlayGlowStartFadeOut(self.overlay);
		else
			ActionButton_OverlayGlowAnimOutFinished(self.overlay);	--We aren't shown anyway, so we'll instantly hide it.
		end
	end
end

function ActionButton_OverlayGlowAnimOutFinished(overlay)
	local actionButton = overlay:GetParent();
	overlay:Hide();
	tinsert(unusedOverlayGlows, overlay);
	actionButton.overlay = nil;
end

function ActionButton_OverlayGlowAnimateTexCoords(texture, textureWidth, textureHeight, frameWidth, frameHeight, numFrames, elapsed, throttle)
	if ( not texture.frame ) then
		-- initialize everything
		texture.frame = 1;
		texture.throttle = throttle;
		texture.numColumns = floor(textureWidth/frameWidth);
		texture.numRows = floor(textureHeight/frameHeight);
		texture.columnWidth = frameWidth/textureWidth;
		texture.rowHeight = frameHeight/textureHeight;
	end
	local frame = texture.frame;
	if ( not texture.throttle or texture.throttle > throttle ) then
		local framesToAdvance = floor(texture.throttle / throttle);
		while ( frame + framesToAdvance > numFrames ) do
			frame = frame - numFrames;
		end
		frame = frame + framesToAdvance;
		texture.throttle = 0;
		local left = mod(frame-1, texture.numColumns)*texture.columnWidth;
		local right = left + texture.columnWidth;
		local bottom = ceil(frame/texture.numColumns)*texture.rowHeight;
		local top = bottom - texture.rowHeight;
		texture:SetTexCoord(left, right, top, bottom);

		texture.frame = frame;
	else
		texture.throttle = texture.throttle + elapsed;
	end
end

function ActionButton_OverlayGlowStartFadeIn(self)
	local frameWidth, frameHeight = self:GetSize();
	self.spark:SetSize(frameWidth, frameHeight);
	self.spark:SetAlpha(0.3)
	self.innerGlow:SetSize(frameWidth / 2, frameHeight / 2);
	self.innerGlow:SetAlpha(1.0);
	self.innerGlowOver:SetSize(frameWidth / 2, frameHeight / 2);
	self.innerGlowOver:SetAlpha(1.0);
	self.outerGlow:SetSize(frameWidth * 2, frameHeight * 2);
	self.outerGlow:SetAlpha(1.0);
	self.outerGlowOver:SetSize(frameWidth * 2, frameHeight * 2);
	self.outerGlowOver:SetAlpha(1.0);
	self.ants:SetSize(frameWidth * 0.85, frameHeight * 0.85)
	self.ants:SetAlpha(0);
	self.fadeInTime = 0;
	self:Show();
end

function ActionButton_OverlayGlowAnimateFadeIn(self, elapsed)
	self.fadeInTime = self.fadeInTime + elapsed;
	local frameWidth, frameHeight = self:GetSize();
	if self.fadeInTime >= 0.5 then
		self.fadeInTime = nil;
		self.spark:SetAlpha(0);
		self.innerGlow:SetAlpha(0);
		self.innerGlow:SetSize(frameWidth, frameHeight);
		self.innerGlowOver:SetAlpha(0.0);
		self.outerGlow:SetSize(frameWidth, frameHeight);
		self.outerGlowOver:SetAlpha(0.0);
		self.outerGlowOver:SetSize(frameWidth, frameHeight);
		self.ants:SetAlpha(1.0);
		return
	end
	if self.fadeInTime > 0.3 then
		local progress = (self.fadeInTime - 0.3)/0.2;
		self.innerGlow:SetAlpha(1 - progress);
		self.ants:SetAlpha(progress);
	end
	if self.fadeInTime > 0.2 then
		local progress = (self.fadeInTime - 0.2)/0.2;
		local sparkScale = 1.5 - progress * 0.5;
		self.spark:SetSize(frameWidth * sparkScale, frameHeight * sparkScale);
		self.spark:SetAlpha(1 - progress);
	end
	if self.fadeInTime <= 0.3 then
		local progress = self.fadeInTime/0.3;
		local innerGlowScale = 0.5 + progress * 0.5;
		self.innerGlow:SetSize(frameWidth * innerGlowScale, frameHeight * innerGlowScale);
		self.innerGlowOver:SetSize(frameWidth * innerGlowScale, frameHeight * innerGlowScale);
		self.innerGlowOver:SetAlpha(1 - progress);
		local outerGlowScale = 2 - progress;
		self.outerGlow:SetSize(frameWidth * outerGlowScale, frameHeight * outerGlowScale);
		self.outerGlowOver:SetSize(frameWidth * outerGlowScale, frameHeight * outerGlowScale);
		self.outerGlowOver:SetAlpha(1 - progress);
	end
	if self.fadeInTime <= 0.2 then
		local progress = self.fadeInTime/0.2;
		local sparkScale = 1 + progress * 0.5;
		self.spark:SetSize(frameWidth * sparkScale, frameHeight * sparkScale);
		self.spark:SetAlpha(0.3 + progress * 0.7);
	end
end

function ActionButton_OverlayGlowStartFadeOut(self)
	self.fadeOutTime = 0;
end

function ActionButton_OverlayGlowAnimateFadeOut(self, elapsed)
	self.fadeOutTime = self.fadeOutTime + elapsed;
	if self.fadeOutTime >= 0.4 then
		ActionButton_OverlayGlowAnimOutFinished(self);
		return
	end
	if self.fadeOutTime > 0.2 then
		local progress = (self.fadeOutTime - 0.2)/0.2;
		self.outerGlowOver:SetAlpha(1 - progress);
		self.outerGlow:SetAlpha(1 - progress);
	end
	if self.fadeOutTime <= 0.2 then
		local progress = self.fadeOutTime/0.2;
		self.outerGlowOver:SetAlpha(progress);
		self.ants:SetAlpha(1 - progress);
	end
end