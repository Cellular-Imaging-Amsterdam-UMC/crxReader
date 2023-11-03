well=1;
dbfile='TestData2\experiment.db';
info=crxReader(dbfile, 'verbose',1);
im=zeros(info.WellInfo.ys*info.WellInfo.tiley,info.WellInfo.xs*info.WellInfo.tilex,3,'uint16');
for c=1:info.WellInfo.channels
    imch=crxReader(dbfile,'well',info.Wells{well},'channel',c,'info',info,'verbose',1);
    switch char(info.WellInfo.lutname{c})
        case 'red'
            disp('Adding Red Channel')
            im(:,:,1)=im(:,:,1)+imch;
        case 'green'
            disp('Adding Green Channel')
            im(:,:,2)=im(:,:,2)+imch;
        case 'blue'
            disp('Adding Blue Channel')
            im(:,:,3)=im(:,:,3)+imch;
        case 'cyan'
            disp('Adding Cyan Channel')
            im(:,:,2)=im(:,:,2)+imch;
            im(:,:,3)=im(:,:,3)+imch;
        case 'yellow'
            disp('Adding Yellow Channel')
            im(:,:,1)=im(:,:,1)+imch;
            im(:,:,2)=im(:,:,2)+imch;
        case 'magenta'
            disp('Adding Magenta Channel')
            im(:,:,1)=im(:,:,1)+imch;
            im(:,:,3)=im(:,:,3)+imch;
        case {'white'}
            disp('Adding TL Channel')
            im(:,:,1)=im(:,:,1)+imch;
            im(:,:,2)=im(:,:,2)+imch;
            im(:,:,3)=im(:,:,3)+imch;
    end
end
imtool(imadjust(im,stretchlim(im)));
