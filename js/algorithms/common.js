
function colorDistance(firstColor, secondColor) {
    return Math.sqrt(Math.pow(firstColor[0] - secondColor[0], 2) + Math.pow(firstColor[1] - secondColor[1], 2) + Math.pow(firstColor[2] - secondColor[2], 2));
}

function colorIsLighterSimple(firstColor, secondColor) {
    return Math.pow(firstColor[0], 2) + Math.pow(firstColor[1], 2) + Math.pow(firstColor[2], 2) >
        Math.pow(secondColor[0], 2) + Math.pow(secondColor[1], 2) + Math.pow(secondColor[2], 2);
}

function colorIsDarkerSimple(firstColor, secondColor) {
    return !colorIsLighterSimple(firstColor, secondColor);
}

function colorIsLighter(firstColor, secondColor, threshold = 0) {
    return !colorIsDarker(firstColor, secondColor, threshold);
}

function colorIsDarker(firstColor, secondColor, threshold = 0) {
    return (firstColor[0] * 0.299 + firstColor[1] * 0.587 + firstColor[2] * 0.114) -
        (secondColor[0] * 0.299 + secondColor[1] * 0.587 + secondColor[2] * 0.114) < threshold;
}

function imageDataToRGBAMatrix(imageData) {
    var resultMatrix = [];

    var index = 0;

    for (var i = 0; i < imageData.height; i++) {
        var row = [];

        for (var j = 0; j < imageData.width; j++) {
            var pixel = [];

            pixel.push(imageData.data[index++]);
            pixel.push(imageData.data[index++]);
            pixel.push(imageData.data[index++]);
            pixel.push(imageData.data[index++]);

            row[j] = pixel;
        }

        resultMatrix[i] = row;
    }

    return resultMatrix;
}

function RGBAMatrixToImageData(matrix, data) {
    var height = matrix.length;
    var width = matrix[0].length;

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            var index = (i * width + j) * 4;

            data[index] = matrix[i][j][0];
            data[index + 1] = matrix[i][j][1];
            data[index + 2] = matrix[i][j][2];
            data[index + 3] = matrix[i][j][3];
        }
    }
}

/** @description Determines whether arrays are equal.  
 * @return {boolean}  
 */  
function arraysAreEqual() {
    var outerArguments = arguments;

    // No arrays passed to compare
    if (arguments.length === 0 || !(arguments[0] instanceof Array)) {
        return false;
    }

    if (arguments.length === 1) {
        return true;
    }

    if (!argumentsAreCorrect()) {
        return false;
    }

    for (var i = 0; i < arguments[0].length; i++) {
        // Check if we have nested arrays
        if (arrayOnIndex(i)) {

            if (arguments.length === 2) {
                if (!arraysAreEqual(arguments[0][i], arguments[1][i])) {
                    return false;
                }
            }
            if (arguments.length === 3) {
                if (!arraysAreEqual(arguments[0][i], arguments[1][i]), arguments[2][i]) {
                    return false;
                }
            }
            if (arguments.length === 4) {
                if (!arraysAreEqual(arguments[0][i], arguments[1][i]), arguments[2][i], arguments[3][i]) {
                    return false;
                }
            }
        }
        else if (!valuesEqualOnIndex(i)) {
            return false;
        }
    }

    return true;

    function valuesEqualOnIndex(index) {
        for (var i = 1; i < outerArguments.length; i++) {
            if (outerArguments[i][index] !== outerArguments[0][index]) {
                return false;
            }
        }

        return true;
    }

    function arrayOnIndex(index) {
        for (var i = 0; i < outerArguments.length; i++) {
            if (!(outerArguments[i][index] instanceof Array)) {
                return false;
            }
        }

        return true;
    }

    function argumentsAreCorrect() {
        var length = outerArguments[0].length;

        for (var i = 1; i < outerArguments.length; i++) {
            if (!(outerArguments[i] instanceof Array) || outerArguments[i].length !== length) {
                return false;
            }
        }

        return true;
    }
}

function create2DArray(width, height, defaultValue) {
    var array = [];

    for (var i = 0; i < height; i++) {
        var row = [];

        for (var j = 0; j < width; j++) {
            row[j] = defaultValue;
        }

        array[i] = row;
    }

    return array;
}

function getColorsByCount(inputMatrix) {
    var colors = [];

    for (var i = 0; i < inputMatrix.length; i++) {
        for (var j = 0; j < inputMatrix[0].length; j++) {
            var value = inputMatrix[i][j];

            if (colors.length == 0) {
                colors.push({
                    value: value,
                    count: 1
                });
                continue;
            }

            var index = -1;

            for (var k = 0; k < colors.length; k++) {
                if (arraysAreEqual(colors[k].value, value)) {
                    index = k;
                    break;
                }
            }

            if (index !== -1) {
                colors[index].count++;
            } else {
                colors.push({
                    value: value,
                    count: 1
                });
            }
        }
    }

    function compare(a, b) {
        let comparison = 0;

        if (a.count > b.count) {
            comparison = 1;
        } else if (b.count > a.count) {
            comparison = -1;
        }

        return comparison;
    }

    colors.sort(compare);

    return colors.map(x => x.value);
}