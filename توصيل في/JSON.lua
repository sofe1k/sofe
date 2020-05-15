-- -*- coding: utf-8 -*-
--
-- Simple JSON encoding and decoding in pure Lua.
--
-- Copyright 2010-2014 Jeffrey Friedl
-- http://regex.info/blog/
--
-- Latest version: http://regex.info/blog/lua/json
--
-- This code is released under a Creative Commons CC-BY "Attribution" License:
-- http://creativecommons.org/licenses/by/3.0/deed.en_US
--
-- It can be used for any purpose so long as the copyright notice above,
-- the web-page links above, and the 'AUTHOR_NOTE' string below are
-- maintained. Enjoy.
--
local VERSION = 20141223.14 -- version history at end of file
local AUTHOR_NOTE = "-[ JSON.lua package by Jeffrey Friedl (http://regex.info/blog/lua/json) version 20141223.14 ]-"

--
-- The 'AUTHOR_NOTE' variable exists so that information about the source
-- of the package is maintained even in compiled versions. It's also
-- included in OBJDEF below mostly to quiet warnings about unused variables.
--
local OBJDEF = {
   VERSION      = VERSION,
   AUTHOR_NOTE  = AUTHOR_NOTE,
}


--
-- Simple JSON encoding and decoding in pure Lua.
-- http://www.json.org/
--
--
--   JSON = assert(loadfile "JSON.lua")() -- one-time load of the routines
--
--   local lua_value = JSON:decode(raw_json_text)
--
--   local raw_json_text    = JSON:encode(lua_table_or_value)
--   local pretty_json_text = JSON:encode_pretty(lua_table_or_value) -- "pretty printed" version for human readability
--
--
--
-- DECODING (from a JSON string to a Lua table)
--
--
--   JSON = assert(loadfile "JSON.lua")() -- one-time load of the routines
--
--   local lua_value = JSON:decode(raw_json_text)
--
--   If the JSON text is for an object or an array, e.g.
--     { "what": "books", "count": 3 }
--   or
--     [ "Larry", "Curly", "Moe" ]
--
--   the result is a Lua table, e.g.
--     { what = "books", count = 3 }
--   or
--     { "Larry", "Curly", "Moe" }
--
--
--   The encode and decode routines accept an optional second argument,
--   "etc", which is not used during encoding or decoding, but upon error
--   is passed along to error handlers. It can be of any type (including nil).
--
--
--
-- ERROR HANDLING
--
--   With most errors during decoding, this code calls
--
--      JSON:onDecodeError(message, text, location, etc)
--
--   with a message about the error, and if known, the JSON text being
--   parsed and the byte count where the problem was discovered. You can
--   replace the default JSON:onDecodeError() with your own function.
--
--   The default onDecodeError() merely augments the message with data
--   about the text and the location if known (and if a second 'etc'
--   argument had been provided to decode(), its value is tacked onto the
--   message as well), and then calls JSON.assert(), which itself defaults
--   to Lua's built-in assert(), and can also be overridden.
--
--   For example, in an Adobe Lightroom plugin, you might use something like
--
--          function JSON:onDecodeError(message, text, location, etc)
--             LrErrors.throwUserError("Internal Error: invalid JSON data")
--          end
--
--   or even just
--
--          function JSON.assert(message)
--             LrErrors.throwUserError("Internal Error: " .. message)
--          end
--
--   If JSON:decode() is passed a nil, this is called instead:
--
--      JSON:onDecodeOfNilError(message, nil, nil, etc)
--
--   and if JSON:decode() is passed HTML instead of JSON, this is called:
--
--      JSON:onDecodeOfHTMLError(message, text, nil, etc)
--
--   The use of the fourth 'etc' argument allows stronger coordination
--   between decoding and error reporting, especially when you provide your
--   own error-handling routines. Continuing with the the Adobe Lightroom
--   plugin example:
--
--          function JSON:onDecodeError(message, text, location, etc)
--             local note = "Internal Error: invalid JSON data"
--             if type(etc) = 'table' and etc.photo then
--                note = note .. " while processing for " .. etc.photo:getFormattedMetadata('fileName')
--             end
--             LrErrors.throwUserError(note)
--          end
--
--            :
--            :
--
--          for i, photo in ipairs(photosToProcess) do
--               :             
--               :             
--               local data = JSON:decode(someJsonText, { photo = photo })
--               :             
--               :             
--          end
--
--
--
--
--
-- DECODING AND STRICT TYPES
--
--   Because both JSON objects and JSON arrays are converted to Lua tables,
--   it's not normally possible to tell which original JSON type a
--   particular Lua table was derived from, or guarantee decode-encode
--   round-trip equivalency.
--
--   However, if you enable strictTypes, e.g.
--
--      JSON = assert(loadfile "JSON.lua")() --load the routines
--      JSON.strictTypes = true
--
--   then the Lua table resulting from the decoding of a JSON object or
--   JSON array is marked via Lua metatable, so that when re-encoded with
--   JSON:encode() it ends up as the appropriate JSON type.
--
--   (This is not the default because other routines may not work well with
--   tables that have a metatable set, for example, Lightroom API calls.)
--
--
-- ENCODING (from a lua table to a JSON string)
--
--   JSON = assert(loadfile "JSON.lua")() -- one-time load of the routines
--
--   local raw_json_text    = JSON:encode(lua_table_or_value)
--   local pretty_json_text = JSON:encode_pretty(lua_table_or_value) -- "pretty printed" version for human readability
--   local custom_pretty    = JSON:encode(lua_table_or_value, etc, { pretty = true, indent = "|  ", align_keys = false })
--
--   On error during encoding, this code calls:
--
--     JSON:onEncodeError(message, etc)
--
--   which you can override in your local JSON object.
--
--   The 'etc' in the error call is the second argument to encode()
--   and encode_pretty(), or nil if it wasn't provided.
--
--
-- PRETTY-PRINTING
--
--   An optional third argument, a table of options, allows a bit of
--   configuration about how the encoding takes place:
--
--     pretty = JSON:encode(val, etc, {
--                                       pretty = true,      -- if false, no other options matter
--                                       indent = "   ",     -- this provides for a three-space indent per nesting level
--                                       align_keys = false, -- see below
--                                     })
--
--   encode() and encode_pretty() are identical except that encode_pretty()
--   provides a default options table if none given in the call:
--
--       { pretty = true, align_keys = false, indent = "  " }
--
--   For example, if
--
--      JSON:encode(data)
--
--   produces:
--
--      {"city":"Kyoto","climate":{"avg_temp":16,"humidity":"high","snowfall":"minimal"},"country":"Japan","wards":11}
--
--   then
--
--      JSON:encode_pretty(data)
--
--   produces:
--
--      {
--        "city": "Kyoto",
--        "climate": {
--          "avg_temp": 16,
--          "humidity": "high",
--          "snowfall": "minimal"
--        },
--        "country": "Japan",
--        "wards": 11
--      }
--
--   The following three lines return identical results:
--       JSON:encode_pretty(data)
--       JSON:encode_pretty(data, nil, { pretty = true, align_keys = false, indent = "  " })
--       JSON:encode       (data, nil, { pretty = true, align_keys = false, indent = "  " })
--
--   An example of setting your own indent string:
--
--     JSON:encode_pretty(data, nil, { pretty = true, indent = "|    " })
--
--   produces:
--
--      {
--      |    "city": "Kyoto",
--      |    "climate": {
--      |    |    "avg_temp": 16,
--      |    |    "humidity": "high",
--      |    |    "snowfall": "minimal"
--      |    },
--      |    "country": "Japan",
--      |    "wards": 11
--      }
--
--   An example of setting align_keys to true:
--
--     JSON:encode_pretty(data, nil, { pretty = true, indent = "  ", align_keys = true })
--  
--   produces:
--   
--      {
--           "city": "Kyoto",
--        "climate": {
--                     "avg_temp": 16,
--                     "humidity": "high",
--                     "snowfall": "minimal"
--                   },
--        "country": "Japan",
--          "wards": 11
--      }
--
--   which I must admit is kinda ugly, sorry. This was the default for
--   encode_pretty() prior to version 20141223.14.
--
--
--  AMBIGUOUS SITUATIONS DURING THE ENCODING
--
--   During the encode, if a Lua table being encoded contains both string
--   and numeric keys, it fits neither JSON's idea of an object, nor its
--   idea of an array. To get around this, when any string key exists (or
--   when non-positive numeric keys exist), numeric keys are converted to
--   strings.
--
--   For example, 
--     JSON:encode({ "one", "two", "three", SOMESTRING = "some string" }))
--   produces the JSON object
--     {"1":"one","2":"two","3":"three","SOMESTRING":"some string"}
--
--   To prohibit this conversion and instead make it an error condition, set
--      JSON.noKeyConversion = true
--




