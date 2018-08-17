var fileInput = document.getElementById('input');
var loader = document.getElementById("loader");

function appendCanvas(name, canvas) {
    var header = document.createElement("div");
    header.className = "box-header";
    header.innerText = name;

    var box = document.createElement('div');
    box.classList.add("box");
    box.classList.add("result");
    box.appendChild(header);
    box.appendChild(canvas);

    document.getElementById("wrapper").appendChild(box);
}

function clearResults() {
    do {
        var results = document.getElementsByClassName("result");

        if (results.length === 0) {
            return;
        }

        var result = document.getElementsByClassName("result")[0];
        result.parentNode.removeChild(result);
    } while (results.length !== 0)
}

function scaleImage(e) {
    var img = new Image;

    img.onload = function () {
        clearResults();

        var canvas = document.createElement("canvas");
        var context = canvas.getContext("2d");

        canvas.width = img.width;
        canvas.height = img.height;
        context.drawImage(img, 0, 0);

        var imageData = context.getImageData(0, 0, canvas.width, canvas.height);
        var rgbaMatrix = imageDataToRGBAMatrix(imageData);

        doLogic(NearestNeighbour, "Nearest Neighbour");
        doLogic(scale2x, "Scale2x");
        doLogic(eagle, "Eagle");
        doLogic(Hawk, "H");
        doLogic(Hawk2, "H2");
        doLogic(Hawk3, "H3");
        doLogic(Hawk3_5, "H3_5");
        doLogic(Hawk4, "H4");
        doLogic(Hawk5, "H5");
        doLogic(Hawk6, "H6");
        doLogic(Hawk7, "H7");
        doLogic(Hawk8, "H8");
        doLogic(Hawk9, "H9");
        
        doLogicForXBR(context);

        function doLogic(algorithm, name) {
            var canvas = document.createElement('canvas');
            var context = canvas.getContext('2d');
            var colorMatrix = algorithm(rgbaMatrix);

            canvas.width = colorMatrix[0].length;
            canvas.height = colorMatrix.length;

            appendCanvas(name, canvas);

            var imageData = context.createImageData(canvas.width, canvas.height);
            RGBAMatrixToImageData(colorMatrix, imageData.data);
            context.putImageData(imageData, 0, 0);
        }

        function doLogicForXBR(inputContext) {
            var canvas = document.createElement('canvas');
            var context = canvas.getContext('2d');

            var image = xBR(inputContext);

            canvas.width = image.width;
            canvas.height = image.height;

            context.putImageData(image, 0, 0);
            appendCanvas("xBR", canvas);
        }
    }

    img.src = URL.createObjectURL(fileInput.files[0]);
}

function S2x(inputArray) {
    var height = inputArray.length;
    var width = inputArray[0].length;

    var sizeFactor = 2;

    var resultArray = create2DArray(width * sizeFactor, height * sizeFactor, []);

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            var x = j * sizeFactor;
            var y = i * sizeFactor;

            resultArray[y][x] = inputArray[i][j];
            resultArray[y + 1][x] = inputArray[i][j];
            resultArray[y][x + 1] = inputArray[i][j];
            resultArray[y + 1][x + 1] = inputArray[i][j];

            var iUp = Math.max(i - 1, 0);
            var iDown = Math.min(i + 1, height - 1);
            var jRight = Math.min(j + 1, width - 1);
            var jLeft = Math.max(j - 1, 0);

            var up = inputArray[iUp][j];
            var right = inputArray[i][jRight];
            var left = inputArray[i][jLeft];
            var down = inputArray[iDown][j];

            var upCenter = inputArray[iUp][j];
            var upRight = inputArray[iUp][jRight];
            var upLeft = inputArray[iUp][jLeft];

            var downLeft = inputArray[iDown][jLeft];
            var downCenter = inputArray[iDown][j];
            var downRight = inputArray[iDown][jRight];

            var middleCenter = inputArray[i][jRight];
            var middleRight = inputArray[i][jRight];
            var middleRight = inputArray[i][jLeft];

            var center = inputArray[i][j];

            // if (colorIsLighter(left, center) &&
            //     colorIsLighter(up, center) &&
            //     colorIsLighter(right, center) &&
            //     colorIsLighter(down, center)) {
            //     continue;
            // }

            if (colorIsLighter(left, center) &&
                colorIsLighter(up, center) &&
                colorIsLighter(left, downLeft) &&
                colorIsLighter(up, upRight) &&
                !colorIsDarker(upLeft, center)) {
                resultArray[y][x] = colorIsDarker(left, up) ? left : up;
            }
            if (colorIsLighter(up, center) &&
                colorIsLighter(right, center) &&
                colorIsLighter(up, upLeft) &&
                colorIsLighter(right, downRight) &&
                !colorIsDarker(upRight, center)) {
                resultArray[y][x + 1] = colorIsDarker(up, right) ? up : right;
            }
            if (colorIsLighter(down, center) &&
                colorIsLighter(left, center) &&
                colorIsLighter(down, downRight) &&
                colorIsLighter(left, upLeft) &&
                !colorIsDarker(downLeft, center)) {
                resultArray[y + 1][x] = colorIsDarker(down, left) ? down : left;
            }
            if (colorIsLighter(right, center) &&
                colorIsLighter(down, center) &&
                colorIsLighter(right, upRight) &&
                colorIsLighter(down, downLeft) &&
                !colorIsDarker(downRight, center)) {
                resultArray[y + 1][x + 1] = colorIsDarker(right, down) ? right : down;
            }
        }
    }

    return resultArray;
}

