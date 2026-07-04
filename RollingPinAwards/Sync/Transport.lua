local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Sync = RPA.Sync or {}
RPA.Sync = Sync

local function sendNativeAddonMessage(prefix, message, distribution, target)
  if _G.C_ChatInfo and type(_G.C_ChatInfo.SendAddonMessage) == "function" then
    return _G.C_ChatInfo.SendAddonMessage(prefix, message, distribution, target)
  end

  if type(_G.SendAddonMessage) == "function" then
    return _G.SendAddonMessage(prefix, message, distribution, target)
  end

  return false
end

local function nativeSendSucceeded(result)
  if result == nil or result == true then
    return true
  end

  local enum = _G.Enum and _G.Enum.SendAddonMessageResult
  return enum and result == enum.Success
end

local function nativeSendError(result)
  if result == false then
    return "native send failed"
  end

  local enum = _G.Enum and _G.Enum.SendAddonMessageResult
  if type(enum) == "table" then
    for name, value in pairs(enum) do
      if value == result then
        return tostring(name):gsub("(%l)(%u)", "%1 %2"):lower()
      end
    end
  end

  return "native send failed"
end

function Sync:Broadcast(payloadType, payload, distribution, target, priority)
  local hasAceComm = type(self.addon.SendCommMessage) == "function" and type(self.addon.Serialize) == "function"
  local hasNativeComm = (_G.C_ChatInfo and type(_G.C_ChatInfo.SendAddonMessage) == "function")
    or type(_G.SendAddonMessage) == "function"
  local channel = distribution or "GUILD"
  local useAceComm = hasAceComm and not (channel == "WHISPER" and hasNativeComm)

  if not hasAceComm and not hasNativeComm then
    self.lastBroadcast = {
      payloadType = payloadType,
      distribution = channel,
      ok = false,
      error = "comm unavailable",
    }

    return false, "comm unavailable"
  end

  local envelope, err = self:BuildEnvelope(payloadType, payload)
  if not envelope then
    self.lastBroadcast = {
      payloadType = payloadType,
      distribution = distribution or "GUILD",
      ok = false,
      error = err,
    }

    return false, err
  end

  local nativeChunkCount

  if useAceComm then
    local serialized = self.addon:Serialize(envelope)
    local ok, sendErr = pcall(self.addon.SendCommMessage, self.addon,
      self.addon.Constants.COMM_PREFIX,
      serialized,
      channel,
      target,
      priority or "NORMAL"
    )
    if not ok then
      self.lastBroadcast = {
        payloadType = payloadType,
        distribution = channel,
        target = target,
        priority = priority or "NORMAL",
        ok = false,
        transport = "ace",
        error = sendErr,
      }

      return false, sendErr
    end
  else
    local serialized, serializeErr = self:SerializeEnvelope(envelope)
    if not serialized then
      self.lastBroadcast = {
        payloadType = payloadType,
        distribution = distribution or "GUILD",
        ok = false,
        error = serializeErr,
      }

      return false, serializeErr
    end

    local chunks, chunkErr = self:EncodeNativeMessages(serialized)
    if not chunks then
      self.lastBroadcast = {
        payloadType = payloadType,
        distribution = distribution or "GUILD",
        ok = false,
        transport = "native",
        error = chunkErr,
      }

      return false, chunkErr
    end

    nativeChunkCount = #chunks

    for _, chunk in ipairs(chunks) do
      local ok, result = pcall(
        sendNativeAddonMessage,
        self.addon.Constants.COMM_PREFIX,
        chunk,
        channel,
        target
      )
      if not ok or not nativeSendSucceeded(result) then
        self.lastBroadcast = {
          payloadType = payloadType,
          distribution = channel,
          target = target,
          priority = priority or "NORMAL",
          ok = false,
          transport = "native",
          chunkCount = nativeChunkCount,
          error = ok and nativeSendError(result) or result,
        }

        return false, self.lastBroadcast.error
      end
    end
  end

  self.lastBroadcast = {
    payloadType = payloadType,
    distribution = channel,
    target = target,
    priority = priority or "NORMAL",
    ok = true,
    transport = useAceComm and "ace" or "native",
    chunkCount = nativeChunkCount,
  }

  return true
end

function Sync:SendHello(distribution, target, force)
  local guild = self.addon:GetActiveGuildContext()
  if not guild then
    self.lastHello = {
      ok = false,
      error = "missing guild",
    }

    return false, "missing guild"
  end

  if not force and self.lastHello and self.lastHello.guildKey == guild.guildKey then
    return false, "hello already sent"
  end

  local ok, err = self:Broadcast("sync_hello", {
    guildKey = guild.guildKey,
    sender = self.addon:GetCurrentPlayerFullName(),
    sentAt = self.addon.Time and type(self.addon.Time.Now) == "function" and self.addon.Time:Now() or 0,
  }, distribution or "GUILD", target, "NORMAL")

  self.lastHello = {
    guildKey = guild.guildKey,
    ok = ok == true,
    error = err,
  }

  return ok, err
end

return RPA.Sync