--
-- SUMMARY OF METHODS YOU CAN OVERRIDE IN YOUR LOCAL LUA JSON OBJECT
--
--    assert
--    onDecodeError
--    onDecodeOfNilError
--    onDecodeOfHTMLError
--    onEncodeError
--
--  If you want to create a separate Lua JSON object with its own error handlers,
--  you can reload JSON.lua or use the :new() method.
--
---------------------------------------------------------------------------

local default_pretty_indent  = "  "
local default_pretty_options = { pretty = true, align_keys = false, indent = default_pretty_indent }

local isArray  = { __tostring = function() return "JSON array"  end }    isArray.__index  = isArray
local isObject = { __tostring = function() return "JSON object" end }    isObject.__index = isObject


function OBJDEF:newArray(tbl)
   return setmetatable(tbl or {}, isArray)
end

function OBJDEF:newObject(tbl)
   return setmetatable(tbl or {}, isObject)
end

local function unicode_codepoint_as_utf8(codepoint)
   --
   -- codepoint is a number
   --
   if codepoint <= 127 then
      return string.char(codepoint)

   elseif codepoint <= 2047 then
      --
      -- 110yyyxx 10xxxxxx         <-- useful notation from http://en.wikipedia.org/wiki/Utf8
      --
      local highpart = math.floor(codepoint / 0x40)
      local lowpart  = codepoint - (0x40 * highpart)
      return string.char(0xC0 + highpart,
                         0x80 + lowpart)

   elseif codepoint <= 65535 then
      --
      -- 1110yyyy 10yyyyxx 10xxxxxx
      --
      local highpart  = math.floor(codepoint / 0x1000)
      local remainder = codepoint - 0x1000 * highpart
      local midpart   = math.floor(remainder / 0x40)
      local lowpart   = remainder - 0x40 * midpart

      highpart = 0xE0 + highpart
      midpart  = 0x80 + midpart
      lowpart  = 0x80 + lowpart

      --
      -- Check for an invalid character (thanks Andy R. at Adobe).
      -- See table 3.7, page 93, in http://www.unicode.org/versions/Unicode5.2.0/ch03.pdf#G28070
      --
      if ( highpart == 0xE0 and midpart < 0xA0 ) or
         ( highpart == 0xED and midpart > 0x9F ) or
         ( highpart == 0xF0 and midpart < 0x90 ) or
         ( highpart == 0xF4 and midpart > 0x8F )
      then
         return "?"
      else
         return string.char(highpart,
                            midpart,
                            lowpart)
      end

   else
      --
      -- 11110zzz 10zzyyyy 10yyyyxx 10xxxxxx
      --
      local highpart  = math.floor(codepoint / 0x40000)
      local remainder = codepoint - 0x40000 * highpart
      local midA      = math.floor(remainder / 0x1000)
      remainder       = remainder - 0x1000 * midA
      local midB      = math.floor(remainder / 0x40)
      local lowpart   = remainder - 0x40 * midB

      return string.char(0xF0 + highpart,
                         0x80 + midA,
                         0x80 + midB,
                         0x80 + lowpart)
   end
