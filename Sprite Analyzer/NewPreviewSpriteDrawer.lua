PreviewDirection = dofile("./PreviewDirection.lua")

local function Flip(image)
    local flippedImage = Image(image.spec)

    for pixel in image:pixels() do
        flippedImage:drawPixel(image.width - 1 - pixel.x, pixel.y, pixel())
    end

    return flippedImage
end

local function Desaturate(image)
    local desaturatedImage = Image(image.spec)

    for pixel in image:pixels() do
        local color = Color(pixel())
        desaturatedImage:drawPixel(pixel.x, pixel.y, Color {
            gray = 0.299 * color.red + 0.114 * color.blue + 0.587 * color.green,
            alpha = color.alpha
        })
    end

    return desaturatedImage
end

local function Silhouette(image)
    local silhouetteImage = Image(image.spec)

    for pixel in image:pixels() do
        silhouetteImage:drawPixel(pixel.x, pixel.y, Color {
            gray = 0,
            alpha = Color(pixel()).alpha
        })
    end

    return silhouetteImage
end

local function OnlyOutline(image, outlineColors)
    local outlineImage = Image(image.spec)
    if outlineColors == nil then return outlineImage end

    for pixel in image:pixels() do
        local pixelColor = Color(pixel())

        for i = 1, #outlineColors do
            if pixelColor == outlineColors[i] then
                outlineImage:drawPixel(pixel.x, pixel.y, Color {
                    gray = 0,
                    alpha = pixelColor.alpha
                })
                break
            end
        end
    end

    return outlineImage
end

local function SilhouetteWithoutOutline(image, outlineColors)
    local silhouetteImage = Image(image.spec)
    if outlineColors == nil then return silhouetteImage end

    for pixel in image:pixels() do
        local pixelColor = Color(pixel())
        local isOutline = false

        for i = 1, #outlineColors do
            if pixelColor == outlineColors[i] then
                isOutline = true
                break
            end
        end

        if not isOutline then
            silhouetteImage:drawPixel(pixel.x, pixel.y, Color {
                gray = 0,
                alpha = pixelColor.alpha
            })
        end
    end

    return silhouetteImage
end

local function FlattenColors(image, flatColorEntries)
    local flattedImage = Image(image.spec)
    if flatColorEntries == nil then return flattedImage end

    for pixel in image:pixels() do
        local pixelColor = Color(pixel())
        flattedImage:drawPixel(pixel.x, pixel.y,
                               Color {gray = 0, alpha = pixelColor.alpha})

        for _, flatColorEntry in ipairs(flatColorEntries) do
            local mainColor = flatColorEntry[1]

            for _, flatColor in ipairs(flatColorEntry) do
                if pixelColor == flatColor then
                    flattedImage:drawPixel(pixel.x, pixel.y, mainColor)
                    break
                end
            end
        end

    end

    return flattedImage
end

local PreviewPositionCalculator = {}

function PreviewPositionCalculator:Init(options)
    self.direction = options and options.direction
    self.bounds = options and options.bounds
    self.padding = options and options.padding

    self.imagesPerRow = 0
    self.imagesPerColumn = 0

    self.currentImageInRow = 0
    self.currentImageInColumn = 0
end

function PreviewPositionCalculator:NextPosition()
    local x = self.padding + (self.padding + self.bounds.width) *
                  self.currentImageInRow
    local y = self.padding + (self.padding + self.bounds.height) *
                  self.currentImageInColumn

    if self.direction == PreviewDirection.Horizontal then
        self.currentImageInRow = self.currentImageInRow + 1
    else
        self.currentImageInColumn = self.currentImageInColumn + 1
    end

    self.imagesPerRow = math.max(self.imagesPerRow, self.currentImageInRow)
    self.imagesPerColumn = math.max(self.imagesPerColumn,
                                    self.currentImageInColumn)

    return Point(x, y)
end

function PreviewPositionCalculator:GoToNextLine()
    if self.direction == PreviewDirection.Horizontal then
        self.currentImageInRow = 0
        self.currentImageInColumn = self.currentImageInColumn + 1
    else
        self.currentImageInRow = self.currentImageInRow + 1
        self.currentImageInColumn = 0
    end

    self.imagesPerRow = math.max(self.imagesPerRow, self.currentImageInRow)
    self.imagesPerColumn = math.max(self.imagesPerColumn,
                                    self.currentImageInColumn)