function Tucan2(inputArray) {
    var height = inputArray.length;
    var width = inputArray[0].length;

    var sizeFactor = 2;

    var threshold = 4;

    // var colors = getColorsByCount(inputArray);
    var colors = getColors(inputArray);
    var outline = colors.slice(0, threshold);
    colors = colors.slice(threshold, colors.length).concat(outline);

    var resultArray = create2DArray(width * sizeFactor, height * sizeFactor, [0, 0, 0, 0]);

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

function Hawk9(inputArray) {
    var height = inputArray.length;
    var width = inputArray[0].length;

    var sizeFactor = 2;

    var resultArray = create2DArray(width * sizeFactor, height * sizeFactor, []);

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            var x = j * sizeFactor;
            var y = i * sizeFactor;

            var xLeft = Math.max(x - 1, 0);
            var xRight = Math.min(x + 1, (width * sizeFactor) - 1);
            var yDown = Math.min(y + 1, (height * sizeFactor) - 1);
            var yUp = Math.max(y - 1, 0);

            resultArray[y][x] = inputArray[i][j];
            resultArray[y][xRight] = inputArray[i][j];
            resultArray[yDown][x] = inputArray[i][j];
            resultArray[yDown][xRight] = inputArray[i][j];

            var iUp = Math.max(i - 1, 0);
            var iDown = Math.min(i + 1, height - 1);
            var jRight = Math.min(j + 1, width - 1);
            var jLeft = Math.max(j - 1, 0);

            var a = inputArray[iUp][jLeft];
            var b = inputArray[iUp][j];
            var c = inputArray[iUp][jRight];

            var d = inputArray[i][jLeft];
            var e = inputArray[i][j];
            var f = inputArray[i][jRight];

            var g = inputArray[iDown][jLeft];
            var h = inputArray[iDown][j];
            var _i = inputArray[iDown][jRight];

            doLogic(y, x, b, d, a, f, h, _i, c, g);
            doLogic(y, xRight, b, f, c, d, g, h, a, _i);
            doLogic(yDown, x, d, h, g, b, c, f, a, _i);
            doLogic(yDown, xRight, h, f, _i, a, b, d, c, g);

            // Spróbować - bliżej jednemu kolorowi do innego

            function doLogic(resultArrayY, resultArrayX, B, D, A, F, H, I, C, G) {
                if (arraysAreEqual(A, e)) {
                    return;
                }

                if (!colorIsDarker(A, B) || !colorIsDarker(A, D)) {
                    if (colorIsLighter(B, e) && colorIsLighter(D, e)) {
                        resultArray[resultArrayY][resultArrayX] = colorIsDarker(B, D) ? B : D;
                        return;
                    }
                }

                // if(!colorIsLighter(A, B) && !colorIsLighter(A, D)){
                if (!colorIsLighter(A, B) && !colorIsLighter(A, D)) {
                    if (colorIsDarker(B, e) && colorIsDarker(D, e)) {
                        if (!(colorIsLighter(e, D) && colorIsLighter(H, D) && colorIsLighter(G, D)) && !(colorIsLighter(e, B) && colorIsLighter(C, B) && colorIsLighter(F, B))) {
                            resultArray[resultArrayY][resultArrayX] = colorIsLighter(B, D) ? B : D;

                        }

                    }
                }

                // if (colorIsDarker(e, A) && (!colorIsDarker(A, B) && !colorIsDarker(A, D))) {
                //     if (colorIsLighter(B, e) && colorIsLighter(D, e)) {
                //         resultArray[resultArrayY][resultArrayX] = colorIsLighter(B, D) ? D : B;
                //     }
                // } else if (colorIsDarker(B, e) && colorIsDarker(D, e) && colorIsDarker(A, e) && !colorIsDarker(e, F) && !colorIsDarker(e, H) && !colorIsDarker(e, I)&& !colorIsDarker(e, C) && !colorIsDarker(e, G)) {
                //     resultArray[resultArrayY][resultArrayX] = colorIsDarker(B, D) ? D : B;
                // }
            }
        }
    }

    return resultArray;
}