end

function OBJDEF:onDecodeError(message, text, location, etc)
   if text then
      if location then
         message = string.format("%s at char %d of: %s", message, location, text)
      else
         message = string.format("%s: %s", message, text)
      end
   end

   if etc ~= nil then
      message = message .. " (" .. OBJDEF:encode(etc) .. ")"
   end

   if self.assert then
      self.assert(false, message)
   else
      assert(false, message)
   end
end

OBJDEF.onDecodeOfNilError  = OBJDEF.onDecodeError
OBJDEF.onDecodeOfHTMLError = OBJDEF.onDecodeError

function OBJDEF:onEncodeError(message, etc)
   if etc ~= nil then
      message = message .. " (" .. OBJDEF:encode(etc) .. ")"
   end

   if self.assert then
      self.assert(false, message)
   else
      assert(false, message)
   end
end

local function grok_number(self, text, start, etc)
   --
   -- Grab the integer part
   --
   local integer_part = text:match('^-?[1-9]%d*', start)
                     or text:match("^-?0",        start)

   if not integer_part then
      self:onDecodeError("expected number", text, start, etc)
   end

   local i = start + integer_part:len()

   --
   -- Grab an optional decimal part
   --
   local decimal_part = text:match('^%.%d+', i) or ""

   i = i + decimal_part:len()

   --
   -- Grab an optional exponential part
   --
   local exponent_part = text:match('^[eE][-+]?%d+', i) or ""

   i = i + exponent_part:len()

   local full_number_text = integer_part .. decimal_part .. exponent_part
   local as_number = tonumber(full_number_text)

   if not as_number then
      self:onDecodeError("bad number", text, start, etc)
   end

   return as_number, i
