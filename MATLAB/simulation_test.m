clc
clear 
close all

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[LogFileName, LogFilePath]=uigetfile('*.*','Select the results log file');
Kernel=-1*[1 1 1; 1 1 1; 1 1 1]; %change this with the kernel used in the IPCore Simulation
offset=0;
SIMD=0; % 0=16bit, 1=8bit

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if SIMD==0
    for ii=1:64
        for jj=1:64
                InputIMG(ii,jj)=jj-1+(ii-1)*64+offset;
        end
    end
    imgSize=size(InputIMG);
    ncol=imgSize(2);
    data = strsplit(fileread([LogFilePath LogFileName]), {'\r', '\n'});
    data=char(data);

    q=quantizer([32,0]);
    ResIMG=bin2num(q,data);
    ResIMG=vec2mat(int32(ResIMG),ncol);
    imshowpair(int32(InputIMG),ResIMG,'montage')
    title('Input Image and IP core produced image');


    InputIMG_filt=imfilter(int32(InputIMG),Kernel,'conv');
    figure
    imshowpair(InputIMG_filt,ResIMG,'montage')
    title('Matlab Filtered Input Image and IP core produced image');
    isequal(InputIMG_filt,ResIMG)

    errMat=InputIMG_filt-ResIMG;
    [errRow,errCol]=find(errMat ~= 0);
else
    for ii=0:7
        for jj=0:2:63
                InputIMG(ii+1,jj+1)=jj/2+(ii)*32+ offset;
                InputIMG(ii+1,jj+2)=jj/2+(ii)*32+ offset;
        end
    end
    InputIMG=repmat(InputIMG,8,1);
    
    imgSize=size(InputIMG);
    ncol=imgSize(2);
    data = strsplit(fileread([LogFilePath LogFileName]), {'\r', '\n'});
    data=char(data);
    data=vec2mat(data,16);

    q=quantizer([16,0]);
    ResIMG=bin2num(q,data);
    ResIMG=vec2mat(int16(ResIMG),ncol);
    imshowpair(int16(InputIMG),ResIMG,'montage')
    title('Input Image and IP core produced image');


    InputIMG_filt=imfilter(int16(InputIMG),Kernel,'conv');
    figure
    imshowpair(InputIMG_filt,ResIMG,'montage')
    title('Matlab Filtered Input Image and IP core produced image');
    isequal(InputIMG_filt,ResIMG)

    errMat=InputIMG_filt-ResIMG;
    [errRow,errCol]=find(errMat ~= 0);
end 
% 
% temp=zeros(64,1);   
% 
%         for jj=1:2:64
%                 temp=a(:,jj+1);
%                 a(:,jj+1)=a(:,jj);
%                 a(:,jj)=temp;
%         end

