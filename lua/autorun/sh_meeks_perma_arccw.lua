ArcCW.detour_1 = ArcCW.detour_1 or ArcCW.PlayerGiveAtt
ArcCW.detour_2 = ArcCW.detour_2 or ArcCW.PlayerTakeAtt
currentPlayerAttachments = currentPlayerAttachments or {}

if not file.Exists("player_attachments", "DATA") then
    file.CreateDir("player_attachments")
end

local lastThink = CurTime() + 1
local lastFileContent = {}

if SERVER then

    hook.Add("PlayerSpawn", "GiveAttachmentsOnSpawn", function(ply)
        if CLIENT then return end

        local steamID64 = ply:SteamID64()
        local filePath = "player_attachments/" .. steamID64 .. ".txt"

        if file.Exists(filePath, "DATA") then
            local json = file.Read(filePath, "DATA")
            ply:SetPData("attachments", json)
            local savedAttachments = util.JSONToTable(json) or {}
            for att, amt in pairs(savedAttachments) do
                ArcCW:PlayerGiveAtt(ply, att, amt)
            end
            for att, amt in pairs(currentPlayerAttachments[steamID64] or {}) do
                if not savedAttachments[att] then
                    ArcCW:PlayerTakeAtt(ply, att, amt)
                end
            end

            currentPlayerAttachments[steamID64] = savedAttachments
        else
            for att, amt in pairs(currentPlayerAttachments[steamID64] or {}) do
                ArcCW:PlayerTakeAtt(ply, att, amt)
            end
            currentPlayerAttachments[steamID64] = {}
        end
    end)
end

hook.Add("Think", "42424242", function()
    if CLIENT then return end
    if lastThink <= CurTime() then
        for _, ply in pairs(player.GetAll()) do
            if not ply.loadedAttachments then
                ply.loadedAttachments = true

                local steamID64 = ply:SteamID64()
                local filePath = "player_attachments/" .. steamID64 .. ".txt"
                local json = file.Read(filePath, "DATA") or "{}"

                ply:SetPData("attachments", json)

                local data = util.JSONToTable(json)
                for att, amt in pairs(data) do
                    ply.loadingAttachment = true
                    ArcCW:PlayerGiveAtt(ply, att, amt)
                    ArcCW:PlayerSendAttInv(ply)
                end
                ply.loadingAttachment = false
            end
        end
        lastThink = CurTime() + 10
    end
end)

hook.Add("Think", "delay_load", function()
    function ArcCW:PlayerGiveAtt(ply, att, amt)
        ArcCW:detour_1(ply, att, amt)
        local steamID64 = ply:SteamID64()
        local filePath = "player_attachments/" .. steamID64 .. ".txt"
        amt = amt or 1
        if CLIENT then return end
        if not ply.detachingAttachment and not ply.attachingAttachment and
            not ply.loadingAttachment then
            local json = file.Read(filePath, "DATA") or "{}"
            local data = util.JSONToTable(json) or {}
            data[att] = data[att] or 0
            data[att] = data[att] + amt
            json = util.TableToJSON(data)
            ply:SetPData("attachments", json)

            -- Save to file
            local steamID64 = ply:SteamID64()
            currentPlayerAttachments[steamID64] =
                currentPlayerAttachments[steamID64] or {}
            currentPlayerAttachments[steamID64][att] =
                (currentPlayerAttachments[steamID64][att] or 0) + amt
            local filePath = "player_attachments/" .. steamID64 .. ".txt"
            file.Write(filePath, json)
        else
            ply.detachingAttachment = false
            ply.attachingAttachment = false
            ply.loadingAttachment = false
        end
    end

    function ArcCW:PlayerTakeAtt(ply, att, amt)
        ArcCW:detour_2(ply, att, amt)
        amt = amt or 1
        if CLIENT then return end
        if ply.droppingAttachment then

            -- Update PData
            local json = file.Read(filePath, "DATA")
            local data = util.JSONToTable(json)
            data[att] = data[att] or 0
            data[att] = data[att] - amt
            json = util.TableToJSON(data)
            ply:SetPData("attachments", json)
            local steamID64 = ply:SteamID64()
            local filePath = "player_attachments/" .. steamID64 .. ".txt"
            file.Write(filePath, json)
            ply.droppingAttachment = false
        end
    end
end)

concommand.Add("remove_player_file", function(ply, cmd, args)
    if not args[1] then return end
    local steamID64 = args[1]
    local filePath = "player_attachments/" .. steamID64 .. ".txt"
    if file.Exists(filePath, "DATA") then
        file.Delete(filePath)
        print("File deleted.")
    else
        print("File not found.")
    end
end)
