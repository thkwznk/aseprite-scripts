function NearestNeighbour(inputArray) {
    var height = inputArray.length;
    var width = inputArray[0].length;

    var resultArray = create2DArray(width * 2, height * 2, []);

    for (var i = 0; i < height; i++) {
        for (var j = 0; j < width; j++) {
            var x = j * 2;
            var y = i * 2;

            resultArray[y][x] = inputArray[i][j];
            resultArray[y + 1][x] = inputArray[i][j];
            resultArray[y][x + 1] = inputArray[i][j];
            resultArray[y + 1][x + 1] = inputArray[i][j];
        }
    }

    return resultArray;
}