function Hawk8(inputArray) {
    var height = inputArray.length;
    var width = inputArray[0].length;

    var sizeFactor = 2;

    var resultArray = create2DArray(width * sizeFactor, height * sizeFactor, []);

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            var x = j * sizeFactor;
            var y = i * sizeFactor;

            var xLeft = Math.max(x - 1, 0);
            var xRight = Math.min(x + 1, (width * sizeFactor) - 1);
            var yDown = Math.min(y + 1, (height * sizeFactor) - 1);
            var yUp = Math.max(y - 1, 0);

            resultArray[y][x] = inputArray[i][j];
            resultArray[y][xRight] = inputArray[i][j];
            resultArray[yDown][x] = inputArray[i][j];
            resultArray[yDown][xRight] = inputArray[i][j];

            var iUp = Math.max(i - 1, 0);
            var iDown = Math.min(i + 1, height - 1);
            var jRight = Math.min(j + 1, width - 1);
            var jLeft = Math.max(j - 1, 0);

            var a = inputArray[iUp][jLeft];
            var b = inputArray[iUp][j];
            var c = inputArray[iUp][jRight];

            var d = inputArray[i][jLeft];
            var e = inputArray[i][j];
            var f = inputArray[i][jRight];

            var g = inputArray[iDown][jLeft];
            var h = inputArray[iDown][j];
            var _i = inputArray[iDown][jRight];

            // if (!arraysAreEqual(a, e) &&
            //     !arraysAreEqual(b, e) &&
            //     !arraysAreEqual(c, e) &&
            //     !arraysAreEqual(d, e) &&
            //     !arraysAreEqual(f, e) &&
            //     !arraysAreEqual(g, e) &&
            //     !arraysAreEqual(h, e) &&
            //     !arraysAreEqual(_i, e)) {
            //     continue;
            // }

            doLogic(y, x, b, d, a, f, h, _i);
            doLogic(y, xRight, b, f, c, d, g, h);
            doLogic(yDown, x, d, h, g, b, c, f);
            doLogic(yDown, xRight, h, f, _i, a, b, d);

            function doLogic(resultArrayY, resultArrayX, B, D, A, F, H, I) {
                if (colorIsDarker(e, A) && (!colorIsDarker(A, B) && !colorIsDarker(A, D))) {
                    if (colorIsLighter(B, e)) {
                        if (arraysAreEqual(B, D) || colorIsLighter(D, e)) {
                            resultArray[resultArrayY][resultArrayX] = colorIsLighter(B, D) ? D : B;
                        }
                    }
                } else if (colorIsDarker(B, e) && colorIsDarker(D, e) && colorIsDarker(A, e) && !colorIsDarker(e, F) && !colorIsDarker(e, H) && !colorIsDarker(e, I)) {
                    resultArray[resultArrayY][resultArrayX] = colorIsDarker(B, D) ? D : B;
                }
            }
        }
    }

    return resultArray;
}

