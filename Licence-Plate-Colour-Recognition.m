%% ��ʼ��
clear;
close all;
matlabpool open;%��cpu���к���
corenum = 16;%�������������16���ĵ�
inputpath = 'C:\�������ݣ��ܣ�\��������2017.4.17\';%ͼƬ����·��
outputpath = 'C:\�������ݣ��ܣ�\yellow4\';%ͼƬ���·��
Files = dir(fullfile(inputpath,'*.jpg'));%����ÿ��ͼƬ·����Ϣ
LengthFiles = length(Files);%�����ļ����ڵ�ͼƬ����

%% ���м�������
for i = 1:corenum:LengthFiles;%16��ͼ��һ����ͬʱ����
    Scolor = Composite();%����Composite����
    for j = 1:corenum
        Scolor{j} = imread(strcat(inputpath,Files(i+j-1).name));%ΪComposite������г�ʼ����ֵ����Ϊÿ�����ķ���������ͼƬ
        fprintf('Processing:No.%d  %s\n',i+j-1,Files(i+j-1).name);%�����ǰ״̬��Ϣ
    end
    
    %% ÿ������ʹ�õ�ͼ������
    spmd
        %Step1 ͼ���ȡ���ɫ������ǿ
        Scolor = Scolor(300:end-300,300:end-300,:);%��ȡͼ����м䲿��
        Sgray=imsubtract(Scolor(:,:,1),Scolor(:,:,3));%ͼͨ�����
        %����ɫͼ��ת��Ϊ�ڰײ���ʾ
        Sgray_gray = rgb2gray(Scolor);%rgb2grayת���ɻҶ�ͼ
%         figure,imshow(Sgray),title('ԭʼ�ڰ�ͼ��');
        %Step2 ͼ��Ԥ����   ��Sgray ԭʼ�ڰ�ͼ����п������õ�ͼ�񱳾�
        s=strel('disk',17);%strei����
        Bgray=imopen(Sgray,s);%��sgray sͼ��
%         figure,imshow(Bgray);title('����ͼ��');%�������ͼ��
        Egray=imsubtract(Sgray,Bgray);%����ͼ�������ԭʼͼ���뱳��ͼ������������ǿͼ��
%         figure,imshow(Egray);title('��ǿ�ڰ�ͼ��');%����ڰ�ͼ��
        
        %Step3 ȡ�������ֵ����ͼ���ֵ��
        fmax1=double(max(max(Egray)));%egray�����ֵ�����˫������
        fmin1=double(min(min(Egray)));%egray����Сֵ�����˫������
        level=(fmax1-(fmax1-fmin1)/3)/255;%��������ֵ
        bw22=im2bw(Egray,level);%ת��ͼ��Ϊ������ͼ��
        bw2=double(bw22);
        
        %Step4 �Եõ���ֵͼ�������ղ��������˲�
%         figure,imshow(bw2);title('ͼ���ֵ��');%�õ���ֵͼ��
        grd = edge(bw2,'canny');%��canny����ʶ��ǿ��ͼ���еı߽�
%         figure,imshow(grd);title('ͼ���Ե��ȡ');%���ͼ���Ե
        bg1=imclose(grd,strel('rectangle',[5,19]));%ȡ���ο�ı�����
%         figure,imshow(bg1);title('ͼ�������[5,19]');%����������ͼ��
        se = strel('disk',3);
        grd = imdilate(bg1,se);
        bg1=imclose(grd,strel('rectangle',[5,19]));%ȡ���ο�ı�����
%         figure,imshow(bg1);title('ͼ�������[5,19]');%����������ͼ��
        bg3=imopen(bg1,strel('rectangle',[5,19]));%ȡ���ο�Ŀ�����
%         figure,imshow(bg3);title('ͼ������[5,19]');%����������ͼ��
        bg2=imopen(bg3,strel('rectangle',[19,1]));%ȡ���ο�Ŀ�����
%         figure,imshow(bg2);title('ͼ������[19,1]');%����������ͼ��
        
        %Step5 �Զ�ֵͼ�����������ȡ���������������������������������������Ƚϣ���ȡ��������
        [L,num] = bwlabel(bg2,8);%��ע������ͼ���������ӵĲ���
        Feastats = regionprops(L,'basic');%����ͼ������������ߴ�
        Area=[Feastats.Area];%�������
        if ~isempty(Area)%�����Ƿ�Ϊ�գ���û�л�ɫ����
            BoundingBox=[Feastats.BoundingBox];%[x y width height]���ƵĿ�ܴ�С
            x = floor(BoundingBox(1));%����ȡ������������ʱ������㲻������С��
            y = floor(BoundingBox(2));
            width = BoundingBox(3);
            height = BoundingBox(4);
            if x>0 && x < 1800 && y > 0 && y < 1100
                imgcut= Scolor(y:(y+height),x:(x+width),:);%���г���ɫ��������
                % imshow(imgcut);
                imgfinal = imresize(imgcut,[1,1]);%������ɫ��ֵ
                signa = imgfinal(:,:,1);%ͨ����
                signb = imgfinal(:,:,2);%ͨ����
                signc = imgfinal(:,:,3);%ͨ����
                if signa - signc > 80 && signb -signc > 70 && signc < 70 %���·��ϻ�ɫ
                    copyfile(strcat(inputpath,Files(i+labindex-1).name), strcat(outputpath,Files(i+labindex-1).name));%������Ҫ���ͼƬ���Ƶ���һ���ļ�����
                    fprintf('OK:No.%d %s\n\n',i+labindex-1,Files(i+labindex-1).name);%����Ҫ���ͼƬ��Ϣ
                end
            end
        end
    end
end
%% ����
clear ;
close all;
matlabpool close;%�رռ������