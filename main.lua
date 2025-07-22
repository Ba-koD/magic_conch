-- Magic Conch - Loader
require("magic_conch_config")
require("magic_conch_mcm")
require("magic_conch_core")
require("magic_conch_render")

local MagicConch_Render = require("magic_conch_render")
MagicConch_Render.tryLoadFont("resources/font/Kkubulim.fnt")

-----------------------------------------------------------
----=         Magic Conch Mod               =----
----=    Makes familiar cubes/balls smarter          =----
----=        Version managed in magic_conch_config.lua       =----
-----------------------------------------------------------

-- Version information will be displayed in console messages
-- RegisterMod is handled in magic_conch_core.lua