function Hawk7(inputArray) {
    var height = inputArray.length;
    var width = inputArray[0].length;

    var sizeFactor = 2;

    var resultArray = create2DArray(width * sizeFactor, height * sizeFactor, []);

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            var x = j * sizeFactor;
            var y = i * sizeFactor;

            var xLeft = Math.max(x - 1, 0);
            var xRight = Math.min(x + 1, (width * sizeFactor) - 1);
            var yDown = Math.min(y + 1, (height * sizeFactor) - 1);
            var yUp = Math.max(y - 1, 0);

            resultArray[y][x] = inputArray[i][j];
            resultArray[y][xRight] = inputArray[i][j];
            resultArray[yDown][x] = inputArray[i][j];
            resultArray[yDown][xRight] = inputArray[i][j];

            var iUp = Math.max(i - 1, 0);
            var iDown = Math.min(i + 1, height - 1);
            var jRight = Math.min(j + 1, width - 1);
            var jLeft = Math.max(j - 1, 0);

            var a = inputArray[iUp][jLeft];
            var b = inputArray[iUp][j];
            var c = inputArray[iUp][jRight];

            var d = inputArray[i][jLeft];
            var e = inputArray[i][j];
            var f = inputArray[i][jRight];

            var g = inputArray[iDown][jLeft];
            var h = inputArray[iDown][j];
            var _i = inputArray[iDown][jRight];

            if (!arraysAreEqual(e, a) && !colorIsLighter(e, a) && (!colorIsDarker(a, b) || !colorIsDarker(a, d))) {
                if (arraysAreEqual(b, d)) {
                    if (colorIsLighter(b, e)) {
                        resultArray[y][x] = b;
                    }
                } else if (colorIsLighter(b, e) && colorIsLighter(d, e)) {
                    resultArray[y][x] = colorIsLighter(b, d) ? d : b;
                }
            }

            if (!arraysAreEqual(e, c) && !colorIsLighter(e, c) && (!colorIsDarker(c, b) || !colorIsDarker(c, f))) {
                if (arraysAreEqual(b, f)) {
                    if (colorIsLighter(b, e)) {
                        resultArray[y][xRight] = b;
                    }
                } else if (colorIsLighter(b, e) && colorIsLighter(f, e)) {
                    resultArray[y][xRight] = colorIsLighter(b, f) ? f : b;
                }
            }

            if (!arraysAreEqual(e, g) && !colorIsLighter(e, g) && (!colorIsDarker(g, d) || !colorIsDarker(g, h))) {
                if (arraysAreEqual(d, h)) {
                    if (colorIsLighter(d, e)) {
                        resultArray[yDown][x] = d;
                    }
                } else if (colorIsLighter(d, e) && colorIsLighter(h, e)) {
                    resultArray[yDown][x] = colorIsLighter(d, h) ? h : d;
                }
            }

            if (!arraysAreEqual(e, _i) && !colorIsLighter(e, _i) && (!colorIsDarker(_i, f) || !colorIsDarker(_i, h))) {
                if (arraysAreEqual(f, h)) {
                    if (colorIsLighter(f, e)) {
                        resultArray[yDown][xRight] = h;

                    }
                } else if (colorIsLighter(f, e) && colorIsLighter(h, e)) {
                    resultArray[yDown][xRight] = colorIsLighter(f, h) ? h : f;
                }
            }

            // if (!arraysAreEqual(e, a) && !colorIsLighter(e, a)) {
            //     if (arraysAreEqual(b, d)) {
            //         if (colorIsLighter(b, e)) {
            //             resultArray[y][x] = b;
            //         }
            //     } else if (colorIsLighter(b, e) && colorIsLighter(d, e)) {
            //         resultArray[y][x] = colorIsLighter(b, d) ? d : b;
            //     }
            // }

            // if (!arraysAreEqual(e, c) && !colorIsLighter(e, c)) {
            //     if (arraysAreEqual(b, f)) {
            //         if (colorIsLighter(b, e)) {
            //             resultArray[y][xRight] = b;
            //         }
            //     } else if (colorIsLighter(b, e) && colorIsLighter(f, e)) {
            //         resultArray[y][xRight] = colorIsLighter(b, f) ? f : b;
            //     }
            // }

            // if (!arraysAreEqual(e, g) && !colorIsLighter(e, g)) {
            //     if (arraysAreEqual(d, h)) {
            //         if (colorIsLighter(d, e)) {
            //             resultArray[yDown][x] = d;
            //         }
            //     } else if (colorIsLighter(d, e) && colorIsLighter(h, e)) {
            //         resultArray[yDown][x] = colorIsLighter(d, h) ? h : d;
            //     }
            // }

            // if (!arraysAreEqual(e, _i) && !colorIsLighter(e, _i)) {
            //     if (arraysAreEqual(f, h)) {
            //         if (colorIsLighter(f, e)) {
            //             resultArray[yDown][xRight] = h;

            //         }
            //     } else if (colorIsLighter(f, e) && colorIsLighter(h, e)) {
            //         resultArray[yDown][xRight] = colorIsLighter(f, h) ? h : f;
            //     }
            // }

        }
    }

    return resultArray;
}

// NHawk
// 1. Get input color pixel (center)
// 2. Find which pixels around have the same colour and calculate a number based on It
// 3. Get the pattern based on the number
// 4. Repeat

// Hawk2
// Sprawdź czy kolory po skosie są takie same
//  Jeśli nie to sprawdź czy są bliżej siebie niż mnie
//      Jeśli tak to zetnij po skosie ciemniejszym z nich

