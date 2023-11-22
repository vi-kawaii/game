io.stdout:setvbuf("no")

local lg = love.graphics
lg.setDefaultFilter("nearest")

local g3d = require "g3d"
local Player = require "player"
local vectors = require "g3d/vectors"
local menori = require 'menori'

local map, background, player
local canvas
local accumulator = 0
local frametime = 1/60
local rollingAverage = {}

local scene_iterator = 1
local example_list = {
	{ title = "minimal", path = "scenes.minimal.scene" },
	{ title = "basic_lighting", path = "scenes.basic_lighting.scene" },
	{ title = "SSAO", path = "scenes.SSAO.scene" },
}
for _, v in ipairs(example_list) do
	local Scene = require(v.path)
	menori.app:add_scene(v.title, Scene())
end
menori.app:set_scene('minimal')

function love.load()
    player = Player:new(0,0,0)
end

function love.draw()
	menori.app:render()
end

local function set_scene()
	menori.app:set_scene(example_list[scene_iterator].title)
end

function love.wheelmoved(...)
	menori.app:handle_event('wheelmoved', ...)
end

function love.keyreleased(key, ...)
	if key == 'a' then
		scene_iterator = scene_iterator - 1
		if scene_iterator < 1 then scene_iterator = #example_list end
		set_scene()
	end
	if key == 'd' then
		scene_iterator = scene_iterator + 1
		if scene_iterator > #example_list then scene_iterator = 1 end
		set_scene()
	end
	menori.app:handle_event('keyreleased', key, ...)
end

function love.keypressed(...)
	menori.app:handle_event('keypressed', ...)
end

function love.mousemoved(x, y, dx, dy)
    g3d.camera.firstPersonLook(dx,dy)

	menori.app:handle_event('mousemoved', x, y, dx, dy)
end

function love.update(dt)
    menori.app:update(dt)

	if love.keyboard.isDown('escape') then
		love.event.quit()
	end
	love.mouse.setRelativeMode(love.mouse.isDown(2))

    -- rolling average so that abrupt changes in dt
    -- do not affect gameplay
    -- the math works out (div by 60, then mult by 60)
    -- so that this is equivalent to just adding dt, only smoother
    table.insert(rollingAverage, dt)
    if #rollingAverage > 60 then
        table.remove(rollingAverage, 1)
    end
    local avg = 0
    for i,v in ipairs(rollingAverage) do
        avg = avg + v
    end

    -- fixed timestep accumulator
    accumulator = accumulator + avg/#rollingAverage
    while accumulator > frametime do
        accumulator = accumulator - frametime
        player:update(dt)
    end
    
    -- interpolate player between frames
    -- to stop camera jitter when fps and timestep do not match
    player:interpolate(accumulator/frametime)
end