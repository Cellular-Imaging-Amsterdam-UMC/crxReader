function outdata=crxReader(crxExperimentFile, varargin)

% crxReader - A function to read and process data from CellReporterXpress experiment files.
%
% Usage:
%   outdata = crxReader(crxExperimentFile, varargin)
%
% Inputs:
%   crxExperimentFile - A string specifying the path to the CellReporterXpress experiment file.
%
% Optional Name-Value Pair Inputs:
%   'channel'        - (Numeric) Channel to be read. Default is 1.
%   'well'           - (String) Specific well to be read. Default is empty.
%   'tile'           - (Numeric/String) Specific tile from the well to be read. Default is empty.
%   'level'          - (Numeric) Pyramid level for image resolution. Default is 0 (full resolution).
%   'timezone'       - (String) Timezone for displaying date and time. Default is 'Europe/Amsterdam'.
%   'show'           - (Numeric) Set to 1 to display image using imshow. Default is 0 (do not show).
%   'saveas'         - (String) Path/File to save the image(s). Supports '.tif' and '.png'. Default is empty (do not save).
%   'tiffcompression'- (String) Compression method for TIFF images. Options are 'none', 'lzw', and 'deflate'. Default is 'deflate'.
%   'info'           - (Struct) Information from experiment file. (Speeds up repeated reading). Default is empty.
%   'verbose'        - (Numeric) Set to 1 to enable display of informational messages. Default is 0 (silent).
%
% Outputs:
%   outdata - The output image data, or a structure containing experiment information if no well and tile are specified.
%
% Description:
%   The function reads image data from a CellReporterXpress experiment file.
%   If a specific well and tile (or 'all') are provided, it returns the full image data for that tile or tiles.
%   If only a well is provided, it returns the full image or pyramid level data for that well.
%   If neither well nor tile is provided, it returns a structure containing information about the experiment.
%
%   The function also supports saving the image data to a file and displaying the image.
%   When saving channel, well, tile and pyramid level ar added to the filename.
%
% Examples:
%   1. Read information from experiment file:
%      info = crxReader('path/to/experiment.db');
%
%   2. Read full image data from a specific well:
%      imgData = crxReader('path/to/experiment.db', 'well', 'A01');
%
%   3. Read image data from a specific tile in a specific well:
%      imgData = crxReader('path/to/experiment.db', 'well', 'A01', 'tile', 5);
%
%   4. Read image data from all tiles in a specific well:
%      imgData = crxReader('path/to/experiment.db', 'well', 'A01', 'tile', 'all');
%
%   5. Read image data of full well and save to a file:
%      imgData = crxReader('path/to/experiment.db', 'well', 'A01', 'saveas', 'output.tif');
%
%   6. Read image data from all tiles in a specific well and save to files:
%      imgData = crxReader('path/to/experiment.db', 'well', 'A01', 'tile', 'all','saveas', 'output.tif');
%
%   7. Read image data of full well, save to a file, and display the image:
%      imgData = crxReader('path/to/experiment.db', 'well', 'A01', 'saveas', 'output.tif', 'show', 1);
%
% Notes:
%   - Image Processing Toolbox & Database Toolbox are needed
%   - Ensure that the CellReporterXpress SQLite database and the images database are in the same directory.
%   - This function only reads multi-well-plate data with one (and the same for all wells)
%     zone per well. Time-series and Z-stacks are not supported.
%   
% Author: Ron Hoebe
% Date: 2023-10-31
% Version: 1.0
% Copyright Ron Hoebe, AmsterdamUMC, Amsterdam, The Netherlands
% This program is free software; you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.

    p = inputParser;
    defaultVerbose=0;
    defaultTimeZone='Europe/Amsterdam';
    defaultChannel=1;
    defaultWell=[];
    defaultTile=[];
    defaultLevel=0;
    defaultShowImage=0;
    defaultSaveAsImage=[];
    defaultTiffCompression='deflate';
    defaultInfo=[];

    validStr = @(x) ischar(x);
    validStruct= @(x) isstruct (x);
    validNumeric = @(x) isnumeric(x) && isscalar(x) && x >= 0;

    addParameter(p, 'channel', defaultChannel, validNumeric);
    addParameter(p, 'well', defaultWell, validStr);
    addParameter(p, 'tile', defaultTile); % can be str or num
    addParameter(p, 'level', defaultLevel, validNumeric);
    addParameter(p, 'timezone', defaultTimeZone, validStr);
    addParameter(p, 'show', defaultShowImage, validNumeric);
    addParameter(p, 'saveas', defaultSaveAsImage, validStr);
    addParameter(p, 'tiffcompression', defaultTiffCompression, validStr);
    addParameter(p, 'info', defaultInfo, validStruct);
    addParameter(p, 'verbose', defaultVerbose, validNumeric);
    parse(p, varargin{:});

    crxTimeZone=p.Results.timezone;
    crxChannel=p.Results.channel;
    crxWell=p.Results.well;
    crxTile=p.Results.tile;
    crxLevel=p.Results.level;
    crxSaveAs=p.Results.saveas;
    crxShow=p.Results.show;
    crxTiffCompression=p.Results.tiffcompression;
    crxInfo=p.Results.info;
    verboseLevel = p.Results.verbose;

    isOK=false;
    if isfile(crxExperimentFile)
        if ~isstruct(crxInfo)
            crxInfo=struct;
            crxInfo.crxExperimentFile=crxExperimentFile;
            [filepath,~,~]=fileparts(crxExperimentFile);
            crxInfo.crxImagesFile=[filepath '\images-0.db'];
            doDisp('Reading Info from CellReporterxpress experiment.db file');
            try
                conn = sqlite(crxExperimentFile,'readonly');
                    rs=fetch(conn,'SELECT ExperimentBase.DateCreated, ExperimentBase.Creator, ExperimentBase.Name FROM ExperimentBase',0);
                    rse=fetch(conn,'SELECT AcquisitionExp.Name FROM AcquisitionExp',0);
                    dt=datetime(uint64(rs.DateCreated),'ConvertFrom','.net','TimeZone',crxTimeZone);
                    doDisp(['Name: ' char(rs.Name)]);
                    doDisp(['Creator: ' char(rs.Creator)]);
                    doDisp(['Protocol: ' char(rse.Name)])
                    doDisp(['Date: ' char(dt) ' (TimeZone: ' crxTimeZone ')']);
                    crxInfo.name=char(rs.Name);
                    crxInfo.creator=char(rs.Creator);
                    crxInfo.protocol=char(rse.Name);
                    crxInfo.dt=dt;
                    rs=fetch(conn,'SELECT Well.Name FROM Well',0);
                    crxInfo.MultiWellPlate=numel(rs.Name);
                    rs=fetch(conn,'SELECT Well.Name, Well.ZoneIndex FROM Well WHERE Well.HasImages = 1',0);
                    rsdI=fetch(conn,'SELECT AcquisitionExp.SensorSizeYPixels, AcquisitionExp.SensorSizeXPixels, AcquisitionExp.Objective, AcquisitionExp.PixelSizeUm, AcquisitionExp.SensorBitness, AutomaticZonesParametersExp.SitesX, AutomaticZonesParametersExp.SitesY FROM AcquisitionExp, AutomaticZonesParametersExp',0);
                    rsdC=fetch(conn,'SELECT ImageChannelExp.Emission, ImageChannelExp.Excitation, ImageChannelExp.Dye, ImageChannelExp.ChannelNumber, ImageChannelExp.ColorName FROM ImageChannelExp',0);
                    crxInfo.WellInfo=crxReadWellInfo(rsdI,rsdC);
                    elements=numel(rs.Name);
                    crxInfo.numwells=elements;
                    for k=1:elements
                        crxInfo.Wells{k}=char(rs.Name{k});
                        crxInfo.ZoneIndex(k)=rs.ZoneIndex(k);
                    end
                close(conn)
                isOK=true;
                doDisp('Ready Reading Info!');
            catch
                doDisp('Error Reading Info from file!');
                doDisp('Format of data in file is different then expected.');
            end
        else
            isOK=true;
            doDisp('Using given Info!');
        end
    else
        doDisp('Error File not Found!');
    end
    % Return info as struct if only read info
    if isempty(crxWell) && isempty(crxTile) && isOK
        outdata=crxInfo;
        return
    end

    % All Tiles or Single Tile from Well (only full resolution supported)
    if ~isempty(crxWell) && ~isempty(crxTile) && isOK    
        if sum(ismember(crxInfo.Wells,crxWell))
            if ischar(crxTile)
                if strcmpi(crxTile,'all')
                    % get well ZoneData
                    zi=crxInfo.ZoneIndex(strcmpi(crxInfo.Wells,crxWell));
                    conn = sqlite(crxInfo.crxExperimentFile,'readonly');
                        zd=fetch(conn,['SELECT SourceImageBase.CoordY, SourceImageBase.CoordX, SourceImageBase.SizeX, SourceImageBase.SizeY, SourceImageBase.BitsPerPixel, SourceImageBase.ImageIndex, SourceImageBase.ChannelId FROM SourceImageBase WHERE SourceImageBase.ZoneIndex = ' num2str(zi) ' AND SourceImageBase.Level = 0 ORDER BY SourceImageBase.CoordX ASC, SourceImageBase.CoordY ASC'],0);
                    close(conn)
                    if ~isempty(zd)
                        zd=zd(zd.ChannelId==(crxChannel-1),:);
                        [~,ix]=unique(zd.CoordX);
                        [~,iy]=unique(zd.CoordY);
                        xmax = sum(zd.SizeX(ix));
                        ymax = sum(zd.SizeY(iy));
                        imdata=zeros(xmax,ymax,'uint16');
                        fid=fopen(crxInfo.crxImagesFile,'r');
                            for i=1:numel(zd.CoordX)
                                fseek(fid,zd.ImageIndex(i),'bof');
                                imdata(1+zd.CoordX(i):zd.CoordX(i)+zd.SizeX(i),1+zd.CoordY(i):zd.CoordY(i)+zd.SizeY(i))=fread(fid, [zd.SizeX(i) zd.SizeY(i)], 'uint16');
                            end
                        fclose(fid);
                        outdata=cell(crxInfo.WellInfo.tiles,1);
                        tx=0;
                        ty=1;
                        for tile=1:crxInfo.WellInfo.tiles
                            tx=tx+1;
                            if tx>crxInfo.WellInfo.tilex
                                tx=1; ty=ty+1;
                            end
                            txs=(tx-1)*crxInfo.WellInfo.xs+1; tys=(ty-1)*crxInfo.WellInfo.ys+1; 
                            xs=txs+crxInfo.WellInfo.xs-1; ys=tys+crxInfo.WellInfo.ys-1;
                            outdata{tile}=transpose(imdata(txs:xs,tys:ys));
                        end
                        ShowSave(outdata, transpose(imdata));
                        doDisp(['Ready Reading all Tiles from Well: ''' crxWell ''''])
                    else
                        doDisp(['Error Reading all Tiles from Well: ''' crxWell ''''])
                        outdata=[];
                    end
                else
                    doDisp(['Error Reading all Tiles  from Well: ''' crxWell ''', Well is not valid'])
                    outdata=[];
                end
            else
                if crxTile>0 && crxTile<=crxInfo.WellInfo.tiles
                    % get well ZoneData
                    zi=crxInfo.ZoneIndex(strcmpi(crxInfo.Wells,crxWell));
                    conn = sqlite(crxInfo.crxExperimentFile,'readonly');
                        zd=fetch(conn,['SELECT SourceImageBase.CoordY, SourceImageBase.CoordX, SourceImageBase.SizeX, SourceImageBase.SizeY, SourceImageBase.BitsPerPixel, SourceImageBase.ImageIndex, SourceImageBase.ChannelId FROM SourceImageBase WHERE SourceImageBase.ZoneIndex = ' num2str(zi) ' AND SourceImageBase.Level = 0 ORDER BY SourceImageBase.CoordX ASC, SourceImageBase.CoordY ASC'],0);
                    close(conn)
                    zd=zd(zd.ChannelId==(crxChannel-1),:);
                    tx=0;
                    ty=1;                    
                    for tile=1:crxTile
                        tx=tx+1;
                        if tx>crxInfo.WellInfo.tilex; tx=1; ty=ty+1; end
                    end                    
                    tx=tx-1;ty=ty-1;
                    %ty=floor((crxTile-1)/crxInfo.WellInfo.tiley); 
                    %tx=crxTile-ty*crxInfo.WellInfo.tilex-1; 
                    xs=tx*crxInfo.WellInfo.xs; ys=ty*crxInfo.WellInfo.ys;  
                    xse=xs+crxInfo.WellInfo.xs-max(zd.SizeX)-1; yse=ys+crxInfo.WellInfo.ys-max(zd.SizeX)-1;
                    % crop data to that tile in zone
                    zdx=sort(zd.CoordX); zdy=sort(zd.CoordY);
                    xmin=zdx(find(zdx<=xs, 1, 'last')); xmax=zdx(find(zdx>=xse, 1, 'first'));
                    ymin=zdy(find(zdy<=ys, 1, 'last')); ymax=zdy(find(zdy>=yse, 1, 'first'));
                    zd=zd(zd.CoordX>=xmin & zd.CoordX<=xmax & zd.CoordY>=ymin & zd.CoordY<=ymax & zd.ChannelId==(crxChannel-1),:);
                    % read this cropped data 
                    xmin = min(zd.CoordX); xmax = max(zd.CoordX);
                    ymin = min(zd.CoordY); ymax = max(zd.CoordY);
                    imdata=zeros(xmax-xmin,ymax-ymin,'uint16');
                    fid=fopen(crxInfo.crxImagesFile,'r');
                        for i=1:numel(zd.CoordX)
                            fseek(fid,zd.ImageIndex(i),'bof');
                            imdata(1+zd.CoordX(i)-xmin:zd.CoordX(i)-xmin+zd.SizeX(i),1+zd.CoordY(i)-ymin:zd.CoordY(i)-ymin+zd.SizeY(i))=fread(fid, [zd.SizeX(i) zd.SizeY(i)], 'uint16');
                        end
                    fclose(fid);
                    % crop data to tile
                    outdata=transpose(imdata(1+xs-xmin:xs-xmin+crxInfo.WellInfo.xs,1+ys-ymin:ys-ymin+crxInfo.WellInfo.ys));
                    ShowSave(outdata);
                    doDisp(['Ready Reading Tile: ' num2str(crxTile) ' from Well: ''' crxWell ''''])
                else
                    doDisp(['Error Reading Tile: ' num2str(crxTile) ' from Well: ''' crxWell ''' does not exists'])
                    outdata=[];
                end
            end
        else
            doDisp(['Error Well: ''' crxWell ''' not Found!']);
            outdata=[];
        end
        return
    end

    % Full Well (pyramid levels supported)
    if ~isempty(crxWell) && isempty(crxTile) && isOK
        if sum(ismember(crxInfo.Wells,crxWell))
            % get well ZoneData
            zi=crxInfo.ZoneIndex(strcmpi(crxInfo.Wells,crxWell));
            conn = sqlite(crxInfo.crxExperimentFile,'readonly');
                zd=fetch(conn,['SELECT SourceImageBase.CoordY, SourceImageBase.CoordX, SourceImageBase.SizeX, SourceImageBase.SizeY, SourceImageBase.BitsPerPixel, SourceImageBase.ImageIndex, SourceImageBase.ChannelId FROM SourceImageBase WHERE SourceImageBase.ZoneIndex = ' num2str(zi) ' AND SourceImageBase.Level = ' num2str(crxLevel) ' ORDER BY SourceImageBase.CoordX ASC, SourceImageBase.CoordY ASC'],0);
            close(conn)
            if ~isempty(zd)
                zd=zd(zd.ChannelId==(crxChannel-1),:);
                [~,ix]=unique(zd.CoordX);
                [~,iy]=unique(zd.CoordY);
                xmax = sum(zd.SizeX(ix));
                ymax = sum(zd.SizeY(iy));
                imdata=zeros(xmax,ymax,'uint16');
                fid=fopen(crxInfo.crxImagesFile,'r');
                    for i=1:numel(zd.CoordX)
                        fseek(fid,zd.ImageIndex(i),'bof');
                        imdata(1+zd.CoordX(i):zd.CoordX(i)+zd.SizeX(i),1+zd.CoordY(i):zd.CoordY(i)+zd.SizeY(i))=fread(fid, [zd.SizeX(i) zd.SizeY(i)], 'uint16');
                    end
                fclose(fid);
                outdata=transpose(imdata);
                ShowSave(outdata);
                doDisp('Ready Reading Full Well')
            else
                doDisp(['Error Reading Full Well, pyramid level ' num2str(crxLevel) ' does not exists'])
                outdata=[];
            end
        else
            doDisp('Error Well not Found!');
            outdata=[];
        end
        return
    end
    
    function ShowSave(imdata, wellimdata)
        isc=iscell(imdata);
        if ~isempty(crxSaveAs)
            [spath,sname,ext]=fileparts(crxSaveAs);
            if ~isempty(crxTile)
                sname=[sname '_ch' num2str(crxChannel) '_' addLeadingZero(crxWell)];
            else
                if crxLevel>0
                    sname=[sname '_ch' num2str(crxChannel) '_level' num2str(crxLevel) '_' addLeadingZero(crxWell)];
                else
                    sname=[sname '_ch' num2str(crxChannel) '_' addLeadingZero(crxWell)];
                end
            end
            if strcmpi(ext,'.tif') || strcmpi(ext,'.png')
                if isfolder(spath) || isempty(spath)
                    if ~isempty(spath)
                        spath=[spath '\'];
                    else
                        spath='';
                    end
                    if strcmpi(ext,'.tif')
                        validCompressionTypes = {'none', 'lzw','deflate'};
                        if ismember(lower(crxTiffCompression), validCompressionTypes)
                            if ~isc
                                if ~isempty(crxTile)
                                    fname=([spath sname '_' addLeadingZero(crxTile) ext]);
                                else
                                    fname=([spath sname ext]);
                                end
                                imwrite(imdata, fname,'Compression',lower(crxTiffCompression))
                                doDisp('Image Saved!')
                            else
                                for im=1:numel(imdata)
                                    fname=([spath sname '_' addLeadingZero(num2str(im)) ext]);
                                    imwrite(imdata{im}, fname,'Compression',lower(crxTiffCompression));
                                end
                                doDisp('Images Saved!')
                            end
                        else
                            doDisp('Error, Only ''none'', ''lzw'' and ''deflate'' are supported .tif compression values!')
                        end
                    end
                    if strcmpi(ext,'.png')
                        if ~isc
                            if ~isempty(crxTile)
                                fname=([spath sname '_' addLeadingZero(crxTile) ext]);
                            else
                                fname=([spath sname ext]);
                            end
                            imwrite(imdata, fname)
                            doDisp('Image Saved!')
                        else
                            for im=1:numel(imdata)
                                fname=([spath sname '_' addLeadingZero(num2str(im)) ext]);
                                imwrite(imdata{im}, fname);
                            end
                            doDisp('Images Saved!')
                        end
                    end
                else
                    doDisp('Error, Path not found, image not saved!')
                end
            else
                doDisp('Error, Only .tif or .png are supported!')
            end
        end
        if crxShow>0
            doDisp('Showing Image');
            if ~isc
                imshow(imdata,[]);
            else
                imshow(wellimdata,[]);
            end
        end
    end

    function doDisp(stext)
        if verboseLevel>0
            disp(stext);
        end
    end 

end

function wellinfo = crxReadWellInfo(ImageData,ChannelData)
    wellinfo.channels=numel(ChannelData.ChannelNumber);
    wellinfo.lutname=cell(wellinfo.channels,1);
    wellinfo.dye=cell(wellinfo.channels,1);
    wellinfo.excitation=zeros(wellinfo.channels,1);
    wellinfo.emission=zeros(wellinfo.channels,1);
    %Tiles
    wellinfo.tilex=double(ImageData.SitesX);
    wellinfo.tiley=double(ImageData.SitesY);
    wellinfo.tiles=double(ImageData.SitesX*ImageData.SitesY);
    %Dimensions and size
    wellinfo.bits=ImageData.SensorBitness;
    wellinfo.resunit='µm';
    wellinfo.xs=ImageData.SensorSizeXPixels;
    wellinfo.ys=ImageData.SensorSizeYPixels;
    wellinfo.xres=ImageData.PixelSizeUm;
    wellinfo.yres=ImageData.PixelSizeUm;
    wellinfo.xres2=ImageData.PixelSizeUm;
    wellinfo.yres2=ImageData.PixelSizeUm;
    %Objective specs
    wellinfo.objective=ImageData.Objective;  
    %Channel Excitation and Emission
    for k = 1:wellinfo.channels
        wellinfo.emission(k)=ChannelData.Emission(k);
        wellinfo.excitation(k)=ChannelData.Excitation(k);
        if wellinfo.excitation(k)==0
            wellinfo.dye{k}='TL';
            wellinfo.lutname{k}='white';
        else
            wellinfo.dye{k}=lower(char(ChannelData.Dye{k}));
            chcolor=split(char(ChannelData.ColorName{k}),' ');
            wellinfo.lutname{k}=lower(char(chcolor{end}));
        end
    end
end

function result = addLeadingZero(inputString)
    [startIdx,endIdx] = regexp(inputString, '\d+');
    result = inputString;
    if ~isempty(startIdx)
        firstNumber=str2double(inputString(startIdx(1):endIdx(1)));
        if firstNumber<10; result=[inputString(1:startIdx(1)-1),'0',inputString(startIdx(1):end)]; end
    end
end
