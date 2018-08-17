function Raven(inputArray) {
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

            // Algorytm Raven
            // Dla wszystkich czterech narożników
            //      Jeśli oba kolory w narożniku są jaśniejsze to wybrać ciemniejszy z nich i ustawić w narozniku
            //      Jeśli oba kolory w narożniku są ciemniejsze to wybrać jaśniejszy z nich i ustawić w narożniku

            doLogic2(y, x, b, d, a, e);
            doLogic2(y, xRight, b, f, c, e);
            doLogic2(yDown, x, d, h, g, e);
            doLogic2(yDown, xRight, f, h, _i, e);
        }
    }

    return resultArray;

    function doLogic(resultArrayY, resultArrayX, a, b, c, e) {
        var darker = colorIsDarker(a, b) ? a : b;
        var lighter = colorIsLighter(a, b) ? a : b;

        if (colorIsLighter(a, e) && colorIsLighter(b, e) && !(colorIsLighter(c, darker) || arraysAreEqual(c, lighter))) {
            resultArray[resultArrayY][resultArrayX] = darker;
        }

        // if (colorIsDarker(a, e) && colorIsDarker(b, e) && !(colorIsDarker(c, lighter) || arraysAreEqual(c, darker))) {
        //     resultArray[resultArrayY][resultArrayX] = lighter;
        // }
    }

    function doLogic2(resultArrayY, resultArrayX, a, b, c, e) {
        var darker = colorIsDarker(a, b) ? a : b;
        var lighter = colorIsLighter(a, b) ? a : b;

        // if (colorIsLighter(a, e) && colorIsLighter(b, e) && !(colorIsLighter(c, darker) || arraysAreEqual(c, lighter))) {
        //     resultArray[resultArrayY][resultArrayX] = darker;
        // }

        if (colorIsDarker(a, e) && colorIsDarker(b, e) && !(colorIsDarker(c, lighter) || arraysAreEqual(c, darker))) {
            resultArray[resultArrayY][resultArrayX] = lighter;
        }
    }
}