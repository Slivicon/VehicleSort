------------------------------------------------------------------
-- VehicleSort Version 0.6
-- Author: Dschonny
-- Project started: 8. Nov. 2014
-- last update: 17. Nov. 2016

-- changelog:
-- V0.1:
-- Main functionality implemented
--		Vehicle sorting
--		Fast switching

-- V0.2:
-- added customizable keys (via modDesc)
-- added mouse-controls
-- fixed init to solve No-sorting-on-map-restart-bug
-- fixed P:false-output in log

-- V0.3:
-- fixed bug when buying/selling vehicles
-- fixed bug when showing multiple columns 

-- V0.4:
-- added parking functionality
-- activated multiplayer-support

-- V0.4.1
-- parking active vehicle implemented
-- fixed seldom fastswitch-bug (hopefully)

-- V0.5
-- Rough conversion to FS17
-- Parking disabled (needs bigger rework for LS17)

-- V0.5.1
-- Fixed fast switching bug
-- Re-added parking
-- catching train and train-crane-names
-- added config-Menu
--		show/hide brand names
-- 		show/hide vehicle type
--		show/hide trains
-- 		show/hide train-cranes

-- V0.5.2
-- Fixed l10n-error in log
-- Changed description in modDesc to FS17

-- V0.6 
-- Fixed VS to properly work with FS17 patch 1.3
-- Added Option to show/hide names of other players
-- Added Option to show Fill-Levels of vehiles in List (Total/percentage)


-- **************************************************************
-- This mod may be distributed freely as long as it is unchanged!
-- **************************************************************

-----------------------------------------------------------------

vsClass ={};

-- Config Vars
-- Text Layout
vsClass.tPos = {};
vsClass.tPos.x = 0.3;								-- x Position of Textfield
vsClass.tPos.y = 0.9;								-- y Position of Textfield
vsClass.tPos.size = 0.018;							-- TextSize
vsClass.tPos.spacing = 0.005;						-- Spacing between lines
vsClass.tPos.columnWidth = 0.35;					-- Space till second column (only if needed)
vsClass.tPos.alignment = RenderText.ALIGN_LEFT;		-- Text Alignment

-- Text Colors
vsClass.tColor = {};
vsClass.tColor.standard = {1.0, 1.0, 1.0, 1.0}; 	-- white
vsClass.tColor.selected = {0.0, 1.0, 0.0, 1.0}; 	-- green
vsClass.tColor.locked = {1.0, 0.0, 0.0, 1.0}; 		-- red
vsClass.tColor.parked = {0.5, 0.5, 0.5, 0.7};		-- grey 

-- InGameConfig
vsClass.config = {
	{"showTrain", true},
	{"showCrane", false},
	{"showBrand", false},
	{"showType", false},
	{"showNames", true},
	{"showFillLevels", true},
	{"showPercentages", true},
	{"showEmpty", false}
};



-- Internal Vars
vsClass.showSteerables = false;
vsClass.selectedIndex = 1;
vsClass.selectedConfigIndex = 1;
vsClass.selectedLock = false;
vsClass.borderToTop = 1 - vsClass.tPos.y;
vsClass.showConfig = false;

vsClass.vInitOrder = {};
vsClass.vUserOrder = {};

vsClass.userPath = "";
vsClass.vsBasePath = "";
vsClass.vsSavePath = "";
vsClass.vsXML = "";
vsClass.saveFile = 0;

vsClass.vsConfigXML = "";
vsClass.vsConfigSaveFile = 0;

vsClass.debugOnScreen = {{"DebugOnScreenActive", 100}};

vsClass.showDebugOnScreen = false;
vsClass.DEBUG = false;
vsClass.execTestFunc = false;

vsClass.vsInitialized = false;

-- Register as event listener
addModEventListener(vsClass);


local vsClass_mt = Class(vsClass, Mission00);


function vsClass:new(baseDirectory, customMt)
    local mt = customMt;
    if mt == nil then
        mt = SampleModMap_mt;
    end;
    local self = SampleModMap:superClass():new(baseDirectory, mt);

    return self;
end;

