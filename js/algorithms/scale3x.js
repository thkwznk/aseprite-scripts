function scale3x(inputArray) {
    var height = inputArray.length;
    var width = inputArray[0].length;

    var resultArray = create2DArray(width * 3, height * 3, []);

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            var x = j * 3;
            var y = i * 3;

            var xLeft = Math.max(x - 1, 0);
            var xRight = Math.min(x + 1, (width * 3) - 1);
            var yDown = Math.min(y + 1, (height * 3) - 1);
            var yUp = Math.max(y - 1, 0);

            resultArray[y][x] = inputArray[i][j];
            resultArray[y][xRight] = inputArray[i][j];
            resultArray[y][xLeft] = inputArray[i][j];

            resultArray[yDown][x] = inputArray[i][j];
            resultArray[yDown][xRight] = inputArray[i][j];
            resultArray[yDown][xLeft] = inputArray[i][j];

            resultArray[yUp][x] = inputArray[i][j];
            resultArray[yUp][xRight] = inputArray[i][j];
            resultArray[yUp][xLeft] = inputArray[i][j];

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

            if (arraysAreEqual(d, b) &&
                !arraysAreEqual(d, h) &&
                !arraysAreEqual(b, f)) {
                resultArray[yUp][xLeft] = d;
            }
            if ((arraysAreEqual(d, b) &&
                !arraysAreEqual(d, h) &&
                !arraysAreEqual(b, f) &&
                !arraysAreEqual(e, c)) ||
                (arraysAreEqual(b, f) &&
                    !arraysAreEqual(b, d) &&
                    !arraysAreEqual(f, h) &&
                    !arraysAreEqual(e, a))) {
                resultArray[yUp][x] = b;
            }
            if (arraysAreEqual(b, f) &&
                !arraysAreEqual(b, d) &&
                !arraysAreEqual(f, h)) {
                resultArray[yUp][xRight] = f;
            }
            if ((arraysAreEqual(h, d) &&
                !arraysAreEqual(h, f)) &&
                !arraysAreEqual(d, b) &&
                !arraysAreEqual(e, a) ||
                (arraysAreEqual(d, b) &&
                    !arraysAreEqual(d, h) &&
                    !arraysAreEqual(b, f) &&
                    !arraysAreEqual(e, g))) {
                resultArray[y][xLeft] = d;
            }
            resultArray[y][x] = e;
            if ((arraysAreEqual(b, f) &&
                !arraysAreEqual(b, d) &&
                !arraysAreEqual(f, h) &&
                !arraysAreEqual(e, _i)) ||
                (arraysAreEqual(f, h) &&
                    !arraysAreEqual(f, b) &&
                    !arraysAreEqual(h, d) &&
                    !arraysAreEqual(a, c))) {
                resultArray[y][xRight] = f;
            }
            if ((arraysAreEqual(h, d) &&
                !arraysAreEqual(h, f)) &&
                !arraysAreEqual(d, b)) {
                resultArray[yDown][xLeft] = d;
            }
            if ((arraysAreEqual(f, h) &&
                !arraysAreEqual(f, b) &&
                !arraysAreEqual(h, d) &&
                !arraysAreEqual(a, g)) ||
                (arraysAreEqual(h, d) &&
                    !arraysAreEqual(h, f)) &&
                !arraysAreEqual(d, b) &&
                !arraysAreEqual(e, _i)) {
                resultArray[yDown][x] = h;
            }
            if (arraysAreEqual(f, h) &&
                !arraysAreEqual(f, b) &&
                !arraysAreEqual(h, d)) {
                resultArray[yDown][xRight] = f;
            }
        }
    }

    return resultArray;
}