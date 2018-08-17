function scale2x(inputArray) {
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

            if (arraysAreEqual(left, up) &&
                !arraysAreEqual(left, down) &&
                !arraysAreEqual(up, right)) {
                resultArray[y][x] = up;
            }
            if (arraysAreEqual(up, right) &&
                !arraysAreEqual(up, left) &&
                !arraysAreEqual(right, down)) {
                resultArray[y][x + 1] = right;
            }
            if (arraysAreEqual(down, left) &&
                !arraysAreEqual(down, right) &&
                !arraysAreEqual(left, up)) {
                resultArray[y + 1][x] = left;
            }
            if (arraysAreEqual(right, down) &&
                !arraysAreEqual(right, up) &&
                !arraysAreEqual(down, left)) {
                resultArray[y + 1][x + 1] = down;
            }
        }
    }

    return resultArray;
}