function vsClass:loadSteerable(xmlFile)
	if self.vs_brandName == nil then self.vs_brandName = getXMLString(self.xmlFile, "vehicle.storeData.brand"); end
	if self.vs_name == nil then self.vs_name = getXMLString(self.xmlFile, "vehicle.storeData.name"); end
	-- Fallback-Naming
	if self.vs_brandName == nil or self.vs_brandName == "" then self.vs_brandName = "(?)"; end
	if self.vs_name == nil then self.vs_name = getXMLString(self.xmlFile, "vehicle.storeData.name.".. g_languageShort); end
	if self.vs_name == nil then self.vs_name = getXMLString(self.xmlFile, "vehicle.storeData.name"); end
	if self.vs_name == nil then self.vs_name = getXMLString(self.xmlFile, "vehicle.name.".. g_languageShort); end
	if self.vs_name == nil then self.vs_name = getXMLString(self.xmlFile, "vehicle.name"); end
	if self.vs_name == nil then self.vs_name = getXMLString(self.xmlFile, "vehicle#type"); end
	if self.vs_name == nil then self.vs_name = "Steerable"; end
end
Steerable.load  = Utils.appendedFunction(Steerable.load, vsClass.loadSteerable);

function vsClass:loadAttachable(xmlFile)
	if self.vs_brandName == nil then self.vs_brandName = getXMLString(self.xmlFile, "vehicle.storeData.brand"); end
	if self.vs_name == nil then self.vs_name = getXMLString(self.xmlFile, "vehicle.storeData.name"); end
	-- Fallback-Naming
	if self.vs_brandName == nil or self.vs_brandName == "" then self.vs_brandName = "(?)"; end
	if self.vs_name == nil then self.vs_name = getXMLString(self.xmlFile, "vehicle.storeData.name.".. g_languageShort); end
	if self.vs_name == nil then self.vs_name = getXMLString(self.xmlFile, "vehicle.storeData.name"); end
	if self.vs_name == nil then self.vs_name = getXMLString(self.xmlFile, "vehicle.name.".. g_languageShort); end
	if self.vs_name == nil then self.vs_name = getXMLString(self.xmlFile, "vehicle.name"); end
	if self.vs_name == nil then self.vs_name = getXMLString(self.xmlFile, "vehicle#type"); end
	if self.vs_name == nil then self.vs_name = "Attachable"; end
end
Attachable.load = Utils.appendedFunction(Attachable.load, vsClass.loadAttachable);


function vsClass:keyEvent(unicode, sym, modifier, isDown)
	if isDown then
		-- dprint("Key Down - Unicode: " .. tostring(unicode).. " sym: " .. tostring(sym) .. " modifier: " .. tostring(modifier) .. " isDown: " .. tostring(isDown));
		-- vsClass:debPrint("Key Down - Unicode: " .. tostring(unicode).. " sym: " .. tostring(sym) .. " modifier: " .. tostring(modifier) .. " isDown: " .. tostring(isDown));
		--[[
		if vsClass.showKeyPress then
			vsClass.lastKey.sym = sym;
			vsClass.lastKey.unicode = unicode;
			vsClass.lastKey.modifier = modifier;
			for i,j in pairs(InputBinding) do
				if j ~= nil then 
					if InputBinding.isPressed(j) then
						vsClass.lastKey.inBind = "InputBinding."..tostring(i);
					end
				end
			end
		end
		--]]
		
		if sym == 27 then -- Esc-Key
			vsClass.showSteerables = false;
			vsClass:saveVehicleOrder();
			vsClass.selectedLock = false;
			-- testFunc();
		end
		
		-- if sym == 271 and modifier == 64 then
			-- g_client:getServerConnection():sendEvent(VehicleEnterRequestEvent:new(g_currentMission.steerables[vsClass.selectedIndex], g_gameSettings.nickname, g_currentMission.player.id, g_currentMission.player.playerColorIndex));
			-- g_server:broadcastEvent(VehicleEnterRequestEvent:new(g_currentMission.steerables[vsClass.selectedIndex], g_gameSettings.nickname, g_currentMission.player.id, g_currentMission.player.playerColorIndex));
		-- end
		
	end
end

function vsClass:moveUp()
	local oldIndex = vsClass.selectedIndex;
	vsClass.selectedIndex = vsClass.selectedIndex - 1;
	if vsClass.selectedIndex < 1 then
		vsClass.selectedIndex = table.getn(g_currentMission.steerables);
	end
	if (string.find(g_currentMission.steerables[vsClass.selectedIndex].configFileName, "train/locomotive") and not vsClass.config[1][2]) 
		or (string.find(g_currentMission.steerables[vsClass.selectedIndex].configFileName, "train/stationCrane") and not vsClass.config[2][2]) then
			vsClass:moveUp();
	end
	if vsClass.selectedLock then
		vsClass:reSort(oldIndex, vsClass.selectedIndex);
	end
	
	
