# crxReader Function

## Overview
The `crxReader` function is specifically crafted for reading and processing data from CellReporterXpress (CRX) experiment files. It allows users to access image data from specified wells and tiles or retrieve metadata about the experiments.

## Installation

Before using `crxReader`, ensure that MATLAB's Image Processing Toolbox and Database Toolbox are installed. Also, make sure that the CellReporterXpress SQLite database and its associated images database are located in the same directory as the `crxReader` function.

## Usage

```matlab
outdata = crxReader(crxExperimentFile, varargin)
```

### Parameters

#### Required Parameters
- `crxExperimentFile` - A string specifying the path to the CellReporterXpress experiment file.

#### Optional Parameters
Optional parameters follow the MATLAB name-value pair convention:

- `'channel'` - Channel number to read (default: `1`)
- `'well'` - Specific well to read (default: all wells)
- `'tile'` - Specific tile or `'all'` tiles from the well (default: all tiles)
- `'level'` - Pyramid level for image resolution (default: `0`, full resolution)
- `'timezone'` - Timezone for date and time display (default: `'Europe/Amsterdam'`)
- `'show'` - Set to `1` to display image (default: `0`, do not show)
- `'saveas'` - Path/File to save the image(s) (default: do not save)
- `'tiffcompression'` - TIFF image compression method (default: `'deflate'`)
- `'info'` - Preloaded experiment information (default: empty)
- `'verbose'` - Enable informational messages (default: `0`, silent mode)

### Output
- `outdata` - Image data as a matrix, or metadata as a structure.

## Examples

Here are some common usage examples:

```matlab
% Example 1: Retrieve experiment information.
info = crxReader('path/to/experiment.db');

% Example 2: Read full image data from a specific well.
imgData = crxReader('path/to/experiment.db', 'well', 'A01');

% Example 3: Read image data from a specific tile in a well.
imgData = crxReader('path/to/experiment.db', 'well', 'A01', 'tile', 5);

% Example 4: Read image data from all tiles in a well.
imgData = crxReader('path/to/experiment.db', 'well', 'A01', 'tile', 'all');

% Example 5: Read and save image data of a full well.
imgData = crxReader('path/to/experiment.db', 'well', 'A01', 'saveas', 'output.tif');

% Example 6: Read and save image data from all tiles in a well.
imgData = crxReader('path/to/experiment.db', 'well', 'A01', 'tile', 'all','saveas', 'output.tif');

% Example 7: Read, save, and display image data of a full well.
imgData = crxReader('path/to/experiment.db', 'well', 'A01', 'saveas', 'output.tif', 'show', 1);
```

## Notes

- This function is not suitable for time-series or Z-stack data.
- Data for the examples_ is available in the release file.

## Author

Ron Hoebe  
AmsterdamUMC  
Amsterdam, The Netherlands

## License

This project is licensed under the GNU General Public License v2 - see the LICENSE.md file for details.

[![View crxReader on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://nl.mathworks.com/matlabcentral/fileexchange/154556-crxreader)