function Hawk6(inputArray) {
    var height = inputArray.length;
    var width = inputArray[0].length;

    var sizeFactor = 2;

    var resultArray = create2DArray(width * sizeFactor, height * sizeFactor, []);

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            var x = j * sizeFactor;
            var y = i * sizeFactor;

            var xLeft = Math.max(x - 1, 0);
            var xRight = Math.min(x + 1, (width * sizeFactor) - 1);
            var yDown = Math.min(y + 1, (height * sizeFactor) - 1);
            var yUp = Math.max(y - 1, 0);

            resultArray[y][x] = inputArray[i][j];
            resultArray[y][xRight] = inputArray[i][j];
            resultArray[yDown][x] = inputArray[i][j];
            resultArray[yDown][xRight] = inputArray[i][j];

            var iUp = Math.max(i - 1, 0);
            var iDown = Math.min(i + 1, height - 1);
            var jRight = Math.min(j + 1, width - 1);
            var jLeft = Math.max(j - 1, 0);

            var a = inputArray[iUp][jLeft];
            var b = inputArray[iUp][j];
            var c = inputArray[iUp][jRight];

            var d = inputArray[i][jLeft];
            var e = inputArray[i][j];
            var f = inputArray[i][jRight];

            var g = inputArray[iDown][jLeft];
            var h = inputArray[iDown][j];
            var _i = inputArray[iDown][jRight];

            if (arraysAreEqual(b, d)) {
                if (colorIsLighter(b, e)) {
                    resultArray[y][x] = b;
                }
            } else if (colorIsLighter(b, e) && colorIsLighter(d, e)) {
                resultArray[y][x] = colorIsLighter(b, d) ? d : b;
            }

            if (arraysAreEqual(b, f)) {
                if (colorIsLighter(b, e)) {
                    resultArray[y][xRight] = b;
                }
            } else if (colorIsLighter(b, e) && colorIsLighter(f, e)) {
                resultArray[y][xRight] = colorIsLighter(b, f) ? f : b;
            }

            if (arraysAreEqual(d, h)) {
                if (colorIsLighter(d, e)) {
                    resultArray[yDown][x] = d;
                }
            } else if (colorIsLighter(d, e) && colorIsLighter(h, e)) {
                resultArray[yDown][x] = colorIsLighter(d, h) ? h : d;
            }

            if (arraysAreEqual(f, h)) {
                if (colorIsLighter(f, e)) {
                    resultArray[yDown][xRight] = h;

                }
            } else if (colorIsLighter(f, e) && colorIsLighter(h, e)) {
                resultArray[yDown][xRight] = colorIsLighter(f, h) ? h : f;
            }
        }
    }

    return resultArray;
}

function Hawk5(inputArray) {
    var height = inputArray.length;
    var width = inputArray[0].length;

    var sizeFactor = 2;

    var resultArray = create2DArray(width * sizeFactor, height * sizeFactor, []);

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            var x = j * sizeFactor;
            var y = i * sizeFactor;

            var xLeft = Math.max(x - 1, 0);
            var xRight = Math.min(x + 1, (width * sizeFactor) - 1);
            var yDown = Math.min(y + 1, (height * sizeFactor) - 1);
            var yUp = Math.max(y - 1, 0);

            resultArray[y][x] = inputArray[i][j];
            resultArray[y][xRight] = inputArray[i][j];
            resultArray[yDown][x] = inputArray[i][j];
            resultArray[yDown][xRight] = inputArray[i][j];

            var iUp = Math.max(i - 1, 0);
            var iDown = Math.min(i + 1, height - 1);
            var jRight = Math.min(j + 1, width - 1);
            var jLeft = Math.max(j - 1, 0);

            var a = inputArray[iUp][jLeft];
            var b = inputArray[iUp][j];
            var c = inputArray[iUp][jRight];

            var d = inputArray[i][jLeft];
            var e = inputArray[i][j];
            var f = inputArray[i][jRight];

            var g = inputArray[iDown][jLeft];
            var h = inputArray[iDown][j];
            var _i = inputArray[iDown][jRight];

            if (arraysAreEqual(b, d) && arraysAreEqual(d, h) && arraysAreEqual(h, f)) {
                continue;
            }

            if (arraysAreEqual(b, d)) {
                if (colorIsLighter(b, e)) {
                    resultArray[y][x] = b;
                }
            } else if (colorIsLighter(b, e) && colorIsLighter(d, e)) {
                resultArray[y][x] = colorIsLighter(b, d) ? d : b;
            }

            if (arraysAreEqual(b, f)) {
                if (colorIsLighter(b, e)) {
                    resultArray[y][xRight] = b;
                }
            } else if (colorIsLighter(b, e) && colorIsLighter(f, e)) {
                resultArray[y][xRight] = colorIsLighter(b, f) ? f : b;
            }

            if (arraysAreEqual(d, h)) {
                if (colorIsLighter(d, e)) {
                    resultArray[yDown][x] = d;
                }
            } else if (colorIsLighter(d, e) && colorIsLighter(h, e)) {
                resultArray[yDown][x] = colorIsLighter(d, h) ? h : d;
            }

            if (arraysAreEqual(f, h)) {
                if (colorIsLighter(f, e)) {
                    resultArray[yDown][xRight] = h;

                }
            } else if (colorIsLighter(f, e) && colorIsLighter(h, e)) {
                resultArray[yDown][xRight] = colorIsLighter(f, h) ? h : f;
            }
        }
    }

    return resultArray;
}

