local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Sync = RPA.Sync or {}
RPA.Sync = Sync

local function sortedKeys(records)
  local keys = {}

  for key in pairs(records or {}) do
    keys[#keys + 1] = key
  end

  table.sort(keys, function(left, right)
    if type(left) == type(right) then
      return left < right
    end

    return tostring(left) < tostring(right)
  end)

  return keys
end

function Sync:RecordInbound(result)
  self.lastInbound = result or {}
end

function Sync:GetDebugLines()
  local guild = self.addon:GetActiveGuildContext()
  local lines = {
    "Rolling Pin Awards sync diagnostics",
    ("Guild: %s"):format(guild and guild.guildKey or "none"),
    ("Comm prefix: %s registered=%s"):format(
      self.addon.Constants and self.addon.Constants.COMM_PREFIX or "unknown",
      tostring(self.addon.__aceCommPrefix or "fallback")
    ),
    ("Ace3: %s SendComm=%s Serialize=%s"):format(
      tostring(self.addon.__rpaUsesAce3 == true),
      tostring(type(self.addon.SendCommMessage) == "function"),
      tostring(type(self.addon.Serialize) == "function")
    ),
    ("Ace libs: Comm=%s Serializer=%s Console=%s Event=%s"):format(
      tostring((self.addon.__rpaAceLibraries or {})["AceComm-3.0"] == true),
      tostring((self.addon.__rpaAceLibraries or {})["AceSerializer-3.0"] == true),
      tostring((self.addon.__rpaAceLibraries or {})["AceConsole-3.0"] == true),
      tostring((self.addon.__rpaAceLibraries or {})["AceEvent-3.0"] == true)
    ),
    ("LibStub: %s ChatThrottleLib: %s"):format(
      tostring(self.addon.__rpaLibStubPresent == true),
      tostring(self.addon.__rpaChatThrottleLibPresent == true)
    ),
    ("Native comm: registered=%s SendAddon=%s"):format(
      tostring(self.addon.__rpaNativeCommPrefix or "none"),
      tostring((_G.C_ChatInfo and type(_G.C_ChatInfo.SendAddonMessage) == "function")
        or type(_G.SendAddonMessage) == "function")
    ),
  }

  if self.lastBroadcast then
    lines[#lines + 1] = ("Last outbound: type=%s distribution=%s transport=%s ok=%s error=%s"):format(
      tostring(self.lastBroadcast.payloadType),
      tostring(self.lastBroadcast.distribution),
      tostring(self.lastBroadcast.transport or "unknown"),
      tostring(self.lastBroadcast.ok),
      tostring(self.lastBroadcast.error or "none")
    )
    if self.lastBroadcast.chunkCount then
      lines[#lines] = lines[#lines] .. (" chunks=%s"):format(tostring(self.lastBroadcast.chunkCount))
    end
  else
    lines[#lines + 1] = "Last outbound: none"
  end

  if self.lastInbound then
    lines[#lines + 1] = ("Last inbound: type=%s sender=%s distribution=%s ok=%s error=%s"):format(
      tostring(self.lastInbound.payloadType),
      tostring(self.lastInbound.sender),
      tostring(self.lastInbound.distribution),
      tostring(self.lastInbound.ok),
      tostring(self.lastInbound.error or "none")
    )
  else
    lines[#lines + 1] = "Last inbound: none"
  end

  if self.lastNativeChunk then
    lines[#lines + 1] = ("Native chunk: state=%s sender=%s messageId=%s error=%s"):format(
      tostring(self.lastNativeChunk.state or "none"),
      tostring(self.lastNativeChunk.sender or "none"),
      tostring(self.lastNativeChunk.messageId or "none"),
      tostring(self.lastNativeChunk.error or "none")
    )
  else
    lines[#lines + 1] = "Native chunk: none"
  end

  if self.receiveSummary then
    for _, payloadType in ipairs(sortedKeys(self.receiveSummary)) do
      local row = self.receiveSummary[payloadType] or {}
      lines[#lines + 1] = ("Receive summary: %s accepted=%s rejected=%s lastError=%s"):format(
        tostring(payloadType),
        tostring(row.accepted or 0),
        tostring(row.rejected or 0),
        tostring(row.lastError or "none")
      )
    end
  else
    lines[#lines + 1] = "Receive summary: none"
  end

  if self.lastHello then
    lines[#lines + 1] = ("Last hello: guild=%s ok=%s error=%s"):format(
      tostring(self.lastHello.guildKey or "none"),
      tostring(self.lastHello.ok),
      tostring(self.lastHello.error or "none")
    )
  else
    lines[#lines + 1] = "Last hello: none"
  end

  if self.lastSnapshot then
    local counts = self.lastSnapshot.counts or {}
    lines[#lines + 1] = ("Last snapshot: guild=%s awards=%s nominations=%s votes=%s aliases=%s ranks=%s ok=%s"):format(
      tostring(self.lastSnapshot.guildKey or "none"),
      tostring(counts.awards or 0),
      tostring(counts.nominations or 0),
      tostring(counts.votes or 0),
      tostring(counts.aliasMappings or 0),
      tostring(counts.rankPermissions or 0),
      tostring(self.lastSnapshot.ok)
    )
  else
    lines[#lines + 1] = "Last snapshot: none"
  end

  return lines
end

return RPA.Sync