end	

function vsClass:moveDown()
	local oldIndex = vsClass.selectedIndex;
	vsClass.selectedIndex = vsClass.selectedIndex + 1;
	if vsClass.selectedIndex > table.getn(g_currentMission.steerables) then 
		vsClass.selectedIndex = 1; 
	end
	if (string.find(g_currentMission.steerables[vsClass.selectedIndex].configFileName, "train/locomotive") and not vsClass.config[1][2]) 
		or (string.find(g_currentMission.steerables[vsClass.selectedIndex].configFileName, "train/stationCrane") and not vsClass.config[2][2]) then
			vsClass:moveDown();
	end
	if vsClass.selectedLock then
		vsClass:reSort(oldIndex, vsClass.selectedIndex);
	end
	
end

function vsClass:reSort(oldPos, newPos)
	local tempElement = g_currentMission.steerables[oldPos];
	local tempIndex = vsClass.vUserOrder[oldPos];
	table.remove(g_currentMission.steerables, oldPos);
	table.remove(vsClass.vUserOrder, oldPos);
	table.insert(g_currentMission.steerables, newPos, tempElement);
	table.insert(vsClass.vUserOrder, newPos, tempIndex);
	tempElement = nil;
end

function vsClass:toggleParkState(index)
	--[[
	if not g_currentMission.steerables[index].vs_isParked then
			if not g_currentMission.steerables[index].isControlled then
			g_currentMission.steerables[index].vs_isParked = true;
			g_currentMission.steerables[index].isControlled = true;
			g_currentMission.steerables[index].controllerName = "<P>";
			g_currentMission.steerables[index]:setCharacterVisibility(false);
		end
	else
		g_currentMission.steerables[index].vs_isParked = false;
		g_currentMission.steerables[index].isControlled = false;
		g_currentMission.steerables[index].controllerName = "";
	end
	--]]
	g_currentMission.steerables[index].nonTabbable = not g_currentMission.steerables[index].nonTabbable;
end

