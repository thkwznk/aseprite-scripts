
function Tucan(inputArray) {
    var height = inputArray.length;
    var width = inputArray[0].length;

    var sizeFactor = 2;

    // Extract colors from the image
    var colors = getColors(inputArray);
    // colors.reverse();

    var resultArray = create2DArray(width * sizeFactor, height * sizeFactor, [0, 0, 0, 0]);
    // var resultArray = create2DArray(width * sizeFactor, height * sizeFactor, colors[0]);

    for (var i = 0; i < colors.length; i++) {
        // Get layer with only one color
        var currentLayer = getLayer(inputArray, colors[i]);

        // Scale
        currentLayer = scaleLayer(currentLayer, colors[i]);

        // Overlay
        overlayLayer(currentLayer, resultArray);
    }

    return resultArray;
}

function overlayLayer(layer, matrix) {
    for (var i = 0; i < matrix.length; i++) {
        for (var j = 0; j < matrix[0].length; j++) {
            if (layer[i][j].length !== 0) {
                matrix[i][j] = layer[i][j];
            }
        }
    }
}

function scaleLayer(inputMatrix, color) {
    var height = inputMatrix.length;
    var width = inputMatrix[0].length;

    var scaleFactor = 2;

    var resultArray = create2DArray(width * scaleFactor, height * scaleFactor, []);

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            var x = j * scaleFactor;
            var y = i * scaleFactor;

            var xLeft = Math.max(x - 1, 0);
            var xRight = Math.min(x + 1, (width * scaleFactor) - 1);
            var yDown = Math.min(y + 1, (height * scaleFactor) - 1);
            var yUp = Math.max(y - 1, 0);

            resultArray[y][x] = inputMatrix[i][j];
            resultArray[y][xRight] = inputMatrix[i][j];
            resultArray[yDown][x] = inputMatrix[i][j];
            resultArray[yDown][xRight] = inputMatrix[i][j];

            var iUp = Math.max(i - 1, 0);
            var iDown = Math.min(i + 1, height - 1);
            var jRight = Math.min(j + 1, width - 1);
            var jLeft = Math.max(j - 1, 0);

            var b = inputMatrix[iUp][j];

            var d = inputMatrix[i][jLeft];
            var e = inputMatrix[i][j];
            var f = inputMatrix[i][jRight];

            var h = inputMatrix[iDown][j];

            if (arraysAreEqual(b, d) && arraysAreEqual(d, h) && arraysAreEqual(h, f) && !arraysAreEqual(b, [])) {
                continue;
            }

            if (arraysAreEqual(b, d) && !arraysAreEqual(b, [])) {
                resultArray[y][x] = b;
            }
            if (arraysAreEqual(b, f) && !arraysAreEqual(b, [])) {
                resultArray[y][xRight] = b;
            }
            if (arraysAreEqual(d, h) && !arraysAreEqual(h, [])) {
                resultArray[yDown][x] = d;
            }
            if (arraysAreEqual(f, h) && !arraysAreEqual(h, [])) {
                resultArray[yDown][xRight] = f;
            }
        }
    }

    return resultArray;
}

function getLayer(inputMatrix, color) {
    var height = inputMatrix.length;
    var width = inputMatrix[0].length;

    var resultMatrix = create2DArray(width, height, []);

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            if (arraysAreEqual(inputMatrix[i][j], color)) {
                resultMatrix[i][j] = color;
            }
        }
    }

    return resultMatrix;
}

function getColors(inputMatrix) {
    var colors = [];

    for (var i = 0; i < inputMatrix.length; i++) {
        for (var j = 0; j < inputMatrix[0].length; j++) {
            var value = inputMatrix[i][j];

            if (colors.length == 0) {
                colors.push(value);
                continue;
            }

            var unique = true;

            for (var k = 0; k < colors.length; k++) {
                if (arraysAreEqual(colors[k], value)) {
                    unique = false;
                    break;
                }
            }

            if (unique) {
                if (colors.length === 1) {
                    if (colorIsLighter(colors[0], value)) {
                        colors.push(value);
                    } else {
                        colors.unshift(value);
                    }

                    continue;
                }

                if (colorIsLighter(value, colors[0])) {
                    colors.unshift(value);
                    continue;
                }

                if (colorIsDarker(value, colors[colors.length - 1])) {
                    colors.push(value);
                    continue;
                }

                for (var k = 0; k < colors.length - 1; k++) {


                    if ((colorIsLighter(colors[k], value) && colorIsDarker(colors[k + 1], value)) ||
                        (arraysAreEqual(colors[k], value))) {
                        if (k + 1 == colors.length) {
                            colors.push(value);
                        } else {
                            colors.splice(k + 1, 0, value);

                        }
                        break;
                    }
                }
                // if (colorIsLighter(value, colors[0])) {
                //     colors.unshift(value);
                // } else {
                //     colors.push(value);
                // }
            }
        }
    }

    return colors;
}