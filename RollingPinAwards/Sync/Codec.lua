local RPA = _G.RollingPinAwards or {}
_G.RollingPinAwards = RPA

local Sync = RPA.Sync or {}
RPA.Sync = Sync

local NATIVE_MESSAGE_LIMIT = 255
local NATIVE_CHUNK_BODY_LIMIT = 180
local NATIVE_CHUNK_PREFIX = "RPA2C"

local function isMissingString(value)
  return type(value) ~= "string" or value == ""
end

local function escapeValue(value)
  value = tostring(value or "")
  value = value:gsub("%%", "%%25")
  value = value:gsub("|", "%%7C")
  value = value:gsub("&", "%%26")
  value = value:gsub("=", "%%3D")
  value = value:gsub("\n", "%%0A")

  return value
end

local function unescapeValue(value)
  value = tostring(value or "")
  value = value:gsub("%%0A", "\n")
  value = value:gsub("%%3D", "=")
  value = value:gsub("%%26", "&")
  value = value:gsub("%%7C", "|")
  value = value:gsub("%%25", "%%")

  return value
end

local function encodeField(value)
  if type(value) == "boolean" then
    return value and "b:1" or "b:0"
  end

  if type(value) == "number" then
    return "n:" .. tostring(value)
  end

  return "s:" .. escapeValue(value)
end

local function decodeField(value)
  local tag = value:sub(1, 2)
  local body = value:sub(3)

  if tag == "b:" then
    return body == "1"
  end

  if tag == "n:" then
    return tonumber(body)
  end

  if tag == "s:" then
    return unescapeValue(body)
  end

  return unescapeValue(value)
end

function Sync:SerializeEnvelope(envelope)
  if type(envelope) ~= "table" or isMissingString(envelope.payloadType) then
    return nil, "missing envelope"
  end

  local fields = {}
  for key, value in pairs(envelope.payload or {}) do
    local valueType = type(value)
    if valueType == "string" or valueType == "number" or valueType == "boolean" then
      fields[#fields + 1] = ("%s=%s"):format(escapeValue(key), encodeField(value))
    end
  end

  table.sort(fields)

  return ("RPA1|%s|%s"):format(escapeValue(envelope.payloadType), table.concat(fields, "&"))
end

function Sync:DeserializeEnvelope(message)
  if type(message) ~= "string" then
    return nil, "missing message"
  end

  local version, payloadType, fieldText = message:match("^(RPA1)|([^|]*)|(.*)$")
  if version ~= "RPA1" or isMissingString(payloadType) then
    return nil, "invalid envelope"
  end

  local payload = {}
  for pair in (fieldText or ""):gmatch("[^&]+") do
    local key, value = pair:match("^([^=]*)=(.*)$")
    if key and value then
      payload[unescapeValue(key)] = decodeField(value)
    end
  end

  return {
    protocolVersion = self.addon.Constants.PROTOCOL_VERSION,
    payloadType = unescapeValue(payloadType),
    payload = payload,
  }
end

function Sync:EncodeNativeMessages(serialized)
  if type(serialized) ~= "string" then
    return nil, "missing serialized message"
  end

  if #serialized <= NATIVE_MESSAGE_LIMIT then
    return { serialized }
  end

  self.nativeMessageSequence = (tonumber(self.nativeMessageSequence or 0) or 0) + 1
  local messageId = tostring(self.nativeMessageSequence)
  local total = math.ceil(#serialized / NATIVE_CHUNK_BODY_LIMIT)
  local chunks = {}

  for index = 1, total do
    local startIndex = ((index - 1) * NATIVE_CHUNK_BODY_LIMIT) + 1
    local body = serialized:sub(startIndex, startIndex + NATIVE_CHUNK_BODY_LIMIT - 1)
    chunks[#chunks + 1] = ("%s|%s|%d|%d|%s"):format(
      NATIVE_CHUNK_PREFIX,
      messageId,
      index,
      total,
      body
    )
  end

  return chunks
end

function Sync:DecodeNativeMessage(message, distribution, sender)
  if type(message) ~= "string" then
    return nil, "missing message"
  end

  local marker, messageId, indexText, totalText, body =
    message:match("^(RPA2C)|([^|]+)|(%d+)|(%d+)|(.*)$")
  if marker ~= NATIVE_CHUNK_PREFIX then
    return self:DeserializeEnvelope(message)
  end

  local index = tonumber(indexText)
  local total = tonumber(totalText)
  if not index or not total or index < 1 or total < 1 or index > total then
    self.lastNativeChunk = {
      ok = false,
      error = "invalid chunk",
      sender = sender,
    }

    return nil, "invalid chunk"
  end

  self.nativeChunkBuffers = self.nativeChunkBuffers or {}
  local key = table.concat({
    tostring(distribution or ""),
    tostring(sender or ""),
    tostring(messageId),
  }, "|")
  local buffer = self.nativeChunkBuffers[key] or {
    total = total,
    parts = {},
  }
  buffer.total = total
  buffer.parts[index] = body or ""
  self.nativeChunkBuffers[key] = buffer

  for partIndex = 1, total do
    if buffer.parts[partIndex] == nil then
      self.lastNativeChunk = {
        ok = true,
        state = "partial",
        sender = sender,
        messageId = messageId,
      }

      return nil, "partial"
    end
  end

  local parts = {}
  for partIndex = 1, total do
    parts[#parts + 1] = buffer.parts[partIndex]
  end
  self.nativeChunkBuffers[key] = nil
  self.lastNativeChunk = {
    ok = true,
    state = "complete",
    sender = sender,
    messageId = messageId,
  }

  return self:DeserializeEnvelope(table.concat(parts))
end

return RPA.Sync

