function eagle(inputArray) {
    var height = inputArray.length;
    var width = inputArray[0].length;

    var sizeFactor = 2;

    var resultArray = create2DArray(width * sizeFactor, height * sizeFactor, []);

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            var x = j * sizeFactor;
            var y = i * sizeFactor;

            var xRight = Math.min(x + 1, (width * sizeFactor) - 1);
            var yDown = Math.min(y + 1, (height * sizeFactor) - 1);

            var iUp = Math.max(i - 1, 0);
            var iDown = Math.min(i + 1, height - 1);
            var jRight = Math.min(j + 1, width - 1);
            var jLeft = Math.max(j - 1, 0);

            var upperLeft = inputArray[iUp][jLeft];
            var upperCenter = inputArray[iUp][j];
            var upperRight = inputArray[iUp][jRight];

            var middleLeft = inputArray[i][jLeft];
            var middleCenter = inputArray[i][j];
            var middleRight = inputArray[i][jRight];

            var downLeft = inputArray[iDown][jLeft];
            var downCenter = inputArray[iDown][j];
            var downRight = inputArray[iDown][jRight];

            resultArray[y][x] = arraysAreEqual(upperLeft, upperCenter, middleLeft) ? upperLeft : middleCenter;
            resultArray[y][xRight] = arraysAreEqual(upperCenter, upperRight, middleRight) ? upperRight : middleCenter;
            resultArray[yDown][x] = arraysAreEqual(middleLeft, downLeft, downCenter) ? downLeft : middleCenter;
            resultArray[yDown][xRight] = arraysAreEqual(downCenter, downRight, middleRight) ? downRight : middleCenter;
        }
    }

    return resultArray;
}