function vsClass:update(dt)
	if not vsClass.vsInitialized  then  
		vsClass:vsInit();
		vsClass.vsInitialized = true;
		
	end
	
	if InputBinding.hasEvent(InputBinding.vs_showConfig) then
		if vsClass.showSteerables and not vsClass.showConfig then vsClass.showSteerables = false; end
		vsClass.showConfig = not vsClass.showConfig;
	end
	
	if vsClass.showConfig then
		if InputBinding.hasEvent(InputBinding.vs_moveCursorUp) then
			vsClass.selectedConfigIndex = vsClass.selectedConfigIndex - 1;
			if vsClass.selectedConfigIndex <= 0 then
				vsClass.selectedConfigIndex = table.getn(vsClass.config);
			end
		elseif InputBinding.hasEvent(InputBinding.vs_moveCursorDown) then
			vsClass.selectedConfigIndex = vsClass.selectedConfigIndex + 1;
			if vsClass.selectedConfigIndex > table.getn(vsClass.config) then
				vsClass.selectedConfigIndex = 1;
			end
		elseif InputBinding.hasEvent(InputBinding.vs_lockListItem) then 
			vsClass.config[vsClass.selectedConfigIndex][2] = not vsClass.config[vsClass.selectedConfigIndex][2];
			vsClass:saveVehicleOrder();
		end
		
	end
	
	if InputBinding.hasEvent(InputBinding.vs_toggleList) then
		if vsClass.showSteerables then
			vsClass.showSteerables = false;
			vsClass.selectedLock = false;
			vsClass:saveVehicleOrder();
		else
			vsClass.showSteerables = true;
			vsClass.showConfig = false;
		end
	end
	
	if vsClass.showSteerables then
		if InputBinding.hasEvent(InputBinding.vs_moveCursorUp) then
			vsClass:moveUp();
		elseif InputBinding.hasEvent(InputBinding.vs_moveCursorDown) then
			vsClass:moveDown();
		elseif InputBinding.hasEvent(InputBinding.vs_lockListItem) then 
			if not vsClass.selectedLock and vsClass.selectedIndex > 0 then
				vsClass.selectedLock = true;
			elseif vsClass.selectedLock then
				vsClass.selectedLock = false;
			end
		elseif InputBinding.hasEvent(InputBinding.vs_changeVehicle) then
			--[[
			if g_currentMission.steerables[vsClass.selectedIndex].vs_isParked then
				vsClass:toggleParkState(vsClass.selectedIndex);
			end
			--]]
			if g_currentMission.steerables[vsClass.selectedIndex].isControlled == false then
				-- g_client:getServerConnection():sendEvent(VehicleEnterRequestEvent:new(g_currentMission.steerables[vsClass.selectedIndex], g_gameSettings.nickname));
				-- g_client:getServerConnection():sendEvent(VehicleEnterRequestEvent:new(g_currentMission.steerables[vsClass.selectedIndex], g_gameSettings.nickname, g_currentMission.player.id, g_currentMission.player.playerColorIndex));
				-- g_server:broadcastEvent(VehicleEnterRequestEvent:new(g_currentMission.steerables[vsClass.selectedIndex], g_gameSettings.nickname, g_currentMission.player.id, g_currentMission.player.playerColorIndex));
				g_currentMission:requestToEnterVehicle(g_currentMission.steerables[vsClass.selectedIndex]);
				-- g_currentMission.steerables[vsClass.selectedIndex]:enterVehicle(true, g_currentMission.player.id, g_currentMission.player.playerColorIndex);
			end;
		
		elseif InputBinding.hasEvent(InputBinding.vs_togglePark) then
			vsClass:toggleParkState(vsClass.selectedIndex);
			--[[
			if g_currentMission.steerables[vsClass.selectedIndex].controllerName == g_gameSettings.nickname then
				local newIndex = 0;
				for i = vsClass.selectedIndex, table.getn(g_currentMission.steerables) do
					if not g_currentMission.steerables[i].isControlled then
						newIndex = i;
						break;
					end
				end
				if newIndex == 0 then 
					for i =1,  vsClass.selectedIndex do
						if not g_currentMission.steerables[i].isControlled then
							newIndex = i;
							break;
						end
					end
				end
				if newIndex > 0 then
					g_client:getServerConnection():sendEvent(VehicleEnterRequestEvent:new(g_currentMission.steerables[newIndex], g_gameSettings.nickname));
					vsClass:toggleParkState(vsClass.selectedIndex);
				else
					print("VehicleSort: Can't park vehicle - all other vehicles parked or occupied!");
				end
				
			else 
				vsClass:toggleParkState(vsClass.selectedIndex);
			end
			--]]
		end
	end
end;

function vsClass:drawConfig()
	local cCount = table.getn(vsClass.config);
	
	if vsClass.showConfig then
		local lineCount = 0;
		local xPos = vsClass.tPos.x;
		local yPos = vsClass.tPos.y;
		setTextColor(unpack(vsClass.tColor.standard));
		setTextAlignment(vsClass.tPos.alignment);
		renderText(xPos, yPos + vsClass.tPos.size + vsClass.tPos.spacing + 0.007, vsClass.tPos.size + 0.005, g_i18n:getText("configHeadline"));
		for i=1, cCount do
			if i == vsClass.selectedConfigIndex then
				setTextColor(unpack(vsClass.tColor.selected));
			else
				setTextColor(unpack(vsClass.tColor.standard));
			end
			local rText = g_i18n:getText(vsClass.config[i][1])..":";
			local state = tostring(vsClass.config[i][2]);
			if state == "true" then state = g_i18n:getText("vs_on");
			else state = g_i18n:getText("vs_off"); end
			renderText(xPos, yPos, vsClass.tPos.size, rText);
			renderText(xPos + vsClass.tPos.columnWidth, yPos, vsClass.tPos.size, state);
			
			yPos = yPos - vsClass.tPos.size - vsClass.tPos.spacing;
		end
	end

end