end


local function grok_string(self, text, start, etc)

   if text:sub(start,start) ~= '"' then
      self:onDecodeError("expected string's opening quote", text, start, etc)
   end

   local i = start + 1 -- +1 to bypass the initial quote
   local text_len = text:len()
   local VALUE = ""
   while i <= text_len do
      local c = text:sub(i,i)
      if c == '"' then
         return VALUE, i + 1
      end
      if c ~= '\\' then
         VALUE = VALUE .. c
         i = i + 1
      elseif text:match('^\\b', i) then
         VALUE = VALUE .. "\b"
         i = i + 2
      elseif text:match('^\\f', i) then
         VALUE = VALUE .. "\f"
         i = i + 2
      elseif text:match('^\\n', i) then
         VALUE = VALUE .. "\n"
         i = i + 2
      elseif text:match('^\\r', i) then
         VALUE = VALUE .. "\r"
         i = i + 2
      elseif text:match('^\\t', i) then
         VALUE = VALUE .. "\t"
         i = i + 2
      else
         local hex = text:match('^\\u([0123456789aAbBcCdDeEfF][0123456789aAbBcCdDeEfF][0123456789aAbBcCdDeEfF][0123456789aAbBcCdDeEfF])', i)
         if hex then
            i = i + 6 -- bypass what we just read

            -- We have a Unicode codepoint. It could be standalone, or if in the proper range and
            -- followed by another in a specific range, it'll be a two-code surrogate pair.
            local codepoint = tonumber(hex, 16)
            if codepoint >= 0xD800 and codepoint <= 0xDBFF then
               -- it's a hi surrogate... see whether we have a following low
               local lo_surrogate = text:match('^\\u([dD][cdefCDEF][0123456789aAbBcCdDeEfF][0123456789aAbBcCdDeEfF])', i)
               if lo_surrogate then
                  i = i + 6 -- bypass the low surrogate we just read
                  codepoint = 0x2400 + (codepoint - 0xD800) * 0x400 + tonumber(lo_surrogate, 16)
               else
                  -- not a proper low, so we'll just leave the first codepoint as is and spit it out.
               end
            end
            VALUE = VALUE .. unicode_codepoint_as_utf8(codepoint)

         else

            -- just pass through what's escaped
            VALUE = VALUE .. text:match('^\\(.)', i)
            i = i + 2
        