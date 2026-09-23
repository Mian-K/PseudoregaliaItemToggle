--Constants
local MAX_COUNT = {}
	MAX_COUNT["attack"] = 1
	MAX_COUNT["powerBoost"] = 1
	MAX_COUNT["airKick"] = 1
	MAX_COUNT["slide"] = 1
	MAX_COUNT["SlideJump"] = 1
	MAX_COUNT["plunge"] = 1
	MAX_COUNT["chargeAttack"] = 1
	MAX_COUNT["wallRide"] = 1
	MAX_COUNT["airRecovery"] = 1
	MAX_COUNT["projectile"] = 1
	MAX_COUNT["Light"] = 1
	MAX_COUNT["sprint"] = 1
	MAX_COUNT["magicPiece"] = 3
	MAX_COUNT["magicHaste"] = 2
	MAX_COUNT["HealBoost"] = 2
	MAX_COUNT["damageBoost"] = 1
	MAX_COUNT["extraKick"] = 1
	MAX_COUNT["mobileHeal"] = 1

--Reference Hooks
local player_controller = {}
local game_instance = {}
function player_controller.hook()
	if player_controller.value == nil or not player_controller.value:IsValid() then
		player_controller.value = FindFirstOf("BP_PlayerGoatMain_C")
	end
	return player_controller.value
end
function game_instance.hook()
	if game_instance.value == nil or not game_instance.value:IsValid() then
		game_instance.value = FindFirstOf("MV_GameInstance_C")
	end
	return game_instance.value
end

-- Some things need to be loaded before this works for some reason... so we just delay by a few seconds.
ExecuteWithDelay(5000, function()
	-- dev mode sets up most things we want for free and seems to have no side effects.
	-- disabling dev mode makes it work only with Items we have
	-- and once we close the menu without an Item, can't regain it.
	
	game_instance.hook()["devMode?"] = true
	
	-- Pause Menu Construct Hook to fix a few things dev mode doesn't do for us.
	-- it just does most things to make the Pause Menu function for us.
	pre_PM, post_PM = RegisterHook("/Game/UI/UI_PauseMenu.UI_PauseMenu_C:Construct", function(Context)
		pause = Context:get()
		item_buttons = FindAllOf("UI_ItemButton_C")
		for _,item_button in pairs(item_buttons) do
			if item_button:GetPropertyValue("keyDisplay?") then goto continue end
			
			item_button.OnButtonBaseClicked:Add(item_button, FName("OnButtonBaseClicked_Event"))
			
			if game_instance.hook().upgradeTracker:Contains(item_button.upgradeName) then
				if game_instance.hook().upgradeTracker:Find(item_button.upgradeName):get() ~= 0 then
					goto continue
				end
			else
				 game_instance.hook().upgradeTracker:Add(item_button.upgradeName, 0)
			end
			local color = {}
				color.R = 0.05
				color.G = 0.05
				color.B = 0.05
				color.A = 1
			local image = item_button.Image_25
			
			if image:IsValid() then
				image:SetColorAndOpacity(color)
			end
			
			::continue::
		end
		
		ExecuteWithDelay(200,function()
			pause.UI_PauseInfoBox:ChangeTexts(
				FText("Item Toggle"),
				FText("Click on a Major Ability or Aspect to add or remove it."),
				FText("Automatically saves the game after changing the Items you are having.\n\n\n\nMod by Mian")
			)
		end)
	end)
	
	-- Now we just hook the Item Button Click Event and do our thing!
	pre_IB, post_IB = RegisterHook("/Game/UI/UI_ItemButton.UI_ItemButton_C:OnButtonBaseClicked_Event", function(Context)
		local button = Context:get()
		if button:GetPropertyValue("keyDisplay?") then return end
		
		local item_name = button.upgradeName
		local upgrades = game_instance.hook().upgradeTracker
		if upgrades:Contains(item_name) then
			local count = upgrades:Find(item_name):get()
			local new_count = (count + 1) % (MAX_COUNT[item_name:ToString()] + 1)
			print(item_name:ToString() .. ": " .. new_count)
			game_instance.hook().upgradeTracker:Remove(item_name)
			game_instance.hook().upgradeTracker:Add(item_name, new_count)
			button.levelOfThing = new_count
			
			local color = {}
			if new_count == 0 then
				color.R = 0.05
				color.G = 0.05
				color.B = 0.05
				color.A = 1
			else
				color.R = 1
				color.G = 1
				color.B = 1
				color.A = 1
			end
			local image = button.Image_25
			if image:IsValid() then
				image:SetColorAndOpacity(color)
			end
			if button["Out Row"]["PowerupTier_26_A6DCAEEA473ADF8C601BC7A5C76D31FB"] == 1 then
				button:SendInfoHover(nil)
			end
			player_controller.hook():updateUpgrades(upgrades)
			game_instance.hook():InstSaveGameToSlot()
		end
	end)
end)