function vsClass:draw()
	local sCount = table.getn(g_currentMission.steerables);
	
	vsClass.drawConfig();
	if vsClass.showDebugOnScreen then vsClass:drawDebugText(); end
	
	if vsClass.showSteerables and sCount > 0 then
		local lineCount = 0;
		local xPos = vsClass.tPos.x;
		local yPos = vsClass.tPos.y;
		setTextColor(unpack(vsClass.tColor.standard));
		setTextAlignment(vsClass.tPos.alignment);
		renderText(xPos, yPos + vsClass.tPos.size + vsClass.tPos.spacing + 0.007, vsClass.tPos.size + 0.005, g_i18n:getText("headline"));
		for i=1, sCount do
			if i == vsClass.selectedIndex then
				if vsClass.selectedLock then
					setTextColor(unpack(vsClass.tColor.locked));
				else
					setTextColor(unpack(vsClass.tColor.selected));
				end
			elseif g_currentMission.steerables[i].vs_isParked then
				setTextColor(unpack(vsClass.tColor.parked));
			else
				setTextColor(unpack(vsClass.tColor.standard));
			end
			if g_currentMission.steerables[i].isControlled and g_currentMission.steerables[i].controllerName == g_gameSettings.nickname then
				setTextBold(true);
			else
				setTextBold(false);
			end
			local showText = true;
			if not vsClass.config[1][2] and string.find(g_currentMission.steerables[i].configFileName, "train/locomotive") then showText = false; end
			if not vsClass.config[2][2] and string.find(g_currentMission.steerables[i].configFileName, "train/stationCrane") then showText = false; end
			
			if showText then
				renderText(xPos, yPos, vsClass.tPos.size, vsClass:getFullVehicleName(i));
				yPos = yPos - vsClass.tPos.size - vsClass.tPos.spacing;
			end
			
			if yPos < vsClass.borderToTop then
				yPos = vsClass.tPos.y;
				xPos = xPos + vsClass.tPos.columnWidth;
			end
			
		end
	end
	
	
end

function vsClass:drawDebugText()
	local debText = "";
	local itemsToRemove = {};
	if vsClass.debugOnScreen ~= nil and #vsClass.debugOnScreen > 0 then
		for i,j in ipairs(vsClass.debugOnScreen) do
			if j[2] > 0 then
				debText = debText..j[1].." | ";
				j[2] = j[2]-1;
			else
				table.insert(itemsToRemove, i);
			end
		end
		if #itemsToRemove > 0 then
			for i= #itemsToRemove, 1, -1 do
				table.remove(vsClass.debugOnScreen, i);
			end
		end
	end
	
	setTextColor(unpack(vsClass.tColor.standard));
	setTextAlignment(vsClass.tPos.alignment);
	renderText(0.05, 0.25, vsClass.tPos.size, debText);
end

function vsClass:debPrint(text, fadeTime)
	local fTime = fadeTime or 400;
	local elem = {text, fTime};
	table.insert(vsClass.debugOnScreen, elem);
end

function vsClass:loadMap(name)
	vsClass.vsInitialized = false;
end;

function vsClass:deleteMap()
	vsClass.vInitOrder = {};
	vsClass.vUserOrder = {};
	vsClass.vsInitialized = false;
end;

function vsClass:mouseEvent(posX, posY, isDown, isUp, button)
end;

function vsClass:vsInit()
	vsClass.userPath = getUserProfileAppPath();
	vsClass.vsBasePath = vsClass.userPath .. "vehicleSort/";
	vsClass.vsSavePath = vsClass.vsBasePath .. "savegame" .. g_careerScreen.selectedIndex .. "/";
	createFolder(vsClass.vsBasePath);
	createFolder(vsClass.vsSavePath);
	
	vsClass.vsXML = vsClass.vsSavePath.."v_order.xml";
	vsClass.vsConfigXML = vsClass.vsSavePath.."vsConfig.xml";
	
	vsClass:loadVehicleOrder();
	
	if vsClass.execTestFunc then
		testFunc();
	end
	
	print("VehicleSort initialized");
end

function vsClass.addVehic(a, b)
	if b.isSteerable then 
		local listItem = {};
		listItem.ranking = #vsClass.vInitOrder + 1;
		listItem.id = b.id;
		table.insert(vsClass.vInitOrder, listItem);
		if vsClass.vsInitialized then
			local listItem = {};
			listItem.ranking = #vsClass.vUserOrder + 1;
			listItem.id = b.id;
			table.insert(vsClass.vUserOrder, listItem);
		end
		b.vs_isParked = false;
	end
end

function vsClass.removeVehic(a, b)
	if b.isSteerable then
		-- print("Steerable sold!");
		b.vs_isParked = nil;
		local remIndex = 0;
		local modRank = #vsClass.vUserOrder;
		for i,j in ipairs(vsClass.vUserOrder) do
			if j.id == b.id then
				remIndex = i;
				modRank = j.ranking
			end
		end
		if remIndex > 0 then
			table.remove(vsClass.vUserOrder, remIndex);
		else
			print("VehicleSort: Error removing sold Vehicle from User-List!");
		end
		for i,j in ipairs(vsClass.vUserOrder) do
			if j.ranking > modRank then
				j.ranking = j.ranking - 1;
			end
		end
	end
