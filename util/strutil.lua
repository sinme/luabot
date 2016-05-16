#! /usr/bin/env lua
--
-- strutil.lua
-- Copyright (C) 2015 Adrian Perez <aperez@igalia.com>
--
-- Distributed under terms of the MIT license.
--

local s_gmatch    = string.gmatch
local s_match     = string.match
local s_gsub      = string.gsub
local s_sub       = string.sub
local _tostring   = tostring
local _require    = require
local _type       = type

-- Lazy-load "util.html" to avoid mutually-recursive calls to require()
local html_escape = function (s)
   html_escape = _require("util.html").escape
   return html_escape(s)
end

--
-- Based on Rici Lake's simple string interpolation
-- See: http://lua-users.org/wiki/StringInterpolation
--
local dotted_path_pattern = "[^%.]+"
local function interpolate(text, value)
   return (s_gsub(text, "([$%%]%b{})", function (dotted_path)
      local completed = true
      for component in s_gmatch(s_sub(dotted_path, 3, -2), dotted_path_pattern) do
         if _type(value) ~= "table" then
            completed = false
            break
         end
         if _type(value[component]) == "function" then
            -- Pass the current value as "self"
            value = value[component](value)
         else
            value = value[component]
         end
      end
      if completed then
         value = _tostring(value)
         if s_sub(dotted_path, 1, 1) == "$" then
            return html_escape(value)
         else
            return value
         end
      else
         return dotted_path
      end
   end))
end


local strstrip_pattern = "^%s*(.-)%s*$"
local pattern_magic_chars = "([%^%$%(%)%%%.%[%]%*%+%-%?])"

return {
	strip = function (s)
		return s_match(s, strstrip_pattern)
	end;
	escape_pattern = function (s)
	   return (s_gsub(s, pattern_magic_chars, "%%%1"))
   end;
	interpolate = interpolate;
	template = function (text)
		return function (vars)
			return interpolate(text, vars)
		end
	end;
}
