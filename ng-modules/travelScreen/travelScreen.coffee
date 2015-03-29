require('angular');

window.TRAVEL_SPEED = 1 # pixels per movement tick of tile travel
window.TRAVELS_PER_MOVE = 5  # TRAVEL_SPEED divisor (for getting < 1 TRAVEL_SPEED)


# TODO: move this to separate file and require it here
class Tile
    constructor: (startX, imageElement)->
        @x = startX
        @img = imageElement
        @tileW = 1920  # TODO: load this dynamically
        @travelCount = 0

    draw: (ctx)->
        # draws the tile
        ctx.drawImage(@img, @x, 0)
        return

    travel: ()->
        # moves the tile 1 travel unit
        if @travelCount > TRAVELS_PER_MOVE
            @x -= window.TRAVEL_SPEED
            @travelCount = 0
        else
            @travelCount += 1

    getOverhang: ()->
        # returns theoretical amount of tile overhanging right of screen, yet to be traveled to
        return @tileW + @x - window.innerWidth

    hasTravelledOffscreen: ()->
        # returns true if tile has travelled left off screen
        return (@tileW + @x) < 0

class Sprite
    constructor: (spritesheet, x=0, y=0)->
        # sets up new sprite using given spritesheet src centered at x & y position on canvas
        @sheet = new Image()
        @sheet.src = spritesheet
        @h = 399
        @w = 182
        @x = x
        @y = y
        @frame_n = 0
        @max_frames = 4
        # for slowing animation speed
        @draws_per_frame = 50  # number of draw calls before setting new frame
        @draw_counter = 0

    next_frame: ()->
        @frame_n += 1
        if @frame_n > @max_frames
            @frame_n = 0

    draw: (ctx, x=@x, y=@y) ->
        # draws a sprite centered at given location, or uses internal
        # set locations to start in sprite sheet
        ssx = @frame_n * @w
        ssy = 0  # TODO: use y-axis in spritesheets for different ship conditionals/permuations (damage, age, etc)
        x = x - @w/2
        y = y - @h/2
        ctx.drawImage(@sheet, ssx, ssy, @w, @h, x, y, @w, @h)
        @draw_counter += 1
        if @draw_counter > @draws_per_frame
            @next_frame()
            @draw_counter = 0


# switching to javascript here...
`
var app = angular.module('travel-screen', [
    require('ng-hold'),
    require('game')
]);

app.directive("travelScreen", function() {
    return {
        restrict: 'E',
        templateUrl: "/ng-modules/travelScreen/travelScreen.html"
    };
});

app.controller("travelScreenController", ['$scope', 'data', function($scope, data){
    var vm = this;
    vm.data = data;
    // TODO: do these need to be set after $(document).ready()?
    vm.canvasElement = document.getElementById("travelCanvas");
    vm.ctx = vm.canvasElement.getContext("2d");
    vm.shipImg = document.getElementById("player-ship");

    vm.init = function(){
        vm.tiles = [new Tile(0, document.getElementById("sun-bg"))];
        vm.sprites = {}
        vm.shipY = 300;
    }
    vm.init();
    $scope.$on('resetGame', vm.init);

    vm.travel = function(){
        data.travel();

        vm.tiles.forEach(function(tile){
            tile.travel();
        });

        // remove old offscreen tiles
        while(vm.tiles[0].hasTravelledOffscreen()){
            vm.tiles.splice(0, 1);  // remove leftmost tile
            console.log('tile removed');
        }

        // append new bg tiles if needed
        var overhang = vm.tiles[vm.tiles.length - 1].getOverhang();
        while (overhang < 100){
            vm.tiles.push(new Tile(window.innerWidth + overhang, document.getElementById("test-bg")));
            overhang = vm.tiles[vm.tiles.length -1].getOverhang();
            console.log('tile added');
        }
    }

    vm.drift = function(height){
        // returns slightly drifted modification on given height
        if (Math.random() < 0.01) {  // small chance of drift
            height += Math.round(Math.random() * 2 - 1)
            if (height > 400) {
                height = 399
            }
            if (height < 200) {
                height = 201
            }
        }
        return height;
    }

    vm.drawSprite = function(location, Xposition){
        // draws location if in view at global Xposition
        var spriteW = 500;  // max sprite width (for checking when to draw)

        // if w/in reasonable draw distance
        if (data.distanceTraveled + window.innerWidth + spriteW > Xposition    // if close enough
            && data.distanceTraveled - spriteW < Xposition                  ) { // if we haven't passed it
            if (location in vm.sprites){  // if sprite already in current sprites
                var rel_x = Xposition-data.distanceTraveled;
                vm.sprites[location].x = rel_x
                // use existing y value (add small bit of drift)
                vm.sprites[location].y = vm.drift(vm.sprites[location].y);
                vm.sprites[location].draw(vm.ctx)
            } else {
                // get random y value and add to list of current sprites
                vm.sprites[location] = new Sprite('/assets/sprites/station_sheet.png', -1000, Math.random()*200+200);
            }
            // TODO: remove sprites once we're done with them..
        }
    }

    vm.drawLocations = function(){
        for (var loc in data.locations){
            var pos = data.locations[loc];
            vm.drawSprite(loc, pos);
        }
    }

    vm.drawBg = function(){
        vm.tiles.forEach(function(tile) {
            tile.draw(vm.ctx);
        });
    }

    vm.drawShip = function(){
        var shipW = 150, shipH = 338;
        vm.shipY = vm.drift(vm.shipY);
        vm.ctx.drawImage(vm.shipImg, window.innerWidth/3-shipW/2, vm.shipY-shipH/2);
    }

    vm.draw = function(){
        // resize element to window
        vm.ctx.canvas.width  = window.innerWidth;  //TODO: only do this when needed, not every draw
        vm.drawBg();
        vm.drawLocations();
        vm.drawShip();
    }
    $scope.$on('draw', vm.draw);
}]);

module.exports = angular.module('travel-screen').name;
`