end

function PreviewPositionCalculator:CalculateSpriteSize()
    local width = self.padding + (self.bounds.width + self.padding) *
                      self.imagesPerRow
    local height = self.padding + (self.bounds.height + self.padding) *
                       self.imagesPerColumn
    return Point(width, height)
end

local PreviewSpriteDrawer = {}

function PreviewSpriteDrawer:Update(imageProvider, previewSprite, bounds,
                                    configuration)
    if app.apiVersion >= 21 and not self.previewDialog then
        self.previewDialog = Dialog("Sprite Breakdown")
        self.previewDialog:canvas{
            width = 100,
            height = 100,
            onpaint = function(ev)
                local gc = ev.context

                gc:drawImage(self.previewImage, 0, 0)
            end
        }
    end

    -- TODO: DO ALL OF THIS IN A SINGLE LOOP OVER "IMAGE:PIXELS()" AND WRITE DIRECTLY TO THE PREVIEW IMAGE, IT WILL BE A LOT OF MATH BUT SO MUCH FASTER
    local padding = configuration.preview and configuration.preview.padding or
                        math.min(bounds.width, bounds.height) / 4

    PreviewPositionCalculator:Init{
        direction = configuration.preview and configuration.preview.direction or
            PreviewDirection.Horizontal,
        bounds = bounds,
        padding = padding
    }

    -- Get the image of the selection from active sprite
    local image = imageProvider:GetImage()

    -- Prepare a list of all images
    local imagesToDraw = {Desaturate(image), image}

    if self:HasFlatColors(configuration.flatColors) then
        table.insert(imagesToDraw,
                     FlattenColors(image, configuration.flatColors))
    end

    if self:HasOutlineColors(configuration.outlineColors) then
        table.insert(imagesToDraw,
                     OnlyOutline(image, configuration.outlineColors))
        -- table.insert(imagesToDraw, SilhouetteWithoutOutline(image,
        --                                                     configuration.outlineColors))
    end

    table.insert(imagesToDraw, Silhouette(image))

    -- Collect all of the positions for the images
    local positionsToDraw = {}
    for i = 1, #imagesToDraw do
        local position = PreviewPositionCalculator:NextPosition()
        table.insert(positionsToDraw, i, position)
    end

    -- Move to the next line
    if configuration.preview and not configuration.preview.singleLine then
        PreviewPositionCalculator:GoToNextLine()
    end

    -- Collect all of the positions for the flipped images
    for i = 1, #imagesToDraw do
        local position = PreviewPositionCalculator:NextPosition()
        table.insert(positionsToDraw, i, position)
    end

    -- One last step to correctly return the size of the sprite
    PreviewPositionCalculator:GoToNextLine()

    -- Calculating the number of images that are going to be there and resizing the sprite first, before drawing to avoid clipping the preview image
    local previewSpriteSize = PreviewPositionCalculator:CalculateSpriteSize()

    -- Create a new preview image
    local previewImage = Image(previewSpriteSize.x, previewSpriteSize.y,
                               ColorMode.RGB)

    -- Draw all images
    for i = 1, #imagesToDraw * 2 do
        local imageToDraw = imagesToDraw[i]
        if i > #imagesToDraw then
            local originalIndex = i - #imagesToDraw
            imageToDraw = Flip(imagesToDraw[originalIndex])
        end

        previewImage:drawImage(imageToDraw, positionsToDraw[i])
    end

    self.previewImage = previewImage
    self.previewDialog:repaint()
    self.previewDialog:show{wait = false}
end

function PreviewSpriteDrawer:HasOutlineColors(outlineColors)
    return outlineColors and #outlineColors > 0 and outlineColors[1].alpha ~= 0
end

function PreviewSpriteDrawer:HasFlatColors(flatColors)
    return flatColors and #flatColors > 0 and flatColors[1] and #flatColors[1] >
               0 and flatColors[1].alpha ~= 0
end

return PreviewSpriteDrawer