end

function vsClass:getFullVehicleName(index)
	local vehName = "";
	if index <= table.getn(g_currentMission.steerables) then
		-- Prefix for vehicles parked or controlled by other players
		if g_currentMission.steerables[index].vs_isParked or g_currentMission.steerables[index].nonTabbable then
			vehName = "<P> ";
		elseif vsClass.config[5][2] 
		 and g_currentMission.steerables[index].controllerName ~= g_gameSettings.nickname 
		 and g_currentMission.steerables[index].controllerName ~= "Unknown" 
		 and g_currentMission.steerables[index].controllerName ~= "" 
		 and g_currentMission.steerables[index].controllerName ~= nil then
			vehName = "("..g_currentMission.steerables[index].controllerName..") ";
		end
		
		-- Catch train and train crane
		if string.find(g_currentMission.steerables[index].configFileName, "train/locomotive") then 
			vehName = vehName..g_i18n:getText("vs_train"); 
			if vsClass.config[6][2] then  -- Fill-Level-Display active?
				local f, c = vsClass.calculateFillLevel(g_currentMission.steerables[index]);
				if vsClass.config[8][2] or f > 0 then -- Empty vehicles shall be shown or vehicle is not empty
					if vsClass.config[7][2] and c > 0 then -- Fill-Level->Total Values
						local p = vsClass.calcPercentage(f, c);
						vehName = vehName.." ("..tostring(p).."%)";
					elseif c > 0 then -- Fill-Level-->Percentages
						vehName = vehName.." ("..tostring(math.floor(f)).."/"..tostring(c)..")";
					end
				end
			end
			return vehName; 
		elseif string.find(g_currentMission.steerables[index].configFileName, "train/stationCrane") then 
			vehName = vehName..g_i18n:getText("vs_crane"); 
			return vehName; 
		end
		
		-- steerable
		if vsClass.config[3][2] then vehName = vehName..g_currentMission.steerables[index].vs_brandName.." "; end
		vehName = vehName..g_currentMission.steerables[index].vs_name;
		if vsClass.config[4][2] then vehName = vehName.." ("..Utils.getNoNil(g_currentMission.steerables[index].typeDesc, "?")..")"; end
		
		-- first attachment
		if (g_currentMission.steerables[index].attachedImplements[1] ~= nil and g_currentMission.steerables[index].attachedImplements[1].object ~= nil) then
			vehName = vehName .. " - ".. g_i18n:getText("with") .." '";
			if vsClass.config[3][2] then vehName  = vehName..g_currentMission.steerables[index].attachedImplements[1].object.vs_brandName.." "; end
			vehName = vehName.. Utils.getNoNil(g_currentMission.steerables[index].attachedImplements[1].object.vs_name, "(implement1)") .."'";
			if vsClass.config[4][2] then vehName = vehName.." ("..Utils.getNoNil(g_currentMission.steerables[index].attachedImplements[1].object.typeDesc, "")..")"; end
			
			-- second attachment
			if (g_currentMission.steerables[index].attachedImplements[2] ~= nil and g_currentMission.steerables[index].attachedImplements[2].object ~= nil) then
				vehName = vehName .. " & '";
				if vsClass.config[3][2] then vehName  = vehName..g_currentMission.steerables[index].attachedImplements[2].object.vs_brandName.." "; end
				vehName = vehName .. Utils.getNoNil(g_currentMission.steerables[index].attachedImplements[2].object.vs_name, "(implement2)") .."'";
				if vsClass.config[4][2] then vehName = vehName.." ("..Utils.getNoNil(g_currentMission.steerables[index].attachedImplements[2].object.typeDesc, "")..")"; end
			end;
        end;
		
		-- Fill-Level-Display
		if vsClass.config[6][2] then  -- Fill-Level-Display active?
			local f, c = vsClass.calculateFillLevel(g_currentMission.steerables[index]);
			if vsClass.config[8][2] or f > 0 then -- Empty vehicles shall be shown or vehicle is not empty
				if vsClass.config[7][2] and c > 0 then -- Fill-Level->Total Values
					local p = vsClass.calcPercentage(f, c);
					vehName = vehName.." ("..tostring(p).."%)";
				elseif c > 0 then -- Fill-Level-->Percentages
					vehName = vehName.." ("..tostring(math.floor(f)).."/"..tostring(c)..")";
				end
			end
		end
		
		return vehName;
	else
		return nil;
	end
