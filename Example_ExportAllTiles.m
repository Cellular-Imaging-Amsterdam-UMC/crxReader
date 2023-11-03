dbfile='TestData\experiment.db';
exportfolder='TestData\export';
if ~isfolder(exportfolder); mkdir(exportfolder);end
info=crxReader(dbfile);

numwells=numel(info.Wells);
for w=1:numwells
    for c=1:info.WellInfo.channels
        crxReader(dbfile,'well',info.Wells{w},'channel',c,'tile','all','saveas',[exportfolder '\' info.name '.tif'],'info',info,'verbose',1);
    end
end
disp('ready')
