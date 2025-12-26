repeat task.wait() until game:IsLoaded()
if shared.vape then shared.vape:Uninject() end

if identifyexecutor then
	if table.find({'Argon','Wave'}, ({identifyexecutor()})[1]) then
		getgenv().setthreadidentity = nil
	end
end

local vape
local loadstring = function(...)
	local res, err = loadstring(...)
	if err and vape then
		vape:CreateNotification('Vape','Failed to load : '..err,30,'alert')
	end
	return res
end

local queue_on_teleport = queue_on_teleport or function() end

local isfile = isfile or function(file)
	local ok, res = pcall(readfile, file)
	return ok and res ~= nil and res ~= ''
end

local delfile = delfile or function(file)
	pcall(writefile, file, '')
end

local cloneref = cloneref or function(o) return o end
local playersService = cloneref(game:GetService('Players'))

local function downloadFile(path, func)
	if not isfile(path) then
		local ok, res = pcall(function()
			return game:HttpGet(
				"https://raw.githubusercontent.com/a9x4/VapeV4ForRoblox/"..
				(readfile("newvape/profiles/commit.txt") or "main").."/"..
				select(1, path:gsub("newvape/","")),
				true
			)
		end)
		if not ok or not res or res == "404: Not Found" then
			error(res or "download failed")
		end
		if path:sub(-4) == ".lua" then
			res = "--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n"..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in ipairs(listfiles(path)) do
		if not file:find("loader") and isfile(file) then
			local data = readfile(file)
			if data and data:find("^%-%-This watermark is used to delete the file") then
				delfile(file)
			end
		end
	end
end

for _, folder in ipairs({
	"newvape","newvape/games","newvape/profiles",
	"newvape/assets","newvape/libraries","newvape/guis"
}) do
	if not isfolder(folder) then
		makefolder(folder)
	end
end

if not shared.VapeDeveloper then
	local _, page = pcall(function()
		return game:HttpGet("https://github.com/a9x4/VapeV4ForRoblox")
	end)
	local commit = page and page:match("currentOid.-(%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w%w)") or "main"
	if commit == "main" or (isfile("newvape/profiles/commit.txt") and readfile("newvape/profiles/commit.txt") ~= commit) then
		wipeFolder("newvape")
		wipeFolder("newvape/games")
		wipeFolder("newvape/guis")
		wipeFolder("newvape/libraries")
	end
	writefile("newvape/profiles/commit.txt", commit)
end

local function finishLoading()
	vape.Init = nil
	vape:Load()
	task.spawn(function()
		repeat
			vape:Save()
			task.wait(10)
		until not vape.Loaded
	end)

	local teleported
	vape:Clean(playersService.LocalPlayer.OnTeleport:Connect(function()
		if not teleported and not shared.VapeIndependent then
			teleported = true
			local script = [[
shared.vapereload = true
loadstring(game:HttpGet("https://raw.githubusercontent.com/a9x4/VapeV4ForRoblox/"..readfile("newvape/profiles/commit.txt").."/loader.lua",true),"loader")()
]]
			vape:Save()
			queue_on_teleport(script)
		end
	end))

	if not shared.vapereload and vape.Categories then
		if vape.Categories.Main.Options["GUI bind indicator"].Enabled then
			vape:CreateNotification(
				"Finished Loading",
				vape.VapeButton and
				"Press the button in the top right to open GUI" or
				("Press "..table.concat(vape.Keybind," + "):upper().." to open GUI"),
				5
			)
		end
	end
end

if not isfile("newvape/profiles/gui.txt") then
	writefile("newvape/profiles/gui.txt","new")
end

local gui = readfile("newvape/profiles/gui.txt")
if not isfolder("newvape/assets/"..gui) then
	makefolder("newvape/assets/"..gui)
end

vape = loadstring(downloadFile("newvape/guis/"..gui..".lua"),"gui")()
shared.vape = vape

if not shared.VapeIndependent then
	loadstring(downloadFile("newvape/games/universal.lua"),"universal")()
	if isfile("newvape/games/"..game.PlaceId..".lua") then
		loadstring(readfile("newvape/games/"..game.PlaceId..".lua"),tostring(game.PlaceId))(...)
	end
	finishLoading()
else
	vape.Init = finishLoading
	return vape
end