function Hawk4(inputArray) {
    var height = inputArray.length;
    var width = inputArray[0].length;

    var sizeFactor = 2;

    var resultArray = create2DArray(width * sizeFactor, height * sizeFactor, []);

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            var x = j * sizeFactor;
            var y = i * sizeFactor;

            var xLeft = Math.max(x - 1, 0);
            var xRight = Math.min(x + 1, (width * sizeFactor) - 1);
            var yDown = Math.min(y + 1, (height * sizeFactor) - 1);
            var yUp = Math.max(y - 1, 0);

            resultArray[y][x] = inputArray[i][j];
            resultArray[y][xRight] = inputArray[i][j];
            resultArray[yDown][x] = inputArray[i][j];
            resultArray[yDown][xRight] = inputArray[i][j];

            var iUp = Math.max(i - 1, 0);
            var iDown = Math.min(i + 1, height - 1);
            var jRight = Math.min(j + 1, width - 1);
            var jLeft = Math.max(j - 1, 0);

            var a = inputArray[iUp][jLeft];
            var b = inputArray[iUp][j];
            var c = inputArray[iUp][jRight];

            var d = inputArray[i][jLeft];
            var e = inputArray[i][j];
            var f = inputArray[i][jRight];

            var g = inputArray[iDown][jLeft];
            var h = inputArray[iDown][j];
            var _i = inputArray[iDown][jRight];

            if (arraysAreEqual(b, d) && arraysAreEqual(d, h) && arraysAreEqual(h, f)) {
                continue;
            }

            if (arraysAreEqual(b, d)) {
                if (colorIsLighter(b, e)) {
                    resultArray[y][x] = b;
                }
            } else if (colorIsLighter(b, e) && colorIsLighter(d, e) && !arraysAreEqual(e, a)) {
                resultArray[y][x] = colorIsLighter(b, d) ? d : b;
            }

            if (arraysAreEqual(b, f)) {
                if (colorIsLighter(b, e)) {
                    resultArray[y][xRight] = b;
                }
            } else if (colorIsLighter(b, e) && colorIsLighter(f, e) && !arraysAreEqual(e, c)) {
                resultArray[y][xRight] = colorIsLighter(b, f) ? f : b;
            }

            if (arraysAreEqual(d, h)) {
                if (colorIsLighter(d, e)) {
                    resultArray[yDown][x] = d;
                }
            } else if (colorIsLighter(d, e) && colorIsLighter(h, e) && !arraysAreEqual(e, g)) {
                resultArray[yDown][x] = colorIsLighter(d, h) ? h : d;
            }

            if (arraysAreEqual(f, h)) {
                if (colorIsLighter(f, e)) {
                    resultArray[yDown][xRight] = h;

                }
            } else if (colorIsLighter(f, e) && colorIsLighter(h, e) && !arraysAreEqual(e, _i)) {
                resultArray[yDown][xRight] = colorIsLighter(f, h) ? h : f;
            }

        }
    }

    return resultArray;
}

function Hawk3_5(inputArray) {
    var height = inputArray.length;
    var width = inputArray[0].length;

    var sizeFactor = 2;

    var resultArray = create2DArray(width * sizeFactor, height * sizeFactor, []);

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            var x = j * sizeFactor;
            var y = i * sizeFactor;

            var xLeft = Math.max(x - 1, 0);
            var xRight = Math.min(x + 1, (width * sizeFactor) - 1);
            var yDown = Math.min(y + 1, (height * sizeFactor) - 1);
            var yUp = Math.max(y - 1, 0);

            resultArray[y][x] = inputArray[i][j];
            resultArray[y][xRight] = inputArray[i][j];
            resultArray[yDown][x] = inputArray[i][j];
            resultArray[yDown][xRight] = inputArray[i][j];

            var iUp = Math.max(i - 1, 0);
            var iDown = Math.min(i + 1, height - 1);
            var jRight = Math.min(j + 1, width - 1);
            var jLeft = Math.max(j - 1, 0);

            var a = inputArray[iUp][jLeft];
            var b = inputArray[iUp][j];
            var c = inputArray[iUp][jRight];

            var d = inputArray[i][jLeft];
            var e = inputArray[i][j];
            var f = inputArray[i][jRight];

            var g = inputArray[iDown][jLeft];
            var h = inputArray[iDown][j];
            var _i = inputArray[iDown][jRight];

            doLogic(y, x, b, d, h, f);
            doLogic(y, xRight, b, f, h, d);
            doLogic(yDown, x, d, h, f, b);
            doLogic(yDown, xRight, f, h, d, b);

            function doLogic(resultArrayY, resultArrayX, a, b, c, d) {
                if (colorIsDarker(a, e) && colorIsDarker(b, e) &&
                    (colorIsDarker(b, c) || colorIsDarker(a, d))) {
                    // ((colorIsDarker(b, c) || arraysAreEqual(b, c)) || (colorIsDarker(a, d) || arraysAreEqual(a, d)))) {
                    resultArray[resultArrayY][resultArrayX] = colorIsLighter(a, b) ? a : b;
                }
            }
        }
    }

    return resultArray;
}