end

function vsClass:saveVehicleOrder()
	vsClass.saveFile = createXMLFile("vsClass.saveFile", vsClass.vsXML, "vOrder");
	dprint("Saving Config");
	for i=1, #vsClass.config do
		setXMLBool(vsClass.saveFile, "vOrder.vsConfig#"..vsClass.config[i][1],vsClass.config[i][2])
	end
	
	dprint(#vsClass.vUserOrder.." needs to be saved!");
	for i=1, #vsClass.vUserOrder do
		dprint("Saving vehicle "..i);
		setXMLInt(vsClass.saveFile, "vOrder.vehicle"..i.."#id", vsClass.vUserOrder[i].ranking);
		-- setXMLBool(vsClass.saveFile, "vOrder.vehicle"..i.."#parked", g_currentMission.steerables[i].vs_isParked);
		setXMLBool(vsClass.saveFile, "vOrder.vehicle"..i.."#parked", g_currentMission.steerables[i].nonTabbable);
	end
	saveXMLFile(vsClass.saveFile);
end


function vsClass:loadVehicleOrder()
	vsClass.saveFile = createXMLFile("vsClass.loadFile", vsClass.vsXML, "vOrder");
	vsClass.saveFile = loadXMLFile("vsClass.loadFile", vsClass.vsXML);
	if not hasXMLProperty(vsClass.saveFile, "vOrder") then
		print(g_i18n:getText("vOrderMissing"));
		for i = 1, table.getn(g_currentMission.steerables) do
			local listItem = {};
			listItem.ranking = i;
			listItem.id = g_currentMission.steerables[i].id;
			vsClass.vUserOrder[i]= listItem;
		end
	else
		local vIndex = 1;
		local savedIDs = {};
		local savedParkStates = {};
		while hasXMLProperty(vsClass.saveFile, "vOrder.vehicle"..vIndex.."#id") do
			table.insert(savedIDs, getXMLInt(vsClass.saveFile, "vOrder.vehicle"..vIndex.."#id"));
			table.insert(savedParkStates, getXMLBool(vsClass.saveFile, "vOrder.vehicle"..vIndex.."#parked"));
			dprint("Recognized Order Index: "..savedIDs[vIndex]);
			vIndex = vIndex + 1;
		end
		local vTSize = table.getn(g_currentMission.steerables);
		if #savedIDs == vTSize then
			dprint("Size Match savedIDs ("..#savedIDs..") <-> globalVehicleTableSize ("..vTSize..")!");
			for i = 1, vTSize do
				dprint("Moving away from Table Position "..i);
				local listItem = {};
				listItem.ranking = tonumber(savedIDs[i]);
				vsClass.vUserOrder[i] = listItem;
				local eBreaker = 0;
				while vsClass.vInitOrder[i].ranking ~= vsClass.vUserOrder[i].ranking and eBreaker <= (vTSize + 10) do
					dprint("Moving ID "..vsClass.vInitOrder[i].ranking.. " - eBreaker: "..eBreaker);
					eBreaker = eBreaker + 1;
					local tempIndex = vsClass.vInitOrder[i];
					local tempVehicle = g_currentMission.steerables[i];
					
					table.remove(vsClass.vInitOrder, i);
					table.remove(g_currentMission.steerables, i);
					
					table.insert(vsClass.vInitOrder, vTSize, tempIndex);
					table.insert(g_currentMission.steerables, vTSize, tempVehicle);
				end
			end
			for i=1, vTSize do
				vsClass.vUserOrder[i].id = g_currentMission.steerables[i].id;
			end
			for index, isParked in ipairs(savedParkStates) do
				g_currentMission.steerables[index].nonTabbable = isParked;
				--[[if isParked then 
					vsClass:toggleParkState(index);
				end
				--]]
			end
		else
			print("VehicleSort: SaveFile corrupt! Using standard vehicle order!");
			for i = 1, table.getn(g_currentMission.steerables) do
				local listItem = {};
				listItem.ranking = i;
				listItem.id = g_currentMission.steerables[i].id;
				vsClass.vUserOrder[i] = listItem;
			end
		end
	end
	
	if not hasXMLProperty(vsClass.saveFile, "vOrder.vsConfig") then
		dprint("No Config Data found!");
	else
		dprint("Config data found!");
		for i = 1, #vsClass.config do
			local aBool = getXMLBool(vsClass.saveFile, "vOrder.vsConfig#"..vsClass.config[i][1] );
			if aBool ~= nil then vsClass.config[i][2] = aBool; end
		end
	end
end

function vsClass.calculateFillLevel(vehic, d)
	local fillLev = 0;
	local cap = 0;
	local depth = 0;
	if d ~= nil then depth = d; end
	-- print("calcFL-Depth: "..tostring(depth));
	depth = depth + 1;
	
	if vehic ~= nil then
		if vehic.getFillLevel ~= nil then
			fillLev = fillLev + vehic:getFillLevel();
		end
		if vehic.getCapacity ~= nil then
			cap = cap + vehic:getCapacity();
		end
		
		-- recursively go through attachments
		for _,imp in pairs(vehic.attachedImplements) do
			if imp.object ~= nil then
				-- print("Checking attachment: "..tostring(imp.object.typeDesc));
				local f, c = vsClass.calculateFillLevel(imp.object, depth);
				if f ~= nil and c ~= nil then
					fillLev = fillLev + f;
					cap = cap + c;
				end
			end
		end
	end 
	return fillLev, cap;
end

function vsClass.calcPercentage(actualVal, maxVal)
	local perc = actualVal / maxVal * 100;
	return (math.floor(perc * 10)/10);
end


function testFunc()
	print("VehicleSort: Executing test function!");
	
	-- printTableData(Utils);
	-- printTableData(InputBinding);
	-- DebugUtil.printTableRecursively(g_client:getServerConnection(), "-->", 4, 2);
	-- DebugUtil.printTableRecursively(g_currentMission.steerables[1], "-->", 4, 2);
	-- printTableData(g_currentMission.steerables[1]);
	-- print("getRawKeyNames:.." .. tostring(InputBinding.getRawKeyNamesOfDigitalAction(InputBinding.vs_moveCursorUp)));
	-- print("getKeyNames: "..tostring(InputBinding:getKeyNames(InputBinding.vs_moveCursorUp)));
	-- printTableData(InputBinding.getRawKeyNamesOfDigitalAction(InputBinding.vs_moveCursorUp));
	-- printTableData(g_gameSettings);
	--[[
	for i,j in pairs(g_currentMission.steerables) do
		print("*************************************");
		print("Printing Data for Vehicle "..tostring(i));
		print("typeName: "..tostring(j.typeName));
		print("typeDesc: "..tostring(j.typeDesc));
		print("nonTabbable: "..tostring(j.nonTabbable));
		print("isSelectable: "..tostring(j.isSelectable));
		print("id: "..tostring(id));
		print("configFileName: "..tostring(j.configFileName));
		print("controllerName: |"..tostring(j.controllerName).."|".." (PlayerName: |"..g_gameSettings.nickname.."|");
		-- if(Utils.getNoNil(j.typeDesc, "?") ~= "Drescher") then
			-- print("Fill-Level: ("..tostring(j:getAttachedTrailersFillLevelAndCapacity()));
			local f, c = vsClass.calculateFillLevel(j);
			print("FillLevel: " ..tostring(f).." Capacity: "..tostring(c));
		-- end
		
		print("End of vehicle Data");
		print("*************************************");
	end
	--]]
end

function dprint(aString)
	if vsClass.DEBUG then 
		if type(aString) == "table" then
			printTableData(aString);
		else
			print("******* VEHICLE SORT DEBUG: *******:    "..tostring(aString)); 
		end
	end
end

function printTableData(aTable)
	if type(aTable) ~= "table" then 
		print("!!!!!!  Element "..tostring(aTable).." is no Table!");
	else
		print("*********************************************************");
		print("Printing Table Data: ("..tostring(aTable)..")" );
		print("#:   Key      |        Value");
		local output = "";
		local id = 1;
		for i,j in pairs(aTable) do
			-- print("Index: ".. tostring(i));
			print("tData: "..tostring(id).."  |  " .. tostring(i).."  |  "..tostring(j));
			--[[
			if type(j) == "table" then
				printTableData(j);
			end
			--]]
			
			id = id + 1;
		end
		print("*********************************************************");
	end
end


vsClass:superClass():superClass().addVehicle = Utils.appendedFunction(vsClass:superClass():superClass().addVehicle, vsClass.addVehic);
vsClass:superClass():superClass().removeVehicle = Utils.appendedFunction(vsClass:superClass():superClass().removeVehicle, vsClass.removeVehic);


print(" --- VehicleSort loaded --- ");


