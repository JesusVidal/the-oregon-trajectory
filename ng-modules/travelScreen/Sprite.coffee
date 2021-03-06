
module.exports = class Sprite
    constructor: (spritesheet, nameOrJSON, x=0, y=0)->
        # sets up new sprite using given spritesheet src centered at x & y position on canvas
        # :y: y-value of sprite or 'random' which will set a randomized height in the game window
        # :nameOrJSON: name used to set dimensions or else JSON object containing dimensions in following form:
        #       {
        #           h:64    # height of sprite
        #           w:63    # width of sprite
        #           max_frame: 1    # highest frame number (counting starts @ 0), defaults to 0
        #           scale: 0.5      # scale of sprite display defaults to 1. use "random" to set random btwn 10-100%
        #           r: 3.1415       # rotation of sprite in radians (defaults to 0) (use "random" to set random rotation)
        #       }
        @sheet = new Image()
        @sheet.src = spritesheet
        @r = 0  # rotation
        @setDimensions(nameOrJSON)
        if y == 'random'
            @y = Math.random()*200.0+200.0
        else
            @y = y
        @x = x
        @frame_n = 0
        # for slowing animation speed
        @draws_per_frame = 50  # number of draw calls before setting new frame
        @draw_counter = 0

    setDimensions: (nameOrJSON)->
        # sets dimensions, max_frames, draws_per_frame based on name to match given sprite
        # TODO: these should be read from a json file given with each sprite
        switch nameOrJSON
            when "station1"
                @h = 399
                @w = 182
                @max_frames = 4
                @scale = 1
            when "ship"
                @h = 150
                @w = 338
                @max_frames = 0
                @scale = 0.6
            when "satelite-debris-1"
                @h = 150
                @w = 512
                @max_frames = 0
                @scale = 0.3 + Math.random()*0.2
                @r = Math.random()*Math.PI*2
            when "maneuver-node"
                @h = 100
                @w = 140
                @max_frames = 5
                @scale = 1
            else
                # else JSON is given
                @h = nameOrJSON.h
                @w = nameOrJSON.w
                @max_frames = nameOrJSON.max_frame or 0

                if nameOrJSON.scale == "random"
                    @scale = Math.random()*0.9+0.1
                else
                    @scale = nameOrJSON.scale or 1

                if nameOrJSON.r == "random"
                    @r = Math.PI*2.0*Math.random()
                else
                    @r = nameOrJSON.r or 0
                    
                return

    next_frame: ()->
        @frame_n += 1
        if @frame_n > @max_frames
            @frame_n = 0

    draw: (ctx, x=@x, y=@y) ->
        # draws a sprite centered at given location, or uses internal
        # set locations to start in sprite sheet
        ssx = @frame_n * @w
        ssy = 0  # TODO: use y-axis in spritesheets for different ship conditionals/permuations (damage, age, etc)
        if @r != 0
            ctx.save()
            ctx.translate(x,y)
            ctx.rotate(@r)
            ctx.drawImage(@sheet, ssx, ssy, @w, @h, -@w/2, -@h/2, @w*@scale, @h*@scale)
            ctx.restore()
        else
            ctx.drawImage(@sheet, ssx, ssy, @w, @h, x-@w/2, y-@h/2, @w*@scale, @h*@scale)

        @draw_counter += 1
        if @draw_counter > @draws_per_frame
            @next_frame()
            @draw_counter = 0