function Hawk3(inputArray) {
    var height = inputArray.length;
    var width = inputArray[0].length;

    var sizeFactor = 2;

    var resultArray = create2DArray(width * sizeFactor, height * sizeFactor, []);

    var threshold = 0;

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            var x = j * sizeFactor;
            var y = i * sizeFactor;

            var xLeft = Math.max(x - 1, 0);
            var xRight = Math.min(x + 1, (width * sizeFactor) - 1);
            var yDown = Math.min(y + 1, (height * sizeFactor) - 1);
            var yUp = Math.max(y - 1, 0);

            resultArray[y][x] = inputArray[i][j];
            resultArray[y][xRight] = inputArray[i][j];
            resultArray[yDown][x] = inputArray[i][j];
            resultArray[yDown][xRight] = inputArray[i][j];

            var iUp = Math.max(i - 1, 0);
            var iDown = Math.min(i + 1, height - 1);
            var jRight = Math.min(j + 1, width - 1);
            var jLeft = Math.max(j - 1, 0);

            var a = inputArray[iUp][jLeft];
            var b = inputArray[iUp][j];
            var c = inputArray[iUp][jRight];

            var d = inputArray[i][jLeft];
            var e = inputArray[i][j];
            var f = inputArray[i][jRight];

            var g = inputArray[iDown][jLeft];
            var h = inputArray[iDown][j];
            var _i = inputArray[iDown][jRight];

            // Algorytm Raven
            // Dla wszystkich czterech narożników
            //      Jeśli oba kolory w narożniku są jaśniejsze to wybrać ciemniejszy z nich i ustawić w narozniku
            //      Jeśli oba kolory w narożniku są ciemniejsze to wybrać jaśniejszy z nich i ustawić w narożniku

            // Tylko test, było częścią rozwiązania
            // if (arraysAreEqual(b, d) && arraysAreEqual(d, h) && arraysAreEqual(h, f)) {
            //     continue;
            // }

            // if(colorIsDarker(a, e) &&
            //     colorIsDarker(b, e) &&
            //     colorIsDarker(c, e) &&
            //     colorIsDarker(d, e) &&
            //     colorIsDarker(f, e) &&
            //     colorIsDarker(g, e) &&
            //     colorIsDarker(h, e) &&
            //     colorIsDarker(_i, e)){
            //         continue;
            // }

            // if (!arraysAreEqual(e, a)) {
            // if (colorIsDarker(b, a) && colorIsDarker(d, a)) {
            // if (arraysAreEqual(b, d)) {
            //     if (colorIsDarker(b, e, threshold)) {
            //         resultArray[y][x] = b;
            //     }
            // } else if (colorIsDarker(b, e, threshold) && colorIsDarker(d, e, threshold)) {
            //     resultArray[y][x] = colorIsDarker(b, d, threshold) ? d : b;
            // }
            // }

            if (colorIsDarker(b, e, threshold) && colorIsDarker(d, e, threshold) &&
                (colorIsDarker(b, f, threshold) || colorIsDarker(d, h))) {
                resultArray[y][x] = colorIsDarker(b, d, threshold) ? d : b;
            }

            if (colorIsDarker(b, e, threshold) && colorIsDarker(f, e, threshold) &&
                (colorIsDarker(b, d, threshold) || colorIsDarker(f, h))) {
                resultArray[y][xRight] = colorIsDarker(b, f, threshold) ? f : b;
            }

            if (colorIsDarker(d, e, threshold) && colorIsDarker(h, e, threshold) &&
                (colorIsDarker(d, b, threshold) || colorIsDarker(f, h))) {
                resultArray[yDown][x] = colorIsDarker(d, h, threshold) ? h : d;
            }

            if (colorIsDarker(f, e, threshold) && colorIsDarker(h, e, threshold) &&
                (colorIsDarker(f, b, threshold) || colorIsDarker(h, d))) {
                resultArray[yDown][xRight] = colorIsDarker(f, h, threshold) ? h : f;
            }
        }
    }

    return resultArray;
}

