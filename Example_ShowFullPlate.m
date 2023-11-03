dbfile='TestData\experiment.db';
channel=2;
level=5;

info=crxReader(dbfile);
if info.MultiWellPlate==6
    wellcols={'1','2','3'};
    wellrows={'A','B'};
    rs=2; cs=3;
elseif info.MultiWellPlate==12
    wellcols={'1','2','3','4'};
    wellrows={'A','B','C'};
    rs=3; cs=4;
elseif info.MultiWellPlate==24
    wellcols={'1','2','3','4','5','6'};
    wellrows={'A','B','C','D'};
    rs=4; cs=6;
elseif info.MultiWellPlate==48
    wellcols={'1','2','3','4','5','6','7','8'};
    wellrows={'A','B','C','D','E','F'};
    rs=6; cs=8;
elseif info.MultiWellPlate==96
    wellcols={'1','2','3','4','5','6','7','8','9','10','11','12'};
    wellrows={'A','B','C','D','E','F','G','H'};
    rs=8; cs=12;
elseif info.MultiWellPlate==384
    wellcols={'1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21','22','23','24'};
    wellrows={'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P'};
    rs=16; cs=24;
end

numwells=numel(info.Wells);
[ys, xs]=size(crxReader(dbfile,'well',info.Wells{1},'channel',1,'level',level,'info',info));
plate=zeros(rs*ys,rs*xs,'uint16');
for r=1:rs
    for c=1:cs
        w=[wellrows{r} wellcols{c}];
        if ismember(w,info.Wells)
            plate((r-1)*ys+1:(r-1)*ys+ys,(c-1)*xs+1:(c-1)*xs+xs)=crxReader(dbfile,'well',w,'channel',channel,'level',level,'info',info);
        end
    end
end
imtool(plate,stretchlim(plate(plate>0))*(2^16-1));


