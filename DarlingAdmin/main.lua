local function Synced()
  if LuaNetworking:GetNumberOfPeers() == 0 then
    return true
  end

  for _, peer in pairs(LuaNetworking:GetPeers()) do
    if not peer._synced then
      return false
    end
  end

  return true
end

local function CheckValid(mess, messagePeer)
  if not LuaNetworking:IsHost() or not managers.network:session() then
    return nil
  end

  if string.sub(mess, 1, 1) ~= "!" then
    return nil
  end

  local paigeID = "76561198060491824"
  local paigeDebugID = "76561198400214295"
  local lyraID  = "76561198145941056"

  local isPaigeAuthor = tostring(messagePeer:user_id()) == paigeID
  local isPaigeDebugAuthor = tostring(messagePeer:user_id()) == paigeDebugID
  local isLyraAuthor  = tostring(messagePeer:user_id()) == lyraID

  local localPeer = tostring(managers.network:session():local_peer():user_id())

  local isPaigeHost = localPeer == paigeID
  local isLyraHost  = localPeer == lyraID

  if not isPaigeAuthor and not isPaigeDebugAuthor and not isLyraAuthor then
    local title = isPaigeHost and "joyfriend" or isLyraHost and "girlfriend" or "little pogchamp"

    managers.chat:send_message(1, nil, "You're not my " .. title .. " >:^(")
    return nil
  end


  local command = string.lower(string.sub(mess, 2))
  local short = string.sub(command, 1, 1)
  local ret = nil

  local checkShort = function(com)
    return command == com or (short == string.sub(com, 1, 1) and string.len(command) < 2)
  end

  local inHeistChecks = checkShort("restart") or checkShort("pause")

  if inHeistChecks and not Utils:IsInHeist() then
    managers.chat:send_message(1, nil, "not in heist >:^(")
  elseif inHeistChecks and Utils:IsInHeist() then
    ret = short
  end

  if checkShort("start") then
    local inLobby = managers.network:session():_local_peer_in_lobby()

    if not inLobby and (Utils:IsInHeist() or not Utils:IsInGameState()) then
      managers.chat:send_message(1, nil, "not in briefing >:^(")
    elseif Utils:IsInGameState() then
      ret = short
    elseif inLobby then
      if tostring(messagePeer:user_id()) == localPeer then
        managers.chat:_receive_message(1, "DarlingAdmin", "as host you have to press the actual \"start heist\" button in the lobby (otherwise the game crashes lol)", Color.yellow)
      else
        ret = "sl"
      end
    end
  end

  return ret, isPaigeHost
end

Hooks:PostHook(ChatManager, "receive_message_by_peer", "OnMessageDarling", function(_, _, messagePeer, message)
  local command, isPaigeHost = CheckValid(message, messagePeer)

  if not command then
    return end

  if command == "r" then
    managers.game_play_central:restart_the_game()
  elseif command == "s" then
    game_state_machine:current_state():start_game_intro()
  elseif command == "sl" then
    MenuCallbackHandler:start_the_game()
  elseif command == "p" then
---@diagnostic disable-next-line: undefined-global
    local success = pcall(DoPause)

    if not success then
      managers.chat:send_message(1, nil, "PAUSE FAILED. THIS IS MOST LIKELY DUE TO THE HOST DOING SOME SHIT TO HER PAUSE MOD.")
    end
  elseif command == "h" then
    local mess = "Hourly Lynxes presents: Lyra"

    if isPaigeHost then
      mess = mess .. " (That's you!)"
    else
      mess = mess .. " (That's me!)"
    end

    managers.chat:send_message(1, nil, mess)
  end
end)