function Hawk2(inputArray) {
    var height = inputArray.length;
    var width = inputArray[0].length;

    var sizeFactor = 2;

    var resultArray = create2DArray(width * sizeFactor, height * sizeFactor, []);

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            var x = j * sizeFactor;
            var y = i * sizeFactor;

            var xLeft = Math.max(x - 1, 0);
            var xRight = Math.min(x + 1, (width * sizeFactor) - 1);
            var yDown = Math.min(y + 1, (height * sizeFactor) - 1);
            var yUp = Math.max(y - 1, 0);

            resultArray[y][x] = inputArray[i][j];
            resultArray[y][xRight] = inputArray[i][j];
            resultArray[yDown][x] = inputArray[i][j];
            resultArray[yDown][xRight] = inputArray[i][j];

            var iUp = Math.max(i - 1, 0);
            var iDown = Math.min(i + 1, height - 1);
            var jRight = Math.min(j + 1, width - 1);
            var jLeft = Math.max(j - 1, 0);

            var a = inputArray[iUp][jLeft];
            var b = inputArray[iUp][j];
            var c = inputArray[iUp][jRight];

            var d = inputArray[i][jLeft];
            var e = inputArray[i][j];
            var f = inputArray[i][jRight];

            var g = inputArray[iDown][jLeft];
            var h = inputArray[iDown][j];
            var _i = inputArray[iDown][jRight];

            if (arraysAreEqual(b, d) && arraysAreEqual(d, h) && arraysAreEqual(h, f)) {
                continue;
            }

            if (arraysAreEqual(b, d)) {
                if (colorIsLighter(b, e)) {
                    resultArray[y][x] = b;
                }
            } else if (colorIsLighter(b, e) && colorIsLighter(d, e) && !arraysAreEqual(e, a)) {
                resultArray[y][x] = colorIsLighter(b, d) ? d : b;
            }

            if (arraysAreEqual(b, f)) {
                if (colorIsLighter(b, e)) {
                    resultArray[y][xRight] = b;
                }
            } else if (colorIsLighter(b, e) && colorIsLighter(f, e) && !arraysAreEqual(e, c)) {
                resultArray[y][xRight] = colorIsLighter(b, f) ? f : b;
            }

            if (arraysAreEqual(d, h)) {
                if (colorIsLighter(d, e)) {
                    resultArray[yDown][x] = d;
                }
            } else if (colorIsLighter(d, e) && colorIsLighter(h, e) && !arraysAreEqual(e, g)) {
                resultArray[yDown][x] = colorIsLighter(d, h) ? h : d;
            }

            if (arraysAreEqual(f, h)) {
                if (colorIsLighter(f, e)) {
                    resultArray[yDown][xRight] = h;

                }
            } else if (colorIsLighter(f, e) && colorIsLighter(h, e) && !arraysAreEqual(e, _i)) {
                resultArray[yDown][xRight] = colorIsLighter(f, h) ? h : f;
            }
        }
    }

    return resultArray;
}

function Hawk(inputArray) {
    var height = inputArray.length;
    var width = inputArray[0].length;

    var sizeFactor = 2;

    var resultArray = create2DArray(width * sizeFactor, height * sizeFactor, []);

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            var x = j * sizeFactor;
            var y = i * sizeFactor;

            var xLeft = Math.max(x - 1, 0);
            var xRight = Math.min(x + 1, (width * sizeFactor) - 1);
            var yDown = Math.min(y + 1, (height * sizeFactor) - 1);
            var yUp = Math.max(y - 1, 0);

            resultArray[y][x] = inputArray[i][j];
            resultArray[y][xRight] = inputArray[i][j];
            resultArray[yDown][x] = inputArray[i][j];
            resultArray[yDown][xRight] = inputArray[i][j];

            var iUp = Math.max(i - 1, 0);
            var iDown = Math.min(i + 1, height - 1);
            var jRight = Math.min(j + 1, width - 1);
            var jLeft = Math.max(j - 1, 0);

            var a = inputArray[iUp][jLeft];
            var b = inputArray[iUp][j];
            var c = inputArray[iUp][jRight];

            var d = inputArray[i][jLeft];
            var e = inputArray[i][j];
            var f = inputArray[i][jRight];

            var g = inputArray[iDown][jLeft];
            var h = inputArray[iDown][j];
            var _i = inputArray[iDown][jRight];

            if (arraysAreEqual(b, d) && arraysAreEqual(d, h) && arraysAreEqual(h, f)) {
                continue;
            }

            // if(arraysAreEqual(b, d)){
            //     resultArray[y][x] = b;
            // }
            // if(arraysAreEqual(b, f)){
            //     resultArray[y][xRight] = b;
            // }
            // if(arraysAreEqual(d, h)){
            //     resultArray[yDown][x] = d;
            // }
            // if(arraysAreEqual(f, h)){
            //     resultArray[yDown][xRight] = f;
            // }

            // if(arraysAreEqual(b, d) && !arraysAreEqual(a, e)){
            //     resultArray[y][x] = b;
            // }
            // if(arraysAreEqual(b, f) && !arraysAreEqual(c, e)){
            //     resultArray[y][xRight] = b;
            // }
            // if(arraysAreEqual(d, h) && !arraysAreEqual(g, e)){
            //     resultArray[yDown][x] = d;
            // }
            // if(arraysAreEqual(f, h) && !arraysAreEqual(_i, e)){
            //     resultArray[yDown][xRight] = f;
            // }

            if (arraysAreEqual(b, d) && !colorIsLighter(e, b)) {
                resultArray[y][x] = b;
            }
            if (arraysAreEqual(b, f) && !colorIsLighter(e, b)) {
                resultArray[y][xRight] = b;
            }
            if (arraysAreEqual(d, h) && !colorIsLighter(e, d)) {
                resultArray[yDown][x] = d;
            }
            if (arraysAreEqual(f, h) && !colorIsLighter(e, f)) {
                resultArray[yDown][xRight] = f;
            }
        }
    }

    return resultArray;
}

function showLoader() {
    loader.style.display = "block";
}

function hideLoader() {
    loader.style.display